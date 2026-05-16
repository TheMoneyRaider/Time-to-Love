extends Control

func _ready() -> void:
	var config := ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		var volume = config.get_value("audio", "master", 0)
		var bus_index = AudioServer.get_bus_index("Master")
		print(volume)
		AudioServer.set_bus_volume_db(bus_index, volume)

func _on_start_button_pressed() -> void:
	sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
	Globals.is_multiplayer = false
	get_tree().call_deferred("change_scene_to_file", "res://Game Elements/General Game/layer_manager.tscn")

func _on_start_m_button_pressed() -> void:
	sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
	Globals.is_multiplayer =true
	get_tree().call_deferred("change_scene_to_file", "res://Game Elements/General Game/layer_manager.tscn")

func _on_settings_button_pressed() -> void:
	sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
	get_tree().call_deferred("change_scene_to_file", "res://Game Elements/ui/settings.tscn")

func _on_quit_button_pressed() -> void:
	sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
	get_tree().quit()


func _on_save_state_button_pressed() -> void:
	sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
	print("save")
	get_tree().call_deferred("change_scene_to_file", "res://Game Elements/ui/save_states/saves.tscn")
