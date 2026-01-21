extends Node
class_name BattleManager
## 战斗管理器 - 八方旅人式回合制战斗
## 控制整个战斗流程：回合制、BP系统、破盾系统

enum BattleState {
	INIT,
	START,
	PLAYER_TURN,
	ENEMY_TURN,
	EXECUTING,
	VICTORY,
	DEFEAT
}

var current_state: BattleState = BattleState.INIT
var party: Array = []  # 我方队伍
var enemies: Array = []  # 敌方队伍
var turn_order: Array = []  # 行动顺序
var current_actor_index: int = 0

var turn_system: TurnSystem
var bp_system: BPSystem
var shield_system: ShieldSystem
var damage_calculator: DamageCalculator

signal battle_started()
signal battle_ended(is_victory: bool)
signal turn_started(actor: Dictionary)
signal turn_ended(actor: Dictionary)
signal action_executed(actor: Dictionary, action: Dictionary, targets: Array, results: Array)
signal shield_broken(enemy: Dictionary)
signal enemy_defeated(enemy: Dictionary)
signal player_defeated(player: Dictionary)

func _ready() -> void:
	turn_system = TurnSystem.new()
	bp_system = BPSystem.new()
	shield_system = ShieldSystem.new()
	damage_calculator = DamageCalculator.new()
	print("[BattleManager] 初始化完成")

func start_battle(party_data: Array, enemy_data: Array) -> void:
	"""开始战斗"""
	current_state = BattleState.INIT
	
	# 深拷贝数据避免修改原始数据
	party = []
	for p in party_data:
		party.append(p.duplicate(true))
	
	enemies = []
	for e in enemy_data:
		var enemy = e.duplicate(true)
		enemies.append(enemy)
	
	# 初始化BP
	for member in party:
		bp_system.init_bp(member)
	
	# 初始化敌人护盾
	for enemy in enemies:
		shield_system.init_shield(enemy)
	
	# 计算先攻顺序
	turn_order = turn_system.calculate_turn_order(party, enemies)
	current_actor_index = 0
	
	current_state = BattleState.START
	battle_started.emit()
	print("[BattleManager] 战斗开始! 我方: %d 人, 敌方: %d 人" % [party.size(), enemies.size()])
	
	# 开始第一个回合
	await get_tree().create_timer(0.5).timeout
	start_next_turn()

func start_next_turn() -> void:
	"""开始下一个回合"""
	# 检查战斗结束
	if check_battle_end():
		return
	
	# 清理已死亡的单位
	clean_dead_units()
	
	# 重新计算顺序（如果需要）
	if turn_order.is_empty():
		turn_order = turn_system.calculate_turn_order(party, enemies)
		current_actor_index = 0
	
	if current_actor_index >= turn_order.size():
		current_actor_index = 0
		turn_order = turn_system.calculate_turn_order(party, enemies)
	
	# 获取当前行动者
	var actor = turn_order[current_actor_index]
	
	# 检查是否被BREAK
	if actor.get("is_broken", false):
		print("[BattleManager] %s 处于BREAK状态，跳过回合" % actor.get("name", "未知"))
		actor["is_broken"] = false
		shield_system.restore_shield(actor)
		end_turn()
		return
	
	# 回合开始时BP+1（仅玩家）
	if actor in party:
		bp_system.add_bp(actor, 1)
	
	turn_started.emit(actor)
	print("[BattleManager] %s 的回合 (BP: %d)" % [actor.get("name", "未知"), actor.get("bp", 0)])
	
	# 判断是玩家还是敌人回合
	if actor in party:
		current_state = BattleState.PLAYER_TURN
		# 等待玩家输入（UI会调用 execute_action）
	else:
		current_state = BattleState.ENEMY_TURN
		# AI决策
		await get_tree().create_timer(0.8).timeout
		execute_enemy_ai(actor)

func execute_action(actor: Dictionary, action: Dictionary, targets: Array, bp_cost: int = 0) -> void:
	"""执行行动"""
	current_state = BattleState.EXECUTING
	
	# 消耗BP
	if bp_cost > 0 and actor in party:
		bp_system.consume_bp(actor, bp_cost)
	
	# 消耗MP
	var mp_cost = action.get("mp_cost", 0)
	if mp_cost > 0:
		actor["mp"] = max(actor.get("mp", 0) - mp_cost, 0)
	
	var results = []
	var hit_count = bp_system.get_hit_count(bp_cost) if action.get("type", "") in ["physical", "magical"] else 1
	
	# 计算伤害/效果
	for target in targets:
		for i in hit_count:
			var result = calculate_action_result(actor, action, target, bp_cost)
			results.append(result)
			
			# 应用结果
			apply_action_result(target, result)
			
			# 检查破盾
			if result.get("shield_break", false):
				shield_broken.emit(target)
				print("[BattleManager] BREAK! %s 的护盾被击破!" % target.get("name", "未知"))
	
	action_executed.emit(actor, action, targets, results)
	
	# 检查目标是否死亡
	for target in targets:
		if target.get("hp", 0) <= 0:
			if target in enemies:
				enemy_defeated.emit(target)
				print("[BattleManager] %s 被击败!" % target.get("name", "未知"))
			else:
				player_defeated.emit(target)
	
	# 等待动画
	await get_tree().create_timer(0.8).timeout
	
	end_turn()

