extends Node

var continuous_players: Dictionary = {}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func play(stream: AudioStream, volume_db: float = 0.0, bus: String = "SFX", location : Vector2 = Vector2(-99999,-99999),
			attenuation : float = 1.0, pitch: float = 1.0):
	var player
	if location ==Vector2(-99999,-99999):
		player = AudioStreamPlayer.new()
	else:
		player = AudioStreamPlayer2D.new()
		player.global_position = location
		player.attenuation = attenuation
		player.max_distance = 600
		volume_db+=7.0
	player.stream = stream
	player.bus = bus
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	if(is_instance_valid(get_tree().root.get_node_or_null("LayerManager"))):
		get_tree().root.get_node("LayerManager").game_root.add_child(player)
	else:
		add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
	return player


func stop_all_continuous_sounds():
	for player in continuous_players.values():
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	continuous_players.clear()
		

func play_continuous(key: String, stream: AudioStream, volume_db: float = 0.0, bus: String = "SFX", pitch: float = 1.0) -> void:
	if continuous_players.has(key):
		return
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)  # always on SFXManager, immune to game_root pausing
	player.play()
	continuous_players[key] = player
	
func stop_continuous(key: String) -> void: 
	if continuous_players.has(key):
		var player = continuous_players[key]
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
		continuous_players.erase(key)
	

func play_fadeout(stream: AudioStream, fadeout_time: float, volume_db: float = 0.0, bus: String = "SFX", pitch: float = 1.0) -> void:
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	player.play()
	var tween = create_tween()
	tween.tween_property(player, "volume_db", -80.0, fadeout_time)
	tween.tween_callback(player.queue_free)
