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
	"medieval":	preload("res://Game Elements/Music/medieval.wav"),
	"shop": 	preload("res://Game Elements/Music/shopkeeper.wav")
}
var loop_tracks = {
	"main":		preload("res://Game Elements/Music/main_loop.wav"),
	"western":	preload("res://Game Elements/Music/western_loop.wav"),
	"scifi":	preload("res://Game Elements/Music/sci-fi_loop.wav"),
	"medieval":	preload("res://Game Elements/Music/medieval.wav"),
	"shop": 	preload("res://Game Elements/Music/shopkeeper.wav")
}

const NORMAL_VOLUME = 0.0
const PAUSED_VOLUME = -16.0
const FADE_DURATION = 0.5
var tween: Tween
var paused_value: bool = false

func quite_music(time: float):
	fade_volume(PAUSED_VOLUME)
	await get_tree().create_timer(time).timeout
	fade_volume(NORMAL_VOLUME)

func fade_volume(target_db: float):
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(active_player, "volume_db", target_db, FADE_DURATION)
	tween.parallel().tween_property(inactive_player, "volume_db", target_db, FADE_DURATION)

func _on_pause_changed():
	if get_tree().paused:
		fade_volume(PAUSED_VOLUME)
	else:
		fade_volume(NORMAL_VOLUME)
	paused_value = get_tree().paused

func _process(_delta: float):
	if paused_value != get_tree().paused:
		_on_pause_changed()

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

func play_theme(theme: String):
	var start = start_tracks[theme]
	if current_start == start and active_player.playing:
		return
	current_start = start
	active_player.stop()
	active_player.stream = start
	active_player.play()
	active_player.finished.connect(func():
		active_player.stream = loop_tracks[theme]
		active_player.play()
	, CONNECT_ONE_SHOT)

func stop():
	active_player.stop()
	current_start = null
