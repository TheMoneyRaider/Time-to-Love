extends Control
var is_pause_settings = false
var mouse_sensitivity: float = 1.0
const SETTINGS_FILE = "user://settings.cfg"
var debug_mode: bool = false
var display_pathways: bool = false
var mouse_clamping: bool = false
var toggle_invulnerability: bool = false

func load_settings():
	if Globals.config_safe:
		mouse_sensitivity = Globals.config.get_value("controls", "mouse_sensitivity", 1.0)
		debug_mode = Globals.config.get_value("debug", "enabled", false)
		frag_mode = Globals.config.get_value("fragmentation", "enabled", true)
		$MarginContainer/VBoxContainer/Volume/Volume.value = Globals.config.get_value("audio", "master", 100)
		Globals.player1_input = Globals.config.get_value("inputs","player1_input", "key")
		Globals.player2_input = Globals.config.get_value("inputs","player2_input", "0")
		mouse_sensitivity = Globals.config.get_value("controls", "mouse_sensitivity", 1.0)
		print(Globals.config.get_value("debug", "enabled", false))
		debug_mode = Globals.config.get_value("debug", "enabled", false)
		$MarginContainer/VBoxContainer/Volume/Volume.value = Globals.config.get_value("audio", "master", 100)
		
func save_settings():
	var config = ConfigFile.new()
	
	var volslider = $MarginContainer/VBoxContainer/Volume/Volume
	config.set_value("audio", "master", volslider.value)
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("debug", "enabled", debug_mode)
	config.set_value("debug", "display_pathways", display_pathways)
	config.set_value("debug", "mouse_clamping", mouse_clamping)
	config.set_value("debug", "toggle_invulnerability", toggle_invulnerability)
	config.save(SETTINGS_FILE)
var frag_mode: bool = false
var devices : Array[Array]=[[],[]]
func _on_back_pressed() -> void:
	if is_pause_settings:
		queue_free()
		if Globals.is_multiplayer or Globals.player1_input != "key":
			get_parent().get_parent().get_node("Control/VBoxContainer/Return").grab_focus()
	else:
		get_tree().call_deferred("change_scene_to_file", "res://Game Elements/ui/main_menu/main_menu.tscn")


func _on_apply_settings()-> void:
	
	var volslider = $MarginContainer/VBoxContainer/Volume/Volume
	Globals.config.set_value("audio", "master", volslider.value)
	Globals.config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	Globals.config.set_value("debug", "enabled", debug_mode)
	Globals.config.set_value("fragmentation", "enabled", frag_mode)
	Globals.config.set_value("inputs","player1_input", Globals.player1_input)
	Globals.config.set_value("inputs","player2_input", Globals.player2_input)
	Globals.save_config()
	

@onready var label := $MarginContainer/VBoxContainer/Volume/VolVal
@export var bus_name: String = "Master"

func _ready() -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	var value = AudioServer.get_bus_volume_db(bus_index)
		
	_on_volume_value_changed(value)
	load_settings()

	$MarginContainer/VBoxContainer/Mouse/MouseSensitivity.value = mouse_sensitivity
	update_sensitivity_label()
		
	$MarginContainer/VBoxContainer/Debug/DebugMode.button_pressed = debug_mode
	update_debug_menu_label()
	
	$MarginContainer/VBoxContainer/Fragmenting/FragMode.button_pressed = frag_mode
	update_frag_menu_label()
	
	refresh_devices(true)
	refresh_devices(false)
	$MarginContainer/VBoxContainer/Volume/Volume.grab_focus()
	 
func _process(delta):
	$ColorRect.material.set_shader_parameter("time", $ColorRect.material.get_shader_parameter("time")+delta)
	if Input.get_connected_joypads().size() != (devices[0].size()-1):
		refresh_devices(true)
		refresh_devices(false)
	
func _on_volume_value_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(bus_index, percent_to_db(value))
	
	update_label(value)
	pass # Replace with function body.

func update_label(v: float) -> void:
	label.text = str(int(v)) + "%"
	
func percent_to_db(percent: float) -> int:
	# Clamp to avoid weird negative values
	var per = percent / 100
	if per <= 0.0:
		return -40
	# Convert dB → linear gain (0.0–1.0)
	var db := log(per) / log(10)
	return int(round(db))


func set_mouse_sensitivity(value: float): 
	mouse_sensitivity = clamp(value, .1, 2.0)
	update_sensitivity_label()

func update_sensitivity_label():
	$MarginContainer/VBoxContainer/Mouse/SensLabel.text = "%.2f" % mouse_sensitivity

func _on_mouse_sensitivity_value_changed(value: float) -> void:
	set_mouse_sensitivity(value)
	pass # Replace with function body.

func update_debug_menu_label() -> void:
	if debug_mode == false: 
		$MarginContainer/VBoxContainer/Debug/DebugLabel.text = "Off"
	else:
		$MarginContainer/VBoxContainer/Debug/DebugLabel.text = "On"
		
func _on_debug_mode_toggled(toggled_on: bool) -> void:
	debug_mode = toggled_on
	update_debug_menu_label()
	
func update_frag_menu_label() -> void:
	if frag_mode == false: 
		$MarginContainer/VBoxContainer/Fragmenting/FragLabel.text = "Off"
	else:
		$MarginContainer/VBoxContainer/Fragmenting/FragLabel.text = "On"
		
func _on_frag_mode_toggled(toggled_on: bool) -> void:
	frag_mode = toggled_on
	update_frag_menu_label()
	
	
func refresh_devices(is_purple : bool = true):
	if Input.get_connected_joypads().size() == 0:
		Globals.player1_input = "key"
		Globals.player2_input = "0"
	var path = "MarginContainer/VBoxContainer/Player"+str(int(!is_purple)+1)+"/Choice"
	var choice := get_node(path)
	devices[int(!is_purple)].clear()
	choice.clear()

	# Add keyboard as a selectable option
	devices[int(!is_purple)].append("key")
	choice.add_item("Keyboard")

	# Add all connected controllers
	var joypads = Input.get_connected_joypads()
	for device_id in joypads:
		var d_name : String = str(Input.get_joy_name(device_id))
		devices[int(!is_purple)].append(str(device_id))
		choice.add_item(d_name)
	var new_device = Globals.player1_input if is_purple else Globals.player2_input
	for idx in range(devices[int(!is_purple)].size()):
		if devices[int(!is_purple)][idx]==new_device:
			choice.selected = idx
			return
	choice.selected = -1

func _on_p1_selected(index : int):
	if devices[0][index]==Globals.player2_input:
		if Globals.player2_input=="key":
			Globals.player2_input = "0"
		else:
			Globals.player2_input = "key"
	Globals.player1_input = devices[0][index]
	refresh_devices(true)
	refresh_devices(false)
	

func _on_p2_selected(index : int):
	if devices[1][index]==Globals.player1_input:
		if Globals.player1_input=="key":
			Globals.player1_input = "0"
		else:
			Globals.player1_input = "key"
	Globals.player2_input = devices[0][index]
	refresh_devices(true)
	refresh_devices(false)
	
