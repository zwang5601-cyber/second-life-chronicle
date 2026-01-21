extends Node
## 存档管理器
## 处理游戏存档的保存和加载

const SAVE_DIR = "user://saves/"
const SAVE_EXTENSION = ".sav"
const MAX_SLOTS = 3
const SAVE_VERSION = "0.1.0"

var current_slot: int = 0

signal save_completed(slot: int)
signal load_completed(slot: int)
signal save_failed(error: String)

func _ready() -> void:
	# 确保存档目录存在
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	print("[SaveManager] 初始化完成")

func get_save_path(slot: int) -> String:
	return SAVE_DIR + "slot_%d%s" % [slot, SAVE_EXTENSION]

func save_game(slot: int = -1) -> bool:
	if slot < 0:
		slot = current_slot
	
	var save_data = collect_save_data()
	var json_string = JSON.stringify(save_data, "\t")
	
	var file = FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	if file == null:
		var error = FileAccess.get_open_error()
		save_failed.emit("无法创建存档文件: " + str(error))
		return false
	
	file.store_string(json_string)
	file.close()
	
	current_slot = slot
	save_completed.emit(slot)
	print("[SaveManager] 存档保存到槽位 %d" % slot)
	return true

func load_game(slot: int = -1) -> bool:
	if slot < 0:
		slot = current_slot
	
	var path = get_save_path(slot)
	if not FileAccess.file_exists(path):
		save_failed.emit("存档不存在")
		return false
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		save_failed.emit("无法读取存档")
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) != OK:
		save_failed.emit("存档数据损坏")
		return false
	
	var save_data = json.data
	
	# 版本检查
	var save_version = save_data.get("version", "0.0.0")
	if save_version != SAVE_VERSION:
		print("[SaveManager] 存档版本不匹配: %s (当前: %s)" % [save_version, SAVE_VERSION])
		# TODO: 实现版本迁移
	
	apply_save_data(save_data)
	current_slot = slot
	
	load_completed.emit(slot)
	print("[SaveManager] 从槽位 %d 加载存档" % slot)
	return true

func collect_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"game_day": GameManager.game_day,
		"game_time": GameManager.game_time,
		"player_gold": GameManager.player_gold,
		"player_party": [],  # TODO: 序列化队伍
		"inventory": {},     # TODO: 序列化背包
		"base": {},          # TODO: 序列化据点
		"quests": [],        # TODO: 序列化任务
		"flags": {}          # TODO: 序列化剧情标记
	}

func apply_save_data(data: Dictionary) -> void:
	GameManager.game_day = data.get("game_day", 1)
	GameManager.game_time = data.get("game_time", 6.0)
	GameManager.player_gold = data.get("player_gold", 100)
	# TODO: 恢复更多数据

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot))

func delete_save(slot: int) -> bool:
	var path = get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		print("[SaveManager] 删除槽位 %d 的存档" % slot)
		return true
	return false

func get_save_info(slot: int) -> Dictionary:
	"""获取存档信息（用于显示）"""
	if not has_save(slot):
		return {}
	
	var file = FileAccess.open(get_save_path(slot), FileAccess.READ)
	if file == null:
		return {}
	
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	
	var data = json.data
	return {
		"day": data.get("game_day", 1),
		"time": data.get("game_time", 6.0),
		"gold": data.get("player_gold", 0),
		"timestamp": data.get("timestamp", 0)
	}
