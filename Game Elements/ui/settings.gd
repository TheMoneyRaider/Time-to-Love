extends Control
var is_pause_settings = false
var mouse_sensitivity: float = 1.0
var joystick_acceleration: float = 7.0
const SETTINGS_FILE = "user://settings.cfg"
var debug_mode: bool = false
var crosshair_mode : bool = true
var display_pathways: bool = false
var mouse_clamping: bool = false
var toggle_invulnerability: bool = false
var controller_mode = true
var rewind_mode = 0
var display_mode = 0

var p1_dropdown_open: bool = false
var p2_dropdown_open: bool = false
var rewind_dropdown_open: bool = false

func load_settings():
	mouse_sensitivity = Globals.config.get_value("controls", "mouse_sensitivity", 1.0)
	controller_mode = Globals.config.get_value("controls","controller_mode", true)
	joystick_acceleration = Globals.config.get_value("controls","joystick_acceleration",7.0)
	hud_size = Globals.config.get_value("hud","size",5.0)
	debug_mode = Globals.config.get_value("debug", "enabled", false)
	crosshair_mode = Globals.config.get_value("settings", "crosshair", true) 
	frag_mode = Globals.config.get_value("fragmentation", "enabled", true)
	rewind_mode = Globals.config.get_value("rewind", "rewind_mode", 0)
	display_mode = Globals.config.get_value("display", "display_mode", 0)
	$MarginContainer/VBoxContainer/Volume/Volume.value = db_to_percent(Globals.config.get_value("audio", "master", 0))
	if Input.get_connected_joypads().size() == 0:
		Globals.player1_input = "key"
		Globals.player2_input = "0"
	else:
		Globals.player1_input = Globals.config.get_value("inputs","player1_input", "key")
		Globals.player2_input = Globals.config.get_value("inputs","player2_input", "0")
	mouse_sensitivity = Globals.config.get_value("controls", "mouse_sensitivity", 1.0)
	
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
				node.mouse_entered.connect(func(): SFXManager.play(preload("res://Game Elements/sfx/world/remnant_hover.ogg"), 0.0, "UI"))
				node.focus_entered.connect(func(): SFXManager.play(preload("res://Game Elements/sfx/world/remnant_hover.ogg"), 0.0, "UI"))
	
var frag_mode: bool = false
var hud_size: float = 5.0
var devices : Array[Array]=[[],[]]
func _on_back_pressed() -> void:
	SFXManager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"), 0.0, "UI")
	if is_pause_settings:
		queue_free()
		if Globals.is_multiplayer or Globals.player1_input != "key":
			get_parent().get_parent().get_node("Control/VBoxContainer/Return").grab_focus()
	else:
		get_tree().call_deferred("change_scene_to_file", "res://Game Elements/ui/main_menu/main_menu.tscn")

#
func _on_apply_settings()-> void:
	
	SFXManager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"), 0.0, "UI")
	var volslider = $MarginContainer/VBoxContainer/Volume/Volume
	Globals.config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	Globals.config.set_value("controls", "controller_mode", controller_mode)
	Globals.config.set_value("controls", "joystick_acceleration", joystick_acceleration)
	Globals.config.set_value("debug", "enabled", debug_mode)
	Globals.config.set_value("settings", "crosshair", crosshair_mode)
	Globals.config.set_value("fragmentation", "enabled", frag_mode)
	Globals.config.set_value("hud", "size", hud_size)
	Globals.config.set_value("inputs","player1_input", Globals.player1_input)
	Globals.config.set_value("inputs","player2_input", Globals.player2_input)
	Globals.config.set_value("rewind","rewind_mode",rewind_mode)
	Globals.config.set_value("display","display_mode",display_mode)
	
	Globals.config.set_value("audio", "master",percent_to_db(volslider.value))
	Globals.config.set_value("audio", "music", percent_to_db($MarginContainer/VBoxContainer/Music/Music.value))
	Globals.config.set_value("audio", "sfx",   percent_to_db($MarginContainer/VBoxContainer/SFX/SFX.value))
	Globals.config.set_value("audio", "ui",    percent_to_db($MarginContainer/VBoxContainer/UI/UI.value))
	Globals.save_config()
	var LayerManager = get_tree().get_root().get_node_or_null("LayerManager")
	if LayerManager:
		LayerManager.update_players_input_devices()
		LayerManager.hud.update_hud()
	

@onready var label := $MarginContainer/VBoxContainer/Volume/VolVal
# @export var bus_name: String = "Master"

