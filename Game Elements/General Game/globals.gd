extends Node


var is_multiplayer:bool = false
var player1_input
var player2_input
var total_progress : float = 0.0

signal config_changed
var save_state : SaveState
var save_idx : int = 0
var config := ConfigFile.new()
var config_path := "user://settings.cfg"
var save_dir := "user://saves/"
var cinematic_viewed : bool = false

enum MenuState {Western, Space, Medieval}

enum RoomVariant {MedOut, MedIn, WesternCanyon, WesternTown, SciFiCyberspace, SciFiFactory}
enum RoomType {Buffer, Combat, Shop, Boss, Misc}

enum Liquid {Buffer, Water, Lava, Acid, Conveyer, Glitch} #Don't mess with the buffer
enum Direction {Up, Right, Left, Down, Error}
enum Trap {Tile, Spike, Fire, Snare, CryptSpike}
enum Reward {TimeFabric, Remnant, RemnantUpgrade, HealthUpgrade, Health, Shop, Boss}


var menu : MenuState


var letter_percentage : float = 0.0
var num_letters : int = 0
var num_letters_collected : int = 0

func _ready():
	Engine.max_fps = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_config()
	apply_audio_settings()
	player1_input = config.get_value("inputs","player1_input", "key")
	player2_input = config.get_value("inputs","player2_input", "0")
	randomize()
	menu = randi()%3 as MenuState
	num_letters_collected = save_state.letter_progress.size()
	_count_all_letters()
	letter_percentage = num_letters_collected/float(num_letters)
	
func _save_path() -> String:
	return save_dir + "save_%d.res" % save_idx
	
func load_config():
	var err = config.load(config_path)
	if err != OK:
		print("Failed to load config: ", err)
	save_idx = config.get_value("saves", "save_idx", 0)

	var path = _save_path()
	if ResourceLoader.exists(path):
		var loaded = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if loaded is SaveState:
			save_state = loaded
		else:
			push_warning("Save file exists but isn't a SaveState, creating new one.")
			save_state = SaveState.new()
	else:
		save_state = SaveState.new()

	total_progress = save_state.total_progress

func apply_audio_settings():
	var bus_map = {
		"master": "Master",
		"music": "Music",
		"sfx": "SFX",
		"ui": "UI"
	}
	for key in bus_map:
		var db = config.get_value("audio", key, 0)
		var idx = AudioServer.get_bus_index(bus_map[key])
		if idx != -1:
			AudioServer.set_bus_volume_db(idx, db)
			AudioServer.set_bus_mute(idx, db <= -80)

func save_config():
	total_progress = max(total_progress, RoomManager.current_progress)
	save_state.total_progress = total_progress
	DirAccess.make_dir_recursive_absolute(save_dir)  # ensure it exists every time
	var err = ResourceSaver.save(save_state, _save_path())
	if err != OK:
		push_error("Failed to save SaveState: ", err)
	config.set_value("saves", "save_idx", save_idx)
	config.save(config_path)
	emit_signal("config_changed")

func record_remnant(remnant_name: String, rank: int, save_instantly : bool = false):
	if remnant_name in save_state.remnant_progress:
		save_state.remnant_progress[remnant_name] = max(save_state.remnant_progress[remnant_name], rank)
	else:
		save_state.remnant_progress[remnant_name] = rank
	if save_instantly:
		save_config()
		

func _count_all_letters() -> void:
	var dir = ResourceLoader.list_directory("res://Game Elements/ui/guide/letters/")
	if dir == null:
		push_error("Letters folder not found: res://Game Elements/ui/guide/letters/")
		return
	for file in dir:
		if file.ends_with(".tres"):
			num_letters+=1
			
			
func invert_direction(direct : Direction) -> Direction:
	match direct:
		Direction.Left:
			return Direction.Right
		Direction.Right:
			return Direction.Left
		Direction.Up:
			return Direction.Down
		Direction.Down:
			return Direction.Up
	return Direction.Error
	
