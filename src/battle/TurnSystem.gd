extends RefCounted
class_name TurnSystem
## 回合/先攻系统
## 计算和管理行动顺序

func calculate_turn_order(party: Array, enemies: Array) -> Array:
	"""计算行动顺序，基于速度属性"""
	var all_actors = []
	
	# 合并所有存活的角色
	for member in party:
		if member.get("hp", 0) > 0:
			all_actors.append(member)
	
	for enemy in enemies:
		if enemy.get("hp", 0) > 0:
			all_actors.append(enemy)
	
	# 按速度排序（加入随机因子避免固定顺序）
	all_actors.sort_custom(func(a, b):
		var speed_a = a.get("speed", 10) + randf_range(-2, 2)
		var speed_b = b.get("speed", 10) + randf_range(-2, 2)
		return speed_a > speed_b
	)
	
	return all_actors

func insert_break_delay(turn_order: Array, broken_actor: Dictionary) -> Array:
	"""当敌人被BREAK时，将其行动顺序推后"""
	var index = turn_order.find(broken_actor)
	if index >= 0:
		turn_order.remove_at(index)
		turn_order.append(broken_actor)  # 移到最后
	return turn_order

func get_preview(party: Array, enemies: Array, preview_count: int = 10) -> Array:
	"""获取未来几回合的行动预览（用于UI显示）"""
	var preview = []
	var simulated_order = calculate_turn_order(party, enemies)
	
	if simulated_order.is_empty():
		return preview
	
	for i in preview_count:
		preview.append(simulated_order[i % simulated_order.size()])
	
	return preview