func _ready() -> void:
	load_settings()
	$MarginContainer/VBoxContainer/Mouse/MouseSensitivity.value = mouse_sensitivity
	update_sensitivity_label()
	$"MarginContainer/VBoxContainer/Controller/Joystick Sensitivity".value = joystick_acceleration
	update_acceleration_label()
	
	$MarginContainer/VBoxContainer/Controller_Mode/ControllerMode.button_pressed = controller_mode
	update_controller_menu_label()
	
	$MarginContainer/VBoxContainer/HUD_Size/HUD_Size.value = hud_size
	
	# disconnect before setting to avoid triggering sounds
	$MarginContainer/VBoxContainer/Debug/DebugMode.toggled.disconnect(_on_debug_mode_toggled)
	$MarginContainer/VBoxContainer/Debug/DebugMode.button_pressed = debug_mode
	$MarginContainer/VBoxContainer/Debug/DebugMode.toggled.connect(_on_debug_mode_toggled)
	update_debug_menu_label()
	# disconnect before setting to avoid triggering sounds
	$MarginContainer/VBoxContainer/Crosshair/Crosshair.toggled.disconnect(_on_crosshair_mode_toggled)
	$MarginContainer/VBoxContainer/Crosshair/Crosshair.button_pressed = crosshair_mode
	$MarginContainer/VBoxContainer/Crosshair/Crosshair.toggled.connect(_on_crosshair_mode_toggled)
	update_crosshair_menu_label()
	
	
	$MarginContainer/VBoxContainer/Fragmenting/FragMode.toggled.disconnect(_on_frag_mode_toggled)
	$MarginContainer/VBoxContainer/Fragmenting/FragMode.button_pressed = frag_mode
	$MarginContainer/VBoxContainer/Fragmenting/FragMode.toggled.connect(_on_frag_mode_toggled)
	update_frag_menu_label()
	$MarginContainer/VBoxContainer/RewindMode/Choice.selected = rewind_mode
	$MarginContainer/VBoxContainer/DisplayMode/Choice.selected = display_mode
	
	refresh_devices(true)
	refresh_devices(false)
	$MarginContainer/VBoxContainer/Volume/Volume.grab_focus()
	
	$MarginContainer/VBoxContainer/Player1/Choice.pressed.connect(func():
		p1_dropdown_open = !p1_dropdown_open
		if p1_dropdown_open:
			SFXManager.play(preload("res://Game Elements/ui/sfx/maximize_008.ogg"), 0.0, "UI")
		else:
			SFXManager.play(preload("res://Game Elements/ui/sfx/minimize_008.ogg"), 0.0, "UI")
	)
	$MarginContainer/VBoxContainer/Player2/Choice.pressed.connect(func():
		p2_dropdown_open = !p2_dropdown_open
		if p2_dropdown_open:
			SFXManager.play(preload("res://Game Elements/ui/sfx/maximize_008.ogg"), 0.0, "UI")
		else:
			SFXManager.play(preload("res://Game Elements/ui/sfx/minimize_008.ogg"), 0.0, "UI")
	)
	
	$MarginContainer/VBoxContainer/RewindMode/Choice.pressed.connect(func():
		rewind_dropdown_open = !rewind_dropdown_open
		if rewind_dropdown_open:
			SFXManager.play(preload("res://Game Elements/ui/sfx/maximize_008.ogg"), 0.0, "UI")
		else:
			SFXManager.play(preload("res://Game Elements/ui/sfx/minimize_008.ogg"), 0.0, "UI")
	)
	 
func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		_on_back_pressed()
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

func set_joystick_acceleration(value: float):
	joystick_acceleration = clamp(value, 3, 14)
	update_acceleration_label()

func update_acceleration_label():
	$MarginContainer/VBoxContainer/Controller/SensLabel.text = "%.2f" % joystick_acceleration	

func set_hud_size(value: float):
	hud_size = clamp(value, 3.0, 12.0)

func _on_mouse_sensitivity_value_changed(value: float) -> void:
	set_mouse_sensitivity(value)
	pass # Replace with function body.

func update_debug_menu_label() -> void:
	if debug_mode == false: 
		$MarginContainer/VBoxContainer/Debug/DebugLabel.text = "Off"
	else:
		$MarginContainer/VBoxContainer/Debug/DebugLabel.text = "On"
		
func update_crosshair_menu_label() -> void:
	if crosshair_mode == false: 
		$MarginContainer/VBoxContainer/Crosshair/CrosshairLabel.text = "Off"
	else:
		$MarginContainer/VBoxContainer/Crosshair/CrosshairLabel.text = "On"
		
func _on_debug_mode_toggled(toggled_on: bool) -> void:
	if toggled_on:
		SFXManager.play(preload("res://Game Elements/ui/sfx/switch_on.ogg"), 0.0, "UI")
	else:
		SFXManager.play(preload("res://Game Elements/ui/sfx/switch_off.ogg"), 0.0, "UI")
	debug_mode = toggled_on
	update_debug_menu_label()
	

