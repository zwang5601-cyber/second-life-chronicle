extends RefCounted
class_name ShieldSystem
## 破盾系统
## 管理敌人的护盾值和弱点 - 八方旅人核心机制

## 弱点类型枚举
enum WeaknessType {
	SWORD,    # 剑
	SPEAR,    # 枪
	AXE,      # 斧
	BOW,      # 弓
	STAFF,    # 杖
	FIRE,     # 火
	ICE,      # 冰
	THUNDER,  # 雷
	WIND,     # 风
	LIGHT,    # 光
	DARK      # 暗
}

const WEAKNESS_NAMES = {
	"sword": "剑",
	"spear": "枪",
	"axe": "斧",
	"bow": "弓",
	"staff": "杖",
	"fire": "火",
	"ice": "冰",
	"thunder": "雷",
	"wind": "风",
	"light": "光",
	"dark": "暗",
	"physical": "物理"
}

const BREAK_DAMAGE_MULTIPLIER = 1.5  # BREAK状态下伤害加成

func init_shield(enemy: Dictionary) -> void:
	"""初始化敌人护盾"""
	var shield_max = enemy.get("shield", 4)
	enemy["shield_current"] = shield_max
	enemy["shield_max"] = shield_max
	enemy["is_broken"] = false
	enemy["revealed_weaknesses"] = []  # 已发现的弱点

func hit_shield(enemy: Dictionary, hits: int = 1) -> Dictionary:
	"""命中弱点时扣除护盾"""
	var result = {
		"shield_before": enemy.get("shield_current", 0),
		"shield_after": 0,
		"is_broken": false
	}
	
	if enemy.get("is_broken", false):
		# 已经破盾，不再扣除
		result["shield_after"] = 0
		return result
	
	var current_shield = enemy.get("shield_current", 0)
	var new_shield = maxi(current_shield - hits, 0)
	enemy["shield_current"] = new_shield
	result["shield_after"] = new_shield
	
	# 检查是否破盾
	if new_shield == 0 and current_shield > 0:
		enemy["is_broken"] = true
		result["is_broken"] = true
	
	return result

func restore_shield(enemy: Dictionary) -> void:
	"""恢复护盾（BREAK结束后）"""
	enemy["shield_current"] = enemy.get("shield_max", 4)
	enemy["is_broken"] = false

func reveal_weakness(enemy: Dictionary, weakness: String) -> void:
	"""发现弱点"""
	var revealed = enemy.get("revealed_weaknesses", [])
	if weakness not in revealed:
		revealed.append(weakness)
		enemy["revealed_weaknesses"] = revealed

func is_weakness(enemy: Dictionary, element: String) -> bool:
	"""检查是否是弱点"""
	var weaknesses = enemy.get("weaknesses", [])
	return element in weaknesses

func get_weakness_display(enemy: Dictionary) -> Array:
	"""获取弱点显示（用于UI）"""
	var weaknesses = enemy.get("weaknesses", [])
	var revealed = enemy.get("revealed_weaknesses", [])
	var display = []
	
	for w in weaknesses:
		if w in revealed:
			display.append({"type": w, "revealed": true})
		else:
			display.append({"type": "unknown", "revealed": false})
	
	return display

func get_break_multiplier() -> float:
	"""获取BREAK状态的伤害倍率"""
	return BREAK_DAMAGE_MULTIPLIER
