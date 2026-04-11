extends Control

func _on_back_pressed() -> void:
	if save_config:
		Globals.save_config()
	get_tree().call_deferred("change_scene_to_file", "res://Game Elements/ui/main_menu/main_menu.tscn")

var save_state1 : SaveState
var save_state2 : SaveState
var save_state3 : SaveState
var save_config : bool = false
func _ready() -> void:
	save_state1 = Globals.config.get_value("saves", "0", SaveState.new())
	save_state2 = Globals.config.get_value("saves", "1", SaveState.new())
	save_state3 = Globals.config.get_value("saves", "2", SaveState.new())
	highlight_state()
	load_state($MarginContainer/VBoxContainer/Save1,save_state1)
	load_state($MarginContainer/VBoxContainer/Save2,save_state2)
	load_state($MarginContainer/VBoxContainer/Save3,save_state3)
	$MarginContainer/Back.grab_focus()
	
func _process(delta: float) -> void:
	$ColorRect.material.set_shader_parameter("time", $ColorRect.material.get_shader_parameter("time")+delta)	

func highlight_state():
	$MarginContainer/VBoxContainer/Save1/TextureRect2.modulate = Color(0.5, 0.5, 0.5, 1.0) if Globals.save_idx == 0 else Color(1.0, 1.0, 1.0, 1.0)
	$MarginContainer/VBoxContainer/Save2/TextureRect2.modulate = Color(0.5, 0.5, 0.5, 1.0) if Globals.save_idx == 1 else Color(1.0, 1.0, 1.0, 1.0)
	$MarginContainer/VBoxContainer/Save3/TextureRect2.modulate = Color(0.5, 0.5, 0.5, 1.0) if Globals.save_idx == 2 else Color(1.0, 1.0, 1.0, 1.0)
	
func load_state(node : Node, save_state : SaveState):
	var time = node.get_node("HBoxContainer/Time")
	var texture = node.get_node("HBoxContainer/TextureRect")
	texture.texture = save_state.picture
	time.text = format_time(save_state.time_spent)
	
	
func format_time(seconds: float) -> String:
	var seconds_int : int = int(seconds)

	var hours = int(seconds_int / 3600)
	var minutes = int((seconds_int % 3600) / 60)
	var secs = seconds_int % 60

	return str(hours)+"hr "+str(minutes)+"m "+str(secs)+"s "


func _save1_select_pressed() -> void:
	Globals.save_idx = 0
	Globals.save_state = Globals.config.get_value("saves", str(Globals.save_idx), SaveState.new())
	highlight_state()

func _save2_select_pressed() -> void:
	Globals.save_idx = 1
	Globals.save_state = Globals.config.get_value("saves", str(Globals.save_idx), SaveState.new())
	highlight_state()

func _save3_select_pressed() -> void:
	Globals.save_idx = 2
	Globals.save_state = Globals.config.get_value("saves", str(Globals.save_idx), SaveState.new())
	highlight_state()

func _on_delete1_pressed() -> void:
	$MarginContainer/VBoxContainer/Save1/HBoxContainer/Delete.visible = !$MarginContainer/VBoxContainer/Save1/HBoxContainer/Delete.visible
	$MarginContainer/VBoxContainer/Save2/HBoxContainer/Delete.visible = false
	$MarginContainer/VBoxContainer/Save3/HBoxContainer/Delete.visible = false

func _on_delete2_pressed() -> void:
	$MarginContainer/VBoxContainer/Save2/HBoxContainer/Delete.visible = !$MarginContainer/VBoxContainer/Save2/HBoxContainer/Delete.visible
	$MarginContainer/VBoxContainer/Save1/HBoxContainer/Delete.visible = false
	$MarginContainer/VBoxContainer/Save3/HBoxContainer/Delete.visible = false

func _on_delete3_pressed() -> void:
	$MarginContainer/VBoxContainer/Save3/HBoxContainer/Delete.visible = !$MarginContainer/VBoxContainer/Save3/HBoxContainer/Delete.visible
	$MarginContainer/VBoxContainer/Save1/HBoxContainer/Delete.visible = false
	$MarginContainer/VBoxContainer/Save2/HBoxContainer/Delete.visible = false

func _on_deletec1_pressed() -> void:
	save_config = true
	print("Delete 1")
	Globals.config.set_value("saves", "0", SaveState.new())
	save_state1 = Globals.config.get_value("saves", "0", SaveState.new())
	load_state($MarginContainer/VBoxContainer/Save1,save_state1)
	$MarginContainer/VBoxContainer/Save1/HBoxContainer/Delete.visible = false
	$MarginContainer/VBoxContainer/Save1/HBoxContainer/Options/Delete.grab_focus()
	Globals.save_state = Globals.config.get_value("saves", str(Globals.save_idx), SaveState.new())
	
func _on_deletec2_pressed() -> void:
	save_config = true
	print("Delete 2")
	Globals.config.set_value("saves", "1", SaveState.new())
	save_state2 = Globals.config.get_value("saves", "1", SaveState.new())
	load_state($MarginContainer/VBoxContainer/Save2,save_state2)
	$MarginContainer/VBoxContainer/Save2/HBoxContainer/Delete.visible = false
	$MarginContainer/VBoxContainer/Save2/HBoxContainer/Options/Delete.grab_focus()
	Globals.save_state = Globals.config.get_value("saves", str(Globals.save_idx), SaveState.new())

func _on_deletec3_pressed() -> void:
	save_config = true
	print("Delete 3")
	Globals.config.set_value("saves", "2", SaveState.new())
	save_state3 = Globals.config.get_value("saves", "2", SaveState.new())
	load_state($MarginContainer/VBoxContainer/Save3,save_state3)
	$MarginContainer/VBoxContainer/Save3/HBoxContainer/Delete.visible = false
	$MarginContainer/VBoxContainer/Save3/HBoxContainer/Options/Delete.grab_focus()
	Globals.save_state = Globals.config.get_value("saves", str(Globals.save_idx), SaveState.new())