func _on_crosshair_mode_toggled(toggled_on: bool) -> void:
	if toggled_on:
		SFXManager.play(preload("res://Game Elements/ui/sfx/switch_on.ogg"))
	else:
		SFXManager.play(preload("res://Game Elements/ui/sfx/switch_off.ogg"))
	crosshair_mode = toggled_on
	update_crosshair_menu_label()
	
func update_frag_menu_label() -> void:
	if frag_mode == false: 
		$MarginContainer/VBoxContainer/Fragmenting/FragLabel.text = "Off"
	else:
		$MarginContainer/VBoxContainer/Fragmenting/FragLabel.text = "On"
		
func _on_frag_mode_toggled(toggled_on: bool) -> void:
	if toggled_on:
		SFXManager.play(preload("res://Game Elements/ui/sfx/switch_on.ogg"), 0.0, "UI")
	else:
		SFXManager.play(preload("res://Game Elements/ui/sfx/switch_off.ogg"), 0.0, "UI")
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
	p1_dropdown_open = false
	SFXManager.play(preload("res://Game Elements/ui/sfx/minimize_008.ogg"), 0.0, "UI")
	if devices[0][index]==Globals.player2_input:
		if Globals.player2_input=="key":
			Globals.player2_input = "0"
		else:
			Globals.player2_input = "key"
	Globals.player1_input = devices[0][index]
	refresh_devices(true)
	refresh_devices(false)
	

func _on_p2_selected(index : int):
	p2_dropdown_open = false
	SFXManager.play(preload("res://Game Elements/ui/sfx/minimize_008.ogg"), 0.0, "UI")
	if devices[1][index]==Globals.player1_input:
		if Globals.player1_input=="key":
			Globals.player1_input = "0"
		else:
			Globals.player1_input = "key"
	Globals.player2_input = devices[0][index]
	refresh_devices(true)
	refresh_devices(false)
	


func _on_joystick_sensitivity_value_changed(value: float) -> void:
	set_joystick_acceleration(value)


func _on_hud_size_changed(value: float) -> void:
	set_hud_size(value)
func _on_controller_mode_toggled(toggled_on: bool) -> void:
	if toggled_on:
		SFXManager.play(preload("res://Game Elements/ui/sfx/switch_on.ogg"), 0.0, "UI")
	else:
		SFXManager.play(preload("res://Game Elements/ui/sfx/switch_off.ogg"), 0.0, "UI")
	controller_mode = toggled_on
	update_controller_menu_label()

func update_controller_menu_label() -> void:
	if controller_mode == false: 
		$MarginContainer/VBoxContainer/Controller_Mode/ControllerLabel.text = "Off"
	else:
		$MarginContainer/VBoxContainer/Controller_Mode/ControllerLabel.text = "On"


func _on_rewind_mode_selected(index: int) -> void:
	rewind_dropdown_open = false
	SFXManager.play(preload("res://Game Elements/ui/sfx/minimize_008.ogg"), 0.0, "UI")
	rewind_mode = index

func _load_save_time(idx: int) -> float:
	var path = Globals.save_dir + "save_%d.res" % idx
	if ResourceLoader.exists(path):
		var loaded = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if loaded is SaveState:
			return loaded.time_spent
	return 0

func _on_feeback_pressed() -> void:
	SFXManager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"), 0.0, "UI")
	var total_save_time = 0
	for i in range(3):
		total_save_time += _load_save_time(i)
	var progress : String =str(Globals.save_state.total_progress)
	if get_tree().get_root().get_node_or_null("LayerManager"):
		progress= str(Globals.save_state.total_progress+RoomManager.layer_ai[3] + get_tree().get_root().get_node_or_null("LayerManager").time_passed)
	var gpu_name : String = RenderingServer.get_video_adapter_name()
	var gpu_api : String = RenderingServer.get_video_adapter_api_version()
	var gpu_adapter : String = str(RenderingServer.get_video_adapter_type())
	var cpu_name : String = OS.get_processor_name()
	var cpu_cores : String = str(OS.get_processor_count())
	var ram : String = str(OS.get_memory_info()["physical"] / 1073741824.0)
	var static_mem : String = str(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
	DisplayServer.clipboard_set(str(total_save_time) + "," + progress + ","  + gpu_name + "," + gpu_api + "," + gpu_adapter + "," + cpu_name + "," + cpu_cores + "," + ram + "," + static_mem)
	OS.shell_open("https://docs.google.com/forms/d/e/1FAIpQLSdi6Cud_Lk8Z1nC_vxo8Z86O0FkFxxIehl1sPip_KGtnudooA/viewform?usp=publish-editor")


func _on_display_item_selected(index: int) -> void:
	display_mode = index
	match display_mode:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN) 
