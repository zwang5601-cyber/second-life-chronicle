extends Resource
class_name Character
## 角色基类
## 定义所有角色（玩家/NPC）的基础属性和方法

@export var id: String = ""
@export var display_name: String = ""
@export var level: int = 1
@export var job: String = "novice"

# 基础属性
@export_group("属性")
@export var hp: int = 100
@export var hp_max: int = 100
@export var mp: int = 30
@export var mp_max: int = 30
@export var attack: int = 15
@export var defense: int = 10
@export var magic: int = 12
@export var magic_defense: int = 8
@export var speed: int = 10
@export var luck: int = 5

# 战斗相关
var bp: int = 0
var is_defending: bool = false
var exp: int = 0
var exp_to_next: int = 100

# 状态效果
var buffs: Array = []
var debuffs: Array = []

# 技能和装备
var skills: Array = []
var equipment: Dictionary = {
	"weapon": null,
	"armor": null,
	"accessory": null
}

func is_alive() -> bool:
	return hp > 0

func take_damage(amount: int) -> int:
	var actual_damage = amount
	
	# 防御减伤
	if is_defending:
		actual_damage = int(actual_damage * 0.5)
	
	hp = maxi(hp - actual_damage, 0)
	return actual_damage

func heal(amount: int) -> int:
	var actual_heal = mini(amount, hp_max - hp)
	hp += actual_heal
	return actual_heal

func use_mp(amount: int) -> bool:
	if mp >= amount:
		mp -= amount
		return true
	return false

func restore_mp(amount: int) -> int:
	var actual_restore = mini(amount, mp_max - mp)
	mp += actual_restore
	return actual_restore

func gain_exp(amount: int) -> bool:
	"""获得经验值，返回是否升级"""
	exp += amount
	if exp >= exp_to_next:
		level_up()
		return true
	return false

func level_up() -> void:
	"""升级"""
	while exp >= exp_to_next:
		exp -= exp_to_next
		level += 1
		
		# 属性成长
		hp_max += 40 + level * 2
		mp_max += 8 + level
		attack += 4
		defense += 3
		magic += 4
		magic_defense += 3
		speed += 2
		luck += 1
		
		# 升级后完全恢复
		hp = hp_max
		mp = mp_max
		
		# 计算下一级所需经验
		exp_to_next = int(100 * pow(level, 1.5))
		
		print("[Character] %s 升级到 Lv.%d!" % [display_name, level])

func to_dict() -> Dictionary:
	"""序列化为字典（用于存档和战斗）"""
	return {
		"id": id,
		"name": display_name,
		"level": level,
		"job": job,
		"hp": hp,
		"hp_max": hp_max,
		"mp": mp,
		"mp_max": mp_max,
		"attack": attack,
		"defense": defense,
		"magic": magic,
		"magic_defense": magic_defense,
		"speed": speed,
		"luck": luck,
		"bp": bp,
		"exp": exp,
		"exp_to_next": exp_to_next,
		"skills": skills,
		"equipment": equipment
	}

func from_dict(data: Dictionary) -> void:
	"""从字典加载"""
	id = data.get("id", "")
	display_name = data.get("name", "")
	level = data.get("level", 1)
	job = data.get("job", "novice")
	hp = data.get("hp", 100)
	hp_max = data.get("hp_max", 100)
	mp = data.get("mp", 30)
	mp_max = data.get("mp_max", 30)
	attack = data.get("attack", 15)
	defense = data.get("defense", 10)
	magic = data.get("magic", 12)
	magic_defense = data.get("magic_defense", 8)
	speed = data.get("speed", 10)
	luck = data.get("luck", 5)
	bp = data.get("bp", 0)
	exp = data.get("exp", 0)
	exp_to_next = data.get("exp_to_next", 100)
	skills = data.get("skills", [])
	equipment = data.get("equipment", {})

static func create_from_data(data: Dictionary) -> Dictionary:
	"""从数据创建战斗用字典"""
	var base_stats = data.get("base_stats", {})
	return {
		"id": data.get("id", ""),
		"name": data.get("name", "未知"),
		"level": 1,
		"job": data.get("job", "novice"),
		"hp": base_stats.get("hp", 100),
		"hp_max": base_stats.get("hp", 100),
		"mp": base_stats.get("mp", 30),
		"mp_max": base_stats.get("mp", 30),
		"attack": base_stats.get("attack", 15),
		"defense": base_stats.get("defense", 10),
		"magic": base_stats.get("magic", 12),
		"magic_defense": base_stats.get("magic_defense", 8),
		"speed": base_stats.get("speed", 10),
		"luck": base_stats.get("luck", 5),
		"bp": 0,
		"skills": data.get("skills", []),
		"is_defending": false
	}
