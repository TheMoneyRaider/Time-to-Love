extends Node

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func play(stream: AudioStream, volume_db: float = 0.0, bus: String = "SFX", location : Vector2 = Vector2(-99999,-99999),
			attenuation : float = 1.0, pitch: float = 1.0) -> void:
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
