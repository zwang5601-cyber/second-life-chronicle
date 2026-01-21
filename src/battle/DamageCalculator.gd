extends RefCounted
class_name DamageCalculator
## 伤害计算器
## 处理所有战斗中的伤害计算

const CRITICAL_MULTIPLIER = 1.5    # 暴击倍率
const WEAKNESS_MULTIPLIER = 1.5   # 弱点倍率
const BREAK_MULTIPLIER = 1.5      # BREAK状态倍率
const MIN_DAMAGE = 1              # 最低伤害
const VARIANCE = 0.1              # ±10% 伤害浮动

var bp_system: BPSystem

func _init():
	bp_system = BPSystem.new()

func calculate_physical_damage(attacker: Dictionary, defender: Dictionary, skill: Dictionary, bp_cost: int = 0) -> Dictionary:
	"""计算物理伤害"""
	var result = {
		"damage": 0,
		"is_critical": false,
		"hit_weakness": false,
		"is_break_bonus": false
	}
	
	# 基础属性
	var attack = attacker.get("attack", 10)
	var defense = defender.get("defense", 5)
	var skill_power = skill.get("power", 100)
	
	# BP加成
	var bp_multiplier = bp_system.get_multiplier(bp_cost)
	
	# 基础伤害公式
	var base_damage = (attack * skill_power / 100.0 * bp_multiplier) - (defense * 0.5)
	
	# 暴击判定
	var crit_rate = attacker.get("luck", 5) / 100.0
	if randf() < crit_rate:
		base_damage *= CRITICAL_MULTIPLIER
		result["is_critical"] = true
	
	# 弱点加成
	var element = skill.get("element", "")
	var weaknesses = defender.get("weaknesses", [])
	if element in weaknesses:
		base_damage *= WEAKNESS_MULTIPLIER
		result["hit_weakness"] = true
		# 发现弱点
		var revealed = defender.get("revealed_weaknesses", [])
		if element not in revealed:
			revealed.append(element)
			defender["revealed_weaknesses"] = revealed
	
	# BREAK状态加成
	if defender.get("is_broken", false):
		base_damage *= BREAK_MULTIPLIER
		result["is_break_bonus"] = true
	
	# 防御状态减伤
	if defender.get("is_defending", false):
		base_damage *= 0.5
	
	# 伤害浮动
	var variance = randf_range(1.0 - VARIANCE, 1.0 + VARIANCE)
	base_damage *= variance
	
	# 最终伤害
	result["damage"] = int(maxf(base_damage, MIN_DAMAGE))
	
	return result

func calculate_magical_damage(attacker: Dictionary, defender: Dictionary, skill: Dictionary, bp_cost: int = 0) -> Dictionary:
	"""计算魔法伤害"""
	var result = {
		"damage": 0,
		"is_critical": false,
		"hit_weakness": false,
		"is_break_bonus": false
	}
	
	# 基础属性
	var magic = attacker.get("magic", 10)
	var magic_defense = defender.get("magic_defense", 5)
	var skill_power = skill.get("power", 100)
	
	# BP加成
	var bp_multiplier = bp_system.get_multiplier(bp_cost)
	
	# 基础伤害公式（魔防影响较小）
	var base_damage = (magic * skill_power / 100.0 * bp_multiplier) - (magic_defense * 0.3)
	
	# 弱点加成
	var element = skill.get("element", "")
	var weaknesses = defender.get("weaknesses", [])
	if element in weaknesses:
		base_damage *= WEAKNESS_MULTIPLIER
		result["hit_weakness"] = true
		# 发现弱点
		var revealed = defender.get("revealed_weaknesses", [])
		if element not in revealed:
			revealed.append(element)
			defender["revealed_weaknesses"] = revealed
	
	# BREAK状态加成
	if defender.get("is_broken", false):
		base_damage *= BREAK_MULTIPLIER
		result["is_break_bonus"] = true
	
	# 防御状态减伤
	if defender.get("is_defending", false):
		base_damage *= 0.5
	
	# 伤害浮动
	var variance = randf_range(1.0 - VARIANCE, 1.0 + VARIANCE)
	base_damage *= variance
	
	# 最终伤害
	result["damage"] = int(maxf(base_damage, MIN_DAMAGE))
	
	return result

func calculate_heal(healer: Dictionary, skill: Dictionary, bp_cost: int = 0) -> int:
	"""计算治疗量"""
	var magic = healer.get("magic", 10)
	var skill_power = skill.get("power", 100)
	var bp_multiplier = bp_system.get_multiplier(bp_cost)
	
	var heal_amount = magic * skill_power / 100.0 * bp_multiplier
	heal_amount *= randf_range(0.95, 1.05)  # 小浮动
	
	return int(heal_amount)