func calculate_action_result(actor: Dictionary, action: Dictionary, target: Dictionary, bp_cost: int) -> Dictionary:
	"""计算行动结果"""
	var result = {
		"damage": 0,
		"heal": 0,
		"is_critical": false,
		"hit_weakness": false,
		"shield_damage": 0,
		"shield_break": false
	}
	
	var action_type = action.get("type", "physical")
	
	match action_type:
		"physical":
			result = damage_calculator.calculate_physical_damage(actor, target, action, bp_cost)
		"magical":
			result = damage_calculator.calculate_magical_damage(actor, target, action, bp_cost)
		"healing":
			result["heal"] = damage_calculator.calculate_heal(actor, action, bp_cost)
		"support":
			# 防御等辅助技能
			if action.get("effect", "") == "defend":
				actor["is_defending"] = true
				bp_system.add_bp(actor, 1)
	
	# 检查弱点命中和破盾
	if result.get("hit_weakness", false) and target in enemies:
		var shield_result = shield_system.hit_shield(target)
		result["shield_damage"] = 1
		result["shield_break"] = shield_result.get("is_broken", false)
	
	return result

func apply_action_result(target: Dictionary, result: Dictionary) -> void:
	"""应用行动结果"""
	# 扣血
	var damage = result.get("damage", 0)
	if damage > 0:
		var current_hp = target.get("hp", 0)
		target["hp"] = max(current_hp - damage, 0)
	
	# 治疗
	var heal = result.get("heal", 0)
	if heal > 0:
		var current_hp = target.get("hp", 0)
		var max_hp = target.get("hp_max", current_hp)
		target["hp"] = min(current_hp + heal, max_hp)

func execute_enemy_ai(enemy: Dictionary) -> void:
	"""敌人AI决策"""
	if party.is_empty():
		return
	
	# 简单AI：随机选择目标和技能
	var alive_party = party.filter(func(p): return p.get("hp", 0) > 0)
	if alive_party.is_empty():
		return
	
	var target = alive_party[randi() % alive_party.size()]
	
	# 获取敌人技能
	var enemy_skills = enemy.get("skills", ["tackle"])
	var skill_id = enemy_skills[randi() % enemy_skills.size()]
	var skill = DataManager.get_skill(skill_id)
	
	if skill.is_empty():
		skill = {"id": "attack", "name": "攻击", "power": 100, "type": "physical", "element": "physical"}
	
	execute_action(enemy, skill, [target], 0)

func end_turn() -> void:
	"""结束当前回合"""
	var actor = turn_order[current_actor_index]
	
	# 清除防御状态
	actor["is_defending"] = false
	
	turn_ended.emit(actor)
	
	# 移动到下一个行动者
	current_actor_index += 1
	
	start_next_turn()

func clean_dead_units() -> void:
	"""清理已死亡的单位"""
	turn_order = turn_order.filter(func(u): return u.get("hp", 0) > 0)

func check_battle_end() -> bool:
	"""检查战斗是否结束"""
	# 检查敌人全灭
	var enemies_alive = enemies.filter(func(e): return e.get("hp", 0) > 0)
	if enemies_alive.is_empty():
		current_state = BattleState.VICTORY
		print("[BattleManager] 战斗胜利!")
		battle_ended.emit(true)
		return true
	
	# 检查队伍全灭
	var party_alive = party.filter(func(p): return p.get("hp", 0) > 0)
	if party_alive.is_empty():
		current_state = BattleState.DEFEAT
		print("[BattleManager] 战斗失败...")
		battle_ended.emit(false)
		return true
	
	return false

func get_battle_rewards() -> Dictionary:
	"""获取战斗奖励"""
	var total_exp = 0
	var total_gold = 0
	var drops = []
	
	for enemy in enemies:
		total_exp += enemy.get("exp", 0)
		total_gold += enemy.get("gold", 0)
		
		for drop in enemy.get("drops", []):
			if randf() < drop.get("rate", 0):
				drops.append(drop.get("item", ""))
	
	return {
		"exp": total_exp,
		"gold": total_gold,
		"drops": drops
	}
