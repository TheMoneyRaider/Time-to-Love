extends Node

var music_player_a: AudioStreamPlayer
var music_player_b: AudioStreamPlayer
var active_player: AudioStreamPlayer
var inactive_player: AudioStreamPlayer
var current_start: AudioStream = null

var start_tracks = {
	"main":		preload("res://Game Elements/Music/main_start.wav"),
	"western":	preload("res://Game Elements/Music/western_start.wav"),
	"scifi": 	preload("res://Game Elements/Music/sci-fi_start.wav"),
	"medieval":	preload("res://Game Elements/Music/medieval_start.wav"),
	"shop_m": 	preload("res://Game Elements/Music/medieval_shopkeeper.wav"),
	"shop_w": 	preload("res://Game Elements/Music/western_shopkeeper.wav"),
	"shop_s":	preload("res://Game Elements/Music/scifi_shopkeeper.wav"),
}
var loop_tracks = {
	"main":		preload("res://Game Elements/Music/main_loop.wav"),
	"western":	preload("res://Game Elements/Music/western_loop.wav"),
	"scifi":	preload("res://Game Elements/Music/sci-fi_loop.wav"),
	"medieval":	preload("res://Game Elements/Music/medieval_loop.wav"),
	"shop_m": 	preload("res://Game Elements/Music/medieval_shopkeeper.wav"),
	"shop_w": 	preload("res://Game Elements/Music/western_shopkeeper.wav"),
	"shop_s":	preload("res://Game Elements/Music/scifi_shopkeeper.wav"),
}

const NORMAL_VOLUME = 0.0
const PAUSED_VOLUME = -16.0
const FADE_DURATION = 0.5
var tween: Tween
var paused_value: bool = false

# Starting room random state
var in_starting_mode: bool = false
var current_random_theme: String = ""
var starting_themes = ["western", "scifi", "medieval"]
var transitioning_track: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player_a = AudioStreamPlayer.new()
	music_player_a.bus = "Music"
	music_player_a.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player_a)
	music_player_b = AudioStreamPlayer.new()
	music_player_b.bus = "Music" 
	music_player_b.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player_b)
	active_player = music_player_a
	inactive_player = music_player_b

func _process(_delta: float):
	if paused_value != get_tree().paused:
		_on_pause_changed()
	if in_starting_mode and !active_player.playing and !transitioning_track:
		transitioning_track = true
		_play_random_next(current_random_theme)
		transitioning_track = false
		
		
func _on_pause_changed():
	if get_tree().paused:
		fade_volume(PAUSED_VOLUME)
	else:
		fade_volume(NORMAL_VOLUME)
	paused_value = get_tree().paused

func fade_volume(target_db: float):
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(active_player, "volume_db", target_db, FADE_DURATION)
	tween.parallel().tween_property(inactive_player, "volume_db", target_db, FADE_DURATION)

func quite_music(time: float):
	fade_volume(PAUSED_VOLUME)
	await get_tree().create_timer(time).timeout
	fade_volume(NORMAL_VOLUME)

func _clear_signals():
	for connection in active_player.finished.get_connections():
		active_player.finished.disconnect(connection["callable"])

func _play_theme_internal(theme: String):
	_clear_signals()
	current_start = start_tracks[theme]
	active_player.stop()
	active_player.volume_db = NORMAL_VOLUME
	active_player.stream = start_tracks[theme]
	active_player.play()
	active_player.finished.connect(func():
		active_player.stream = loop_tracks[theme]
		active_player.play()
		# reconnect loop so it keeps looping
		var loop_func = func(): 
			if active_player.stream == loop_tracks[theme]:
				active_player.play()
		active_player.finished.connect(loop_func)
	, CONNECT_ONE_SHOT)

func play_starting_room():
	in_starting_mode = true
	transitioning_track = false
	_play_random_next("")

func _play_random_next(exclude: String):
	if !in_starting_mode:
		return
	var available = _get_available_starting_themes(exclude)
	print("available: ", available, " exclude: ", exclude)
	if available.is_empty():
		current_random_theme = exclude
	else:
		current_random_theme = available[randi() % available.size()]
	_clear_signals()
	current_start = start_tracks[current_random_theme]
	active_player.stop()
	active_player.volume_db = NORMAL_VOLUME
	active_player.stream = start_tracks[current_random_theme]
	active_player.play()
	transitioning_track = false

func _get_available_starting_themes(exclude: String) -> Array:
	var progress = max(Globals.save_state.total_progress, Globals.total_progress, RoomManager.current_progress)
	return starting_themes.filter(func(t):
		if t == exclude:
			return false
		if t == "western" and progress < 1.0:
			return false
		if t == "scifi" and progress < 2.0:
			return false
		return true
	)

func play_theme(theme: String):
	in_starting_mode = false
	# don't restart if already playing this theme
	if current_start == start_tracks[theme] and active_player.playing:
		return
	_play_theme_internal(theme)

func stop():
	in_starting_mode = false
	current_random_theme = ""
	current_start = null
	transitioning_track = false
	_clear_signals()
	active_player.stop()
	active_player.volume_db = NORMAL_VOLUME

func swap_theme_limbo(theme: String) -> String:
	if RoomManager.current_progress >= 3.0:
		match theme:
			"western": return "shop_w"
			"scifi": return "shop_s"
			"medieval": return "shop_m"
	return theme

func _input(event):
	if event is InputEventKey and event.pressed and event.is_action("ui_end"):
		_clear_signals()
		active_player.seek(active_player.stream.get_length() - 0.1)
