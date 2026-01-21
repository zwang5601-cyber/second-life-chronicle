extends Node
## 音频管理器
## 管理BGM和音效的播放

var bgm_player: AudioStreamPlayer
var se_players: Array[AudioStreamPlayer] = []
const MAX_SE_PLAYERS = 8

var bgm_volume: float = 0.8
var se_volume: float = 1.0
var is_muted: bool = false

func _ready() -> void:
	# 创建BGM播放器
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	add_child(bgm_player)
	
	# 创建SE播放器池
	for i in MAX_SE_PLAYERS:
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		se_players.append(player)
	
	print("[AudioManager] 初始化完成")

func play_bgm(stream: AudioStream, fade_in: float = 1.0) -> void:
	if is_muted or stream == null:
		return
	
	if bgm_player.playing:
		var tween = create_tween()
		tween.tween_property(bgm_player, "volume_db", -40, 0.5)
		await tween.finished
		bgm_player.stop()
	
	bgm_player.stream = stream
	bgm_player.volume_db = -40
	bgm_player.play()
	
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", linear_to_db(bgm_volume), fade_in)

func stop_bgm(fade_out: float = 1.0) -> void:
	if not bgm_player.playing:
		return
	
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", -40, fade_out)
	await tween.finished
	bgm_player.stop()

func play_se(stream: AudioStream, pitch: float = 1.0) -> void:
	if is_muted or stream == null:
		return
	
	# 找到空闲的播放器
	for player in se_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = linear_to_db(se_volume)
			player.pitch_scale = pitch
			player.play()
			return
	
	# 所有播放器都在使用，覆盖第一个
	se_players[0].stream = stream
	se_players[0].pitch_scale = pitch
	se_players[0].play()

func set_bgm_volume(volume: float) -> void:
	bgm_volume = clamp(volume, 0.0, 1.0)
	if bgm_player.playing:
		bgm_player.volume_db = linear_to_db(bgm_volume)

func set_se_volume(volume: float) -> void:
	se_volume = clamp(volume, 0.0, 1.0)

func toggle_mute() -> void:
	is_muted = not is_muted
	if is_muted:
		bgm_player.stop()
