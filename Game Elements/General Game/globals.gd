extends Node


var is_multiplayer:bool = false
var player1_input
var player2_input
var total_progress : float = 0.0
var current_progress : float = 0.0

signal config_changed
var save_state : SaveState
var save_idx : int = 0
var config := ConfigFile.new()
var config_path := "user://settings.cfg"

enum MenuState {Western, Space, Horror, Medieval}

enum RoomVariant {MedOut, MedIn, WesternCanyon, WesternTown, HorrorDocks, HorrorMansion, SciFiCyberspace, SciFiFactory}
enum RoomType {Buffer, Combat, Shop, Boss, Misc}

enum Liquid {Buffer, Water, Lava, Acid, Conveyer, Glitch} #Don't mess with the buffer
enum Direction {Up, Right, Left, Down, Error}
enum Trap {Tile, Spike, Fire}
enum Reward {TimeFabric, Remnant, RemnantUpgrade, HealthUpgrade, Health, Shop, Boss}


var menu : MenuState


var letter_percentage : float = 0.0
var num_letters : int = 0
var num_letters_collected : int = 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_config()
	player1_input = config.get_value("inputs","player1_input", "key")
	player2_input = config.get_value("inputs","player2_input", "0")
	randomize()
	menu = randi()%4 as MenuState
	num_letters_collected = save_state.letter_progress.size()
	_count_all_letters()
	letter_percentage = num_letters_collected/float(num_letters)
	
func load_config():
	var err = config.load(config_path)
	if err != OK:
		print("Failed to load config:", err)
	save_idx = config.get_value("saves", "save_idx",0)
	save_state = config.get_value("saves", str(save_idx), SaveState.new())
	total_progress = save_state.total_progress

func save_config():
	save_state.total_progress = max(total_progress,current_progress)
	config.set_value("saves", str(save_idx), save_state)
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
