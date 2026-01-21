extends Node
## 数据管理器
## 加载和管理所有游戏数据（角色、技能、敌人、物品等）

var characters: Dictionary = {}
var enemies: Dictionary = {}
var skills: Dictionary = {}
var items: Dictionary = {}
var buildings: Dictionary = {}
var recipes: Dictionary = {}

const DATA_PATH = "res://assets/data/"

func _ready() -> void:
	load_all_data()
	print("[DataManager] 数据加载完成")
	print("  - 角色: %d" % characters.size())
	print("  - 敌人: %d" % enemies.size())
	print("  - 技能: %d" % skills.size())
	print("  - 物品: %d" % items.size())

func load_all_data() -> void:
	characters = load_json("characters.json")
	enemies = load_json("enemies.json")
	skills = load_json("skills.json")
	items = load_json("items.json")
	buildings = load_json("buildings.json")
	recipes = load_json("recipes.json")

func load_json(filename: String) -> Dictionary:
	var path = DATA_PATH + filename
	if not FileAccess.file_exists(path):
		push_warning("[DataManager] 文件不存在: " + path)
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("[DataManager] JSON解析错误: " + filename + " - " + json.get_error_message())
		return {}
	
	return json.data

func get_character(id: String) -> Dictionary:
	return characters.get(id, {})

func get_enemy(id: String) -> Dictionary:
	return enemies.get(id, {})

func get_skill(id: String) -> Dictionary:
	return skills.get(id, {})

func get_item(id: String) -> Dictionary:
	return items.get(id, {})

func get_building(id: String) -> Dictionary:
	return buildings.get(id, {})

func get_recipe(id: String) -> Dictionary:
	return recipes.get(id, {})

func get_all_enemies() -> Array:
	return enemies.values()

func get_enemies_by_difficulty(max_cost: float) -> Array:
	"""获取难度预算内的敌人列表"""
	var result = []
	for enemy in enemies.values():
		if enemy.get("difficulty_cost", 0) <= max_cost:
			result.append(enemy)
	return result
