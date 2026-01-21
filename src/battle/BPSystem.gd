extends RefCounted
class_name BPSystem
## BP (Boost Point) 系统
## 管理战斗中的BP积累和消耗 - 八方旅人核心机制

const BP_MAX = 5
const BP_START = 0
const BP_PER_TURN = 1

## BP消耗对应的效果倍率
const BP_MULTIPLIERS = {
	0: 1.0,   # 基础效果
	1: 1.5,   # 1BP: 1.5倍
	2: 2.0,   # 2BP: 2倍
	3: 2.5    # 3BP: 2.5倍（最大）
}

## BP消耗对应的攻击次数
const BP_HIT_COUNT = {
	0: 1,     # 基础1次
	1: 2,     # 1BP: 2次
	2: 3,     # 2BP: 3次
	3: 4      # 3BP: 4次
}

func init_bp(actor: Dictionary) -> void:
	"""初始化角色BP"""
	actor["bp"] = BP_START
	actor["bp_max"] = BP_MAX

func add_bp(actor: Dictionary, amount: int = BP_PER_TURN) -> int:
	"""增加BP，返回实际增加量"""
	var current = actor.get("bp", 0)
	var new_bp = mini(current + amount, BP_MAX)
	var actual_gain = new_bp - current
	actor["bp"] = new_bp
	return actual_gain

func consume_bp(actor: Dictionary, amount: int) -> bool:
	"""消耗BP，返回是否成功"""
	var current = actor.get("bp", 0)
	if current >= amount:
		actor["bp"] = current - amount
		return true
	return false

func get_bp(actor: Dictionary) -> int:
	"""获取当前BP"""
	return actor.get("bp", 0)

func can_boost(actor: Dictionary, amount: int) -> bool:
	"""检查是否可以消耗指定数量的BP"""
	return actor.get("bp", 0) >= amount

func get_multiplier(bp_cost: int) -> float:
	"""获取BP消耗对应的倍率"""
	return BP_MULTIPLIERS.get(mini(bp_cost, 3), 1.0)

func get_hit_count(bp_cost: int) -> int:
	"""获取BP消耗对应的攻击次数"""
	return BP_HIT_COUNT.get(mini(bp_cost, 3), 1)

func get_max_boost() -> int:
	"""获取最大可消耗BP数"""
	return 3
