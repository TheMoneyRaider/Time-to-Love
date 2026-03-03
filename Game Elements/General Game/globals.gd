extends Node


var is_multiplayer:bool = false
var player1_input
var player2_input
var total_progress : float = 2.3
var current_progress : float = 0.0

signal config_changed
var remnant_progress : Dictionary = {}
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

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_config()
	player1_input = config.get_value("inputs","player1_input", "key")
	player2_input = config.get_value("inputs","player2_input", "0")
	total_progress = config.get_value("progress","total_progress", 0.0)
	randomize()
	menu = randi()%4 as MenuState
func load_config():
	var err = config.load(config_path)
	if err != OK:
		print("Failed to load config:", err)

	remnant_progress = config.get_value("progress", "remnant_progress", {})

func save_config():
	config.set_value("progress","total_progress", max(total_progress,current_progress))
	config.set_value("progress", "remnant_progress", remnant_progress)
	config.save(config_path)
	emit_signal("config_changed")

func record_remnant(remnant_name: String, rank: int, save_instantly : bool = false):
	if remnant_name in remnant_progress:
		remnant_progress[remnant_name] = max(remnant_progress[remnant_name], rank)
	else:
		remnant_progress[remnant_name] = rank
	if save_instantly:
		save_config()
