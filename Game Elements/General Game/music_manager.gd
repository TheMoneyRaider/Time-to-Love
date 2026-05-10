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
	"medieval":	preload("res://Game Elements/Music/medieval.wav")
}

var loop_tracks = {
	"main":		preload("res://Game Elements/Music/main_loop.wav"),
	"western":	preload("res://Game Elements/Music/western_loop.wav"),
	"scifi":	preload("res://Game Elements/Music/sci-fi_loop.wav"),
	"medieval":	preload("res://Game Elements/Music/medieval.wav"),
	"shop": 	preload("res://Game Elements/Music/shopkeeper.wav")
}

func _ready():
	music_player_a = AudioStreamPlayer.new()
	music_player_a.bus = "Music"
	add_child(music_player_a)
	music_player_b = AudioStreamPlayer.new()
	music_player_b.bus = "Music"
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
