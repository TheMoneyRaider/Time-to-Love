extends Control
class_name RemnantUpgrade

signal remnant_upgraded(remnant1: Resource,remnant2: Resource)

@onready var crosshair_sprite = $Crosshair/Sprite2D
@onready var purple_crosshair = preload("res://art/purple_crosshair.png")
@onready var orange_crosshair = preload("res://art/orange_crosshair.png")
@onready var slot_nodes: Array = [
	$MarginContainer/slots_hbox/slot0,
	$MarginContainer/slots_hbox/slot1,
	$MarginContainer/slots_hbox/slot2,
	$MarginContainer/slots_hbox/slot3]
var upgrade_remnants: Array[Resource] = []
var selected_index1: int = -1 #Purple
var selected_index2: int = -1 #Orange
var player1_remnants = []
var player2_remnants = []
var hover_index1 : int = 0 #purple
var hover_index2 : int = -1 #orange
var is_purple : bool = true

func _ready():
	for i in range(slot_nodes.size()):
		slot_nodes[i].index = i
		slot_nodes[i].slot_selected.connect(_on_slot_selected)
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().paused = true
	modulate.a = 0.0

func _process(_delta):
	if !Globals.is_multiplayer and Input.is_action_just_pressed("swap_" + Globals.player1_input):
		is_purple=!is_purple
		if Globals.player1_input== "key":
			crosshair_sprite.texture=purple_crosshair if is_purple else orange_crosshair
		else:
			if is_purple:
				hover_index1 = hover_index2
				hover_index2 = -1
			else:
				hover_index2 = hover_index1
				hover_index1 = -1
	for i in range(slot_nodes.size()):
		slot_nodes[i].outline_remnant(Color.GREEN, 0.0)
	if hover_index2!=-1:
		slot_nodes[hover_index2].outline_remnant(Color.ORANGE, .5)
	if hover_index1!=-1:
		slot_nodes[hover_index1].outline_remnant(Color.PURPLE, .5)
	if selected_index1 != -1:
		slot_nodes[selected_index1].outline_remnant(Color.PURPLE, 1)
	if selected_index2 != -1:
		slot_nodes[selected_index2].outline_remnant(Color.ORANGE, 1)
	if selected_index1 != selected_index2 and selected_index1 != -1 and selected_index2 != -1:
		#If we now have two different selections -> close the menu
		_close_after_two_chosen()
	if modulate.a == 1.0:
		inputs(Globals.player1_input,true)
		if Globals.is_multiplayer:
			inputs(Globals.player2_input,false)

func popup_upgrade(player1_remnants_in : Array, player2_remnants_in : Array):
	player1_remnants = player1_remnants_in
	player2_remnants = player2_remnants_in
	crosshair_sprite.texture = purple_crosshair
	#query the pool for 4 random remnants(2 from each player)
	upgrade_remnants = RemnantManager.get_remnant_upgrades(4,player1_remnants, player2_remnants)
	selected_index1 = -1
	selected_index2 = -1
	#populate UI
	for i in range(slot_nodes.size()):
		if i < upgrade_remnants.size():
			slot_nodes[i].set_remnant(upgrade_remnants[i],true)
		else:
			slot_nodes[i].queue_free()
	# Wait a frame for layout to update
	await get_tree().process_frame
	var tmp_slots = []
	for slot in slot_nodes:
		if slot and !slot.is_queued_for_deletion():
			tmp_slots.append(slot)
	slot_nodes=tmp_slots
	for i in range(slot_nodes.size()):
		if i < upgrade_remnants.size():
			_place_purple_selectable(slot_nodes[i],upgrade_remnants[i])
			_place_orange_selectable(slot_nodes[i],upgrade_remnants[i])

	visible = true
	print(slot_nodes)
	print(slot_nodes.size()-1)
	hover_index2 = slot_nodes.size()-1
	if Globals.is_multiplayer:
		if Globals.player1_input =="key":
			crosshair_sprite.texture = purple_crosshair
			hover_index1=-1
		elif Globals.player2_input =="key":
			crosshair_sprite.texture = orange_crosshair
			hover_index2=-1
		else:
			crosshair_sprite.visible=false
	else:
		if Globals.player1_input =="key":
			hover_index1=-1
		hover_index2=-1
		crosshair_sprite.texture = purple_crosshair
	
	#Fade in
	var _tween = create_tween().tween_property(self, "modulate:a", 1.0, 0.5)
	
	

