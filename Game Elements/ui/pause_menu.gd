extends CanvasLayer


var frame_amount = 0
var mouse_mode = null
var pause_cooldown = 0
var active = false

@onready var slot_nodes: Array = [
	$Control/MarginContainer/slots_hbox/slot0,
	$Control/MarginContainer/slots_hbox/slot1,
	$Control/MarginContainer/slots_hbox/slot2]

func _ready():
	for i in range(slot_nodes.size()):
		slot_nodes[i].index = i
		slot_nodes[i].slot_selected.connect(_on_slot_selected)
		slot_nodes[i].set_enabled(false)
		slot_nodes[i].hide_visuals(true)
	hide()


func setup(nodes : Array[Node]):
	for node in nodes:
		if "remnant" in node:
			node.icon_selected.connect(_on_icon_selected)
	



func activate():
	active = true
	mouse_mode = Input.get_mouse_mode()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show()
	get_tree().paused = true
	get_tree().get_root().get_node("LayerManager/DeathMenu").capturing = false
	if Globals.is_multiplayer or Globals.player1_input != "key":
		$Control/VBoxContainer/Return.grab_focus()
	pause_cooldown = 5

func _process(_delta):
	pause_cooldown= max(0,pause_cooldown-1)
		




func _on_icon_selected(remnant : Remnant, is_purple : bool) -> void:
	var index = (!is_purple as int) *2
	if remnant ==slot_nodes[index].remnant and !slot_nodes[index].btn_select.disabled:
		slot_nodes[index].hide_visuals(true)
		slot_nodes[index].set_enabled(false)
	else:
		slot_nodes[index].hide_visuals(false)
		slot_nodes[index].set_enabled(true)
		slot_nodes[index].set_remnant(remnant,false)
	pass


func _on_slot_selected(idx: int) -> void:
	slot_nodes[idx].hide_visuals(true)
	slot_nodes[idx].set_enabled(false)


func _on_settings_pressed():
	for i in range(slot_nodes.size()):
		slot_nodes[i].set_enabled(false)
		slot_nodes[i].hide_visuals(true)
	var setting = load("res://Game Elements/ui/settings.tscn").instantiate()
	add_child(setting)
	setting.get_child(0).is_pause_settings=true

func _on_return_pressed():
	active = false
	pause_cooldown = 5
	for i in range(slot_nodes.size()):
		slot_nodes[i].set_enabled(false)
		slot_nodes[i].hide_visuals(true)
	Input.set_mouse_mode(mouse_mode)
	get_tree().get_root().get_node("LayerManager/DeathMenu").capturing = true
	get_tree().paused = false
	hide()

func _on_menu_pressed():
	for i in range(slot_nodes.size()):
		slot_nodes[i].set_enabled(false)
		slot_nodes[i].hide_visuals(true)
	get_tree().paused = false
	get_tree().call_deferred("change_scene_to_file", "res://Game Elements/ui/main_menu/main_menu.tscn")
