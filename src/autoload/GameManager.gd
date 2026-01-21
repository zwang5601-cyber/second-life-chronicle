extends Node
## 游戏全局管理器
## 管理游戏状态、场景切换、时间系统

enum GameState {
	MAIN_MENU,
	BASE,      # 据点
	EXPLORE,   # 探索（节点地图）
	BATTLE,    # 战斗
	DIALOGUE,  # 对话
	PAUSED
}

var current_state: GameState = GameState.MAIN_MENU
var game_day: int = 1
var game_time: float = 6.0  # 6:00 开始
var is_night: bool = false

# 玩家数据
var player_gold: int = 100
var player_party: Array = []

signal state_changed(new_state: GameState)
signal day_changed(day: int)
signal time_changed(time: float)
signal night_started()
signal night_ended()
signal gold_changed(new_amount: int)

func _ready() -> void:
	print("[GameManager] 初始化完成 - 异世界人生录 v0.1.0")

func change_state(new_state: GameState) -> void:
	if current_state != new_state:
		var old_state = current_state
		current_state = new_state
		state_changed.emit(new_state)
		print("[GameManager] 状态: %s -> %s" % [GameState.keys()[old_state], GameState.keys()[new_state]])

func advance_time(hours: float) -> void:
	game_time += hours
	if game_time >= 24.0:
		game_time -= 24.0
		game_day += 1
		day_changed.emit(game_day)
		print("[GameManager] 新的一天: 第 %d 天" % game_day)
	
	# 检查日夜切换
	var was_night = is_night
	is_night = game_time >= 18.0 or game_time < 6.0
	
	if is_night and not was_night:
		night_started.emit()
		print("[GameManager] 夜幕降临...")
	elif not is_night and was_night:
		night_ended.emit()
		print("[GameManager] 黎明到来...")
	
	time_changed.emit(game_time)

func get_time_string() -> String:
	var hour = int(game_time)
	var minute = int((game_time - hour) * 60)
	return "%02d:%02d" % [hour, minute]

func add_gold(amount: int) -> void:
	player_gold += amount
	gold_changed.emit(player_gold)

func spend_gold(amount: int) -> bool:
	if player_gold >= amount:
		player_gold -= amount
		gold_changed.emit(player_gold)
		return true
	return false