func _place_purple_selectable(slot : Node ,remnant : Resource):
	if remnant in player1_remnants:
		var particle = load("res://Game Elements/ui/purple_selectable.tscn").instantiate()
		particle.position = slot.position+slot.size+$MarginContainer/slots_hbox.position
		particle.position.x -= slot.size.x/2
		add_child(particle)

func _place_orange_selectable(slot : Node ,remnant : Resource):
	if remnant in player2_remnants:
		var particle = load("res://Game Elements/ui/orange_selectable.tscn").instantiate()
		particle.position = slot.position+slot.size+$MarginContainer/slots_hbox.position
		particle.position.x -= slot.size.x/2
		particle.position.y -= slot.size.y
		add_child(particle)

func weighted_random_index(weights: Array) -> int:
	var total = 0
	for w in weights:
		total += w
	var r = randf() * total
	var cumulative = 0.0

	for i in range(weights.size()):
		cumulative += weights[i]
		if r < cumulative:
			return i+1

	return weights.size()

func _check_if_remnant_viable(remnant : Resource, remnant_array : Array):
	if remnant in remnant_array:
		return true
	return false

func inputs(input_device : String, is_player_1 : bool):
	if input_device=="key" or not visible:
		return
	if !is_purple:
		is_player_1=!is_player_1
	if Input.is_action_just_pressed("menu_right_"+input_device):
		if is_player_1:
			hover_index1 = min(upgrade_remnants.size() - 1, hover_index1 + 1)
		else:
			hover_index2 = min(upgrade_remnants.size() - 1, hover_index2 + 1)
	if Input.is_action_just_pressed("menu_left_"+input_device):
		if is_player_1:
			hover_index1 = max(0, hover_index1 - 1)
		else:
			hover_index2 = max(0, hover_index2 - 1)
	if Input.is_action_just_pressed("activate_"+input_device):
		if is_player_1:
			if _check_if_remnant_viable(upgrade_remnants[hover_index1], player1_remnants) and hover_index1 != selected_index2:
				selected_index1 = hover_index1
		else:
			if _check_if_remnant_viable(upgrade_remnants[hover_index2], player2_remnants) and hover_index2 != selected_index1:
				selected_index2 = hover_index2

func _on_slot_selected(idx: int) -> void:
	if Globals.is_multiplayer:
		if Globals.player1_input == "key" and _check_if_remnant_viable(upgrade_remnants[idx], player1_remnants) and idx != selected_index2:
			selected_index1 = idx
		elif Globals.player2_input == "key" and _check_if_remnant_viable(upgrade_remnants[idx], player2_remnants) and idx != selected_index1:
			selected_index2 = idx
	else:
		if is_purple:
			if  _check_if_remnant_viable(upgrade_remnants[idx], player1_remnants):
				if idx == selected_index2:
					selected_index2=-1
				selected_index1 = idx
		else:
			if _check_if_remnant_viable(upgrade_remnants[idx], player2_remnants):
				if idx == selected_index1:
					selected_index1=-1
				selected_index2 = idx
		if selected_index1 != selected_index2 and selected_index1 != -1 and selected_index2 != -1: #If we now have two different selections -> close the menu
			_close_after_two_chosen()

func _close_after_two_chosen():
	#Fade out animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, .5)
	await tween.finished
	#Emit the two chosen remnants
	emit_signal("remnant_upgraded", upgrade_remnants[selected_index1], upgrade_remnants[selected_index2])
	visible = false
	get_tree().paused = false
