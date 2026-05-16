extends Control

func _on_back_pressed() -> void:
	sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
	get_tree().call_deferred("change_scene_to_file", "res://Game Elements/ui/main_menu/main_menu.tscn")

var save_state1 : SaveState
var save_state2 : SaveState
var save_state3 : SaveState
func _load_save(idx: int) -> SaveState:
	var path = Globals.save_dir + "save_%d.res" % idx
	if ResourceLoader.exists(path):
		var loaded = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if loaded is SaveState:
			return loaded
	return SaveState.new()

func _delete_save(idx: int) -> void:
	sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
	var path = Globals.save_dir + "save_%d.res" % idx
	if ResourceLoader.exists(path):
		DirAccess.remove_absolute(path)

func _ready() -> void:
	save_state1 = _load_save(0)
	print(save_state1.time_spent)
	save_state2 = _load_save(1)
	save_state3 = _load_save(2)
	highlight_state()
	load_state($MarginContainer/VBoxContainer/Save1, save_state1)
	load_state($MarginContainer/VBoxContainer/Save2, save_state2)
	load_state($MarginContainer/VBoxContainer/Save3, save_state3)
	$MarginContainer/Back.grab_focus()

func _process(delta: float) -> void:
	$ColorRect.material.set_shader_parameter("time", $ColorRect.material.get_shader_parameter("time") + delta)

func highlight_state():
	$MarginContainer/VBoxContainer/Save1/TextureRect2.modulate = Color(0.5, 0.5, 0.5, 1.0) if Globals.save_idx == 0 else Color(1.0, 1.0, 1.0, 1.0)
	$MarginContainer/VBoxContainer/Save2/TextureRect2.modulate = Color(0.5, 0.5, 0.5, 1.0) if Globals.save_idx == 1 else Color(1.0, 1.0, 1.0, 1.0)
	$MarginContainer/VBoxContainer/Save3/TextureRect2.modulate = Color(0.5, 0.5, 0.5, 1.0) if Globals.save_idx == 2 else Color(1.0, 1.0, 1.0, 1.0)

func load_state(node: Node, save_state: SaveState):
	var time = node.get_node("HBoxContainer/Time")
	var texture = node.get_node("HBoxContainer/TextureRect")
	texture.texture = save_state.picture
	time.text = format_time(save_state.time_spent)

func format_time(seconds: float) -> String:
	var seconds_int : int = int(seconds)
	var hours = int(seconds_int / 3600)
	var minutes = int((seconds_int % 3600) / 60)
	var secs = seconds_int % 60
	return str(hours) + "hr " + str(minutes) + "m " + str(secs) + "s "

func _save1_select_pressed() -> void:
	sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
	Globals.save_idx = 0
	Globals.save_state = _load_save(0)
	Globals.total_progress = Globals.save_state.total_progress
	highlight_state()

func _save2_select_pressed() -> void:
	sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
	Globals.save_idx = 1
	Globals.save_state = _load_save(1)
	Globals.total_progress = Globals.save_state.total_progress
	highlight_state()

func _save3_select_pressed() -> void:
	sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
	Globals.save_idx = 2
	Globals.save_state = _load_save(2)
	Globals.total_progress = Globals.save_state.total_progress
	highlight_state()

func _on_delete1_pressed() -> void:
	sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
	$MarginContainer/VBoxContainer/Save1/HBoxContainer/Delete.visible = !$MarginContainer/VBoxContainer/Save1/HBoxContainer/Delete.visible
	$MarginContainer/VBoxContainer/Save2/HBoxContainer/Delete.visible = false
	$MarginContainer/VBoxContainer/Save3/HBoxContainer/Delete.visible = false

func _on_delete2_pressed() -> void:
	sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
	$MarginContainer/VBoxContainer/Save2/HBoxContainer/Delete.visible = !$MarginContainer/VBoxContainer/Save2/HBoxContainer/Delete.visible
	$MarginContainer/VBoxContainer/Save1/HBoxContainer/Delete.visible = false
	$MarginContainer/VBoxContainer/Save3/HBoxContainer/Delete.visible = false

func _on_delete3_pressed() -> void:
	sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
	$MarginContainer/VBoxContainer/Save3/HBoxContainer/Delete.visible = !$MarginContainer/VBoxContainer/Save3/HBoxContainer/Delete.visible
	$MarginContainer/VBoxContainer/Save1/HBoxContainer/Delete.visible = false
	$MarginContainer/VBoxContainer/Save2/HBoxContainer/Delete.visible = false

func _on_deletec1_pressed() -> void:
	sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
	_delete_save(0)
	save_state1 = SaveState.new()
	load_state($MarginContainer/VBoxContainer/Save1, save_state1)
	$MarginContainer/VBoxContainer/Save1/HBoxContainer/Delete.visible = false
	$MarginContainer/VBoxContainer/Save1/HBoxContainer/Options/Delete.grab_focus()
	if Globals.save_idx == 0:
		Globals.save_state = save_state1

func _on_deletec2_pressed() -> void:
	sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
	_delete_save(1)
	save_state2 = SaveState.new()
	load_state($MarginContainer/VBoxContainer/Save2, save_state2)
	$MarginContainer/VBoxContainer/Save2/HBoxContainer/Delete.visible = false
	$MarginContainer/VBoxContainer/Save2/HBoxContainer/Options/Delete.grab_focus()
	if Globals.save_idx == 1:
		Globals.save_state = save_state2

func _on_deletec3_pressed() -> void:
	sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
	_delete_save(2)
	save_state3 = SaveState.new()
	load_state($MarginContainer/VBoxContainer/Save3, save_state3)
	$MarginContainer/VBoxContainer/Save3/HBoxContainer/Delete.visible = false
	$MarginContainer/VBoxContainer/Save3/HBoxContainer/Options/Delete.grab_focus()
	if Globals.save_idx == 2:
		Globals.save_state = save_state3
