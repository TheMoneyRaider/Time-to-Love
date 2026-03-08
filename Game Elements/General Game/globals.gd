extends Node


var is_multiplayer:bool = false
var player1_input
var player2_input

signal config_changed

var config := ConfigFile.new()
var config_safe = false
var config_path := "user://settings.cfg"

enum MenuState {Western, Space, Horror, Medieval}

enum RoomVariant {MedOut, MedIn, WesternCanyon, WesternTown, HorrorDocks, HorrorMansion, SciFiCyberspace, SciFiFactory}
enum RoomType {Buffer, Combat, Shop, Boss, Misc}

enum Liquid {Buffer, Water, Lava, Acid, Conveyer, Glitch} #Don't mess with the buffer
enum Direction {Up, Right, Left, Down, Error}
enum Trap {Tile, Spike, Fire, Snare}
enum Reward {TimeFabric, Remnant, RemnantUpgrade, HealthUpgrade, Health, Shop, Boss}


var menu : MenuState

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var err = load_config()
	if err == OK:
		config_safe=true
		player1_input = config.get_value("inputs","player1_input", "key")
		player2_input = config.get_value("inputs","player2_input", "0")
	randomize()
	menu = randi()%4 as MenuState
func load_config():
	var err = config.load(config_path)
	if err != OK:
		print("Failed to load config:", err)
	return err

func save_config():
	config.save(config_path)
	emit_signal("config_changed")
