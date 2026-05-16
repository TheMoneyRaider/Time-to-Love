extends Control
var is_pause_settings = false
var mouse_sensitivity: float = 1.0
const SETTINGS_FILE = "user://settings.cfg"
var debug_mode: bool = false
var display_pathways: bool = false
var mouse_clamping: bool = false
var toggle_invulnerability: bool = false

func load_settings():
	mouse_sensitivity = Globals.config.get_value("controls", "mouse_sensitivity", 1.0)
	debug_mode = Globals.config.get_value("debug", "enabled", false)
	frag_mode = Globals.config.get_value("fragmentation", "enabled", true)
	$MarginContainer/VBoxContainer/Volume/Volume.value = db_to_percent(Globals.config.get_value("audio", "master", 0))
	Globals.player1_input = Globals.config.get_value("inputs","player1_input", "key")
	Globals.player2_input = Globals.config.get_value("inputs","player2_input", "0")
	mouse_sensitivity = Globals.config.get_value("controls", "mouse_sensitivity", 1.0)
	debug_mode = Globals.config.get_value("debug", "enabled", false)
	
	# audio settings 
	$MarginContainer/VBoxContainer/Volume/Volume.value = db_to_percent(Globals.config.get_value("audio", "master", 0))
	$MarginContainer/VBoxContainer/Music/Music.value   = db_to_percent(Globals.config.get_value("audio", "music", 0))   
	$MarginContainer/VBoxContainer/SFX/SFX.value       = db_to_percent(Globals.config.get_value("audio", "sfx", 0))     
	$MarginContainer/VBoxContainer/UI/UI.value         = db_to_percent(Globals.config.get_value("audio", "ui", 0))
	
	update_label($MarginContainer/VBoxContainer/Volume/Volume.value, $MarginContainer/VBoxContainer/Volume/VolVal)
	update_label($MarginContainer/VBoxContainer/Music/Music.value,   $MarginContainer/VBoxContainer/Music/MusicVal)     
	update_label($MarginContainer/VBoxContainer/SFX/SFX.value,       $MarginContainer/VBoxContainer/SFX/SFXVal)         
	update_label($MarginContainer/VBoxContainer/UI/UI.value,         $MarginContainer/VBoxContainer/UI/UIVal)           
	
	for child in $MarginContainer/VBoxContainer.get_children():
		for node in child.get_children():
			if node is Button:
				node.mouse_entered.connect(func(): sfx_manager.play(preload("res://Game Elements/sfx/world/remnant_hover.ogg")))
				node.focus_entered.connect(func(): sfx_manager.play(preload("res://Game Elements/sfx/world/remnant_hover.ogg")))
	
var frag_mode: bool = false
var devices : Array[Array]=[[],[]]
func _on_back_pressed() -> void:
	sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
	if is_pause_settings:
		queue_free()
		if Globals.is_multiplayer or Globals.player1_input != "key":
			get_parent().get_parent().get_node("Control/VBoxContainer/Return").grab_focus()
	else:
		get_tree().call_deferred("change_scene_to_file", "res://Game Elements/ui/main_menu/main_menu.tscn")

#
func _on_apply_settings()-> void:
	
	sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
	var volslider = $MarginContainer/VBoxContainer/Volume/Volume
	Globals.config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	Globals.config.set_value("debug", "enabled", debug_mode)
	Globals.config.set_value("fragmentation", "enabled", frag_mode)
	Globals.config.set_value("inputs","player1_input", Globals.player1_input)
	Globals.config.set_value("inputs","player2_input", Globals.player2_input)
	
	Globals.config.set_value("audio", "master",percent_to_db(volslider.value))
	Globals.config.set_value("audio", "music", percent_to_db($MarginContainer/VBoxContainer/Music/Music.value))
	Globals.config.set_value("audio", "sfx",   percent_to_db($MarginContainer/VBoxContainer/SFX/SFX.value))
	Globals.config.set_value("audio", "ui",    percent_to_db($MarginContainer/VBoxContainer/UI/UI.value))
	Globals.save_config()
	

@onready var label := $MarginContainer/VBoxContainer/Volume/VolVal
# @export var bus_name: String = "Master"

func _ready() -> void:
		
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
	set_bus_volume("Master", value)
	update_label(value, $MarginContainer/VBoxContainer/Volume/VolVal)
	
	#var bus_index = AudioServer.get_bus_index(bus_name)
	#AudioServer.set_bus_volume_db(bus_index, percent_to_db(value))

func _on_music_value_changed(value: float) -> void:
	set_bus_volume("Music", value)
	update_label(value, $MarginContainer/VBoxContainer/Music/MusicVal)

func _on_sfx_value_changed(value: float) -> void:
	set_bus_volume("SFX", value)
	update_label(value, $MarginContainer/VBoxContainer/SFX/SFXVal)

func _on_ui_value_changed(value: float) -> void:
	set_bus_volume("UI", value)
	update_label(value, $MarginContainer/VBoxContainer/UI/UIVal)

func update_label(v: float, lbl: Label) -> void:
	lbl.text = str(int(v)) + "%"
	
func set_bus_volume(bus_name: String, percent: float) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(idx, percent_to_db(percent))
	AudioServer.set_bus_mute(idx, percent <= 0.0)
	
func percent_to_db(percent: float) -> int:
	# Clamp to avoid weird negative values
	#var per = percent / 100
	#if per <= 0.0:
	#	return -40
	## Convert dB → linear gain (0.0–1.0)
	#var db := log(per) / log(10)
	#print(int(round(db)))
	#return int(round(db))
	
	var linear = percent / 100.00
	if linear <= 0.0:
		return -80.0
	return 20.0 * log(linear) / log(10)
	
func db_to_percent(db: int) -> float:
	if db <= -80:
		return 0.0
	return pow(10.0, db / 20.0) * 100.0

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
	if toggled_on:
		sfx_manager.play(preload("res://Game Elements/ui/sfx/switch_on.ogg"))
	else:
		sfx_manager.play(preload("res://Game Elements/ui/sfx/switch_off.ogg"))
	debug_mode = toggled_on
	update_debug_menu_label()
	
func update_frag_menu_label() -> void:
	if frag_mode == false: 
		$MarginContainer/VBoxContainer/Fragmenting/FragLabel.text = "Off"
	else:
		$MarginContainer/VBoxContainer/Fragmenting/FragLabel.text = "On"
		
func _on_frag_mode_toggled(toggled_on: bool) -> void:
	if toggled_on:
		sfx_manager.play(preload("res://Game Elements/ui/sfx/switch_on.ogg"))
	else:
		sfx_manager.play(preload("res://Game Elements/ui/sfx/switch_off.ogg"))
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
	
