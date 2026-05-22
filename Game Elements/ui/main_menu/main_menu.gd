extends Control

func _ready() -> void:
	var config := ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		var volume = config.get_value("audio", "master", 0)
		var display_mode = config.get_value("display","display_mode",0)
		if(display_mode == 0):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN) 
		var bus_index = AudioServer.get_bus_index("Master")
		AudioServer.set_bus_volume_db(bus_index, volume)

func _on_start_button_pressed() -> void:
	Globals.is_multiplayer = false
	get_tree().call_deferred("change_scene_to_file", "res://Game Elements/General Game/layer_manager.tscn")

func _on_start_m_button_pressed() -> void:
	Globals.is_multiplayer =true
	get_tree().call_deferred("change_scene_to_file", "res://Game Elements/General Game/layer_manager.tscn")

func _on_settings_button_pressed() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://Game Elements/ui/settings.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_save_state_button_pressed() -> void:
	print("save")
	get_tree().call_deferred("change_scene_to_file", "res://Game Elements/ui/save_states/saves.tscn")
