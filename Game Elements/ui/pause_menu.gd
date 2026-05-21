extends CanvasLayer


var frame_amount = 0
var mouse_mode = null
var pause_cooldown = 0
var active = false
var can_escape = false

@onready var slot_nodes: Array = [
	$Control/MarginContainer/slots_hbox/slot0,
	$Control/MarginContainer/slots_hbox/slot1,
	$Control/MarginContainer/slots_hbox/slot2]

func _ready():
	LayerManager = get_tree().get_root().get_node("LayerManager")
	for i in range(slot_nodes.size()):
		slot_nodes[i].index = i
		slot_nodes[i].slot_selected.connect(_on_slot_selected)
		slot_nodes[i].set_enabled(false)
		slot_nodes[i].hide_visuals(true)
	hide()
	
	for button in $Control/VBoxContainer.get_children():
		button.mouse_entered.connect(func(): SFXManager.play(preload("res://Game Elements/sfx/world/remnant_hover.ogg"), 0.0, "UI"))
		button.focus_entered.connect(func(): SFXManager.play(preload("res://Game Elements/sfx/world/remnant_hover.ogg"), 0.0, "UI"))
	for button in $Control/Extras.get_children():
		button.mouse_entered.connect(func(): SFXManager.play(preload("res://Game Elements/sfx/world/remnant_hover.ogg"), 0.0, "UI"))
		button.focus_entered.connect(func(): SFXManager.play(preload("res://Game Elements/sfx/world/remnant_hover.ogg"), 0.0, "UI"))

func setup(nodes : Array[Node]):
	for node in nodes:
		if "remnant" in node:
			node.icon_selected.connect(_on_icon_selected)
	

var LayerManager : Node

func activate():
	active = true
	mouse_mode = Input.MOUSE_MODE_HIDDEN
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show()
	get_tree().paused = true
	get_tree().get_root().get_node("LayerManager/DeathMenu").capturing = false
	get_tree().get_root().get_node("LayerManager/DeathMenu").getting_time = false
	if Globals.is_multiplayer or Globals.player1_input != "key":
		$Control/VBoxContainer/Return.grab_focus()
	pause_cooldown = 5
	can_escape = true
	for node in get_tree().get_nodes_in_group("attack"):
		node.pause_shaders()
	LayerManager.player1.reset_special()
	if LayerManager.is_multiplayer:
		LayerManager.player2.reset_special()
		

func _process(delta):
	if can_escape and pause_cooldown < 1 and Input.is_action_just_pressed("ui_cancel"):
		_on_return_pressed()
	for child in $Control/Extras.get_children():
		if child.is_hovered() or child.has_focus():
			child.position.x = clamp(child.position.x-delta*150,168,198)
		else:
			child.position.x = clamp(child.position.x+delta*150,168,198)
	pause_cooldown= max(0,pause_cooldown-1)
		




func _on_icon_selected(remnant : Remnant, is_purple : bool) -> void:
	SFXManager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"), 0.0, "UI")
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
	SFXManager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"), 0.0, "UI")
	slot_nodes[idx].hide_visuals(true)
	slot_nodes[idx].set_enabled(false)


func _on_settings_pressed():
	SFXManager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"), 0.0, "UI")
	for i in range(slot_nodes.size()):
		slot_nodes[i].set_enabled(false)
		slot_nodes[i].hide_visuals(true)
	var setting = preload("res://Game Elements/ui/settings.tscn").instantiate()
	add_child(setting)
	setting.get_child(0).is_pause_settings=true

func _on_return_pressed():
	SFXManager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"), 0.0, "UI")
	active = false
	pause_cooldown = 5
	for i in range(slot_nodes.size()):
		slot_nodes[i].set_enabled(false)
		slot_nodes[i].hide_visuals(true)
	Input.set_mouse_mode(mouse_mode)
	get_tree().get_root().get_node("LayerManager/DeathMenu").capturing = true
	get_tree().get_root().get_node("LayerManager/DeathMenu").getting_time = true
	get_tree().paused = false
	hide()
	for node in get_tree().get_nodes_in_group("attack"):
		node.resume_shaders()

func _on_menu_pressed():
	RoomManager.reset()
	SFXManager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"), 0.0, "UI")
	get_tree().get_root().get_node("LayerManager/DeathMenu").state_change()
	for i in range(slot_nodes.size()):
		slot_nodes[i].set_enabled(false)
		slot_nodes[i].hide_visuals(true)
	get_tree().paused = false
	Globals.save_config()
	get_tree().call_deferred("change_scene_to_file", "res://Game Elements/ui/main_menu/main_menu.tscn")


	



func _on_letters_pressed() -> void:
	SFXManager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
	active = false
	pause_cooldown = 2000000000
	for i in range(slot_nodes.size()):
		slot_nodes[i].set_enabled(false)
		slot_nodes[i].hide_visuals(true)
	hide()
	get_parent().get_node("LetterMenu").activate()


func _on_weapons_pressed() -> void:
	SFXManager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
	active = false
	pause_cooldown = 2000000000
	for i in range(slot_nodes.size()):
		slot_nodes[i].set_enabled(false)
		slot_nodes[i].hide_visuals(true)
	hide()
	get_parent().get_node("WeaponMenu").activate()


func _on_remnants_pressed() -> void:
	SFXManager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
	active = false
	pause_cooldown = 2000000000
	for i in range(slot_nodes.size()):
		slot_nodes[i].set_enabled(false)
		slot_nodes[i].hide_visuals(true)
	hide()
	get_parent().get_node("RemnantMenu").activate()
