extends Control
class_name RemnantOffer

signal remnant_chosen(remnant1: Resource,remnant2: Resource)

@onready var crosshair_sprite = $Crosshair/Sprite2D
@onready var purple_crosshair = preload("res://art/purple_crosshair_with_shadow.png")
@onready var orange_crosshair = preload("res://art/orange_crosshair_with_shadow.png")
@onready var slot_nodes: Array = [
	$MarginContainer/slots_hbox/slot0,
	$MarginContainer/slots_hbox/slot1,
	$MarginContainer/slots_hbox/slot2,
	$MarginContainer/slots_hbox/slot3]
var offered_remnants: Array[Resource] = []
var selected_index1: int = -1 #Purple
var selected_index2: int = -1 #Orange
var player1_remnants = []
var player2_remnants = []
var current_weights = []
var hover_index1 : int = 0 #purple
var hover_index2 : int = -1 #orange
var is_purple : bool = true

######Timefabric animation
@export var spritesheet : Texture2D = load("res://art/time_fabric.png")            #The sprite sheet
@export var frame_width : int = 16             #adjust to match your sheet
@export var frame_height : int = 16            #adjust to match your sheet
@export var frame_count : int = 6              #number of frames in sheet
@export var fps := 1                           #animation speed
@export var smear_strength := 0.6              #0=sharp, 1=ghost-smear
var tricky1 : int = 0 
var tricky2 : int = 0
var frames : Array[Texture2D] = []
var current_frame := 0
var next_frame := 1
var anim_time := 0.0
###

func _set_drifter_text(player1_remnants_in, player2_remnants_in):
	var drifter = preload("res://Game Elements/Remnants/trickster.tres")
	for rem in player1_remnants_in:
		if rem.active:
			match rem.remnant_name:
				drifter.remnant_name:
					tricky1 = (rem.variable_1_values[rem.rank -1])
					$DrifterText.visible = true
	for rem in player2_remnants_in:
		if rem.active:
			match rem.remnant_name:
				drifter.remnant_name:
					tricky2 = (rem.variable_1_values[rem.rank -1])
					$DrifterText.visible = true
	if(Globals.is_multiplayer):
		if(tricky1 != 0 && tricky2 != 0):
			if(tricky1 < tricky2):
				var glyph_key = "special"+Globals.player1_input
				$DrifterText/Label.text = GlyphManager.get_glyph(GlyphManager.get_device_type(Globals.player1_input),glyph_key)+": Reroll for "+str(tricky1)+"  "
			else:
				var glyph_key = "special"+Globals.player2_input
				$DrifterText/Label.text = GlyphManager.get_glyph(GlyphManager.get_device_type(Globals.player2_input),glyph_key)+": Reroll for "+str(tricky2)+"  "
		elif (tricky1 != 0):
			var glyph_key = "special"+Globals.player1_input
			$DrifterText/Label.text = GlyphManager.get_glyph(GlyphManager.get_device_type(Globals.player1_input),glyph_key)+": Reroll for "+str(tricky1)+"  "
		elif(tricky2 != 0):
			var glyph_key = "special"+Globals.player2_input
			$DrifterText/Label.text = GlyphManager.get_glyph(GlyphManager.get_device_type(Globals.player2_input),glyph_key)+": Reroll for "+str(tricky2)+"  "
	else:
		if(is_purple && tricky1 != 0):
			var glyph_key = "special"+Globals.player1_input
			$DrifterText/Label.text = GlyphManager.get_glyph(GlyphManager.get_device_type(Globals.player1_input),glyph_key)+": Reroll for "+str(tricky1)+"  "
		elif(!is_purple && tricky2 != 0):
			var glyph_key = "special"+Globals.player1_input
			$DrifterText/Label.text = GlyphManager.get_glyph(GlyphManager.get_device_type(Globals.player1_input),glyph_key)+": Reroll for "+str(tricky2)+"  "
	if Globals.total_progress < 1.0 and !RemnantManager.has_gotten_remnant:
		$DrifterText/Label.text = "Chose a Remnant for each Character"
		$DrifterText.visible = true
		$DrifterText/Label/TextureRect.visible = false
func _slice_frames() -> void:
	frames.clear()

	var img := spritesheet.get_image()

	for i in range(frame_count):
		var x := i * frame_width
		var frame_image := Image.create(frame_width, frame_height, false, Image.FORMAT_RGBA8)
		frame_image.blit_rect(img, Rect2i(x, 0, frame_width, frame_height), Vector2i(0, 0))
		var tex := ImageTexture.create_from_image(frame_image)
		frames.append(tex)

func _blend_textures(a: Texture2D, b: Texture2D, t: float) -> Texture2D:
	var img_a := a.get_image()
	var img_b := b.get_image()

	var out := Image.create(img_a.get_width(), img_a.get_height(), false, Image.FORMAT_RGBA8)

	for y in img_a.get_height():
		for x in img_a.get_width():
			var ca = img_a.get_pixel(x, y)
			var cb = img_b.get_pixel(x, y)
			out.set_pixel(x, y, ca.lerp(cb, t))

	return ImageTexture.create_from_image(out)

func _ready():
	for i in range(slot_nodes.size()):
		slot_nodes[i].index = i
		slot_nodes[i].slot_selected.connect(_on_slot_selected)
	_slice_frames()
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().paused = true
	modulate.a = 0.0

func _process(_delta):
	if !Globals.is_multiplayer and Input.is_action_just_pressed("swap_" + Globals.player1_input):
		is_purple=!is_purple
		_set_drifter_text(player1_remnants, player2_remnants)
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
		slot_nodes[hover_index2].outline_remnant( Color.ORANGE, .5)
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
	if frames.is_empty():
		return

	var prev_frame_index := int(anim_time)
	anim_time += _delta * fps
	var new_frame_index := int(anim_time)

	if new_frame_index != prev_frame_index:
		current_frame = next_frame
		next_frame = (next_frame + 1) % frame_count

	var t := anim_time - int(anim_time)
	var smear_t := pow(t, smear_strength)
	$DrifterText/Label/TextureRect.texture = _blend_textures(frames[current_frame], frames[next_frame], smear_t)


func popup_offer(player1_remnants_in : Array, player2_remnants_in : Array, rank_weights : Array = [70,25,5]):
	_set_drifter_text(player1_remnants_in,player2_remnants_in)
	player1_remnants = player1_remnants_in.duplicate()
	player2_remnants = player2_remnants_in.duplicate()
	current_weights = rank_weights
	is_purple = true
	crosshair_sprite.texture = purple_crosshair
	#query the pool for 4 random remnants(2 from each player)
	offered_remnants = RemnantManager.get_random_remnants(4,player1_remnants, player2_remnants)
	selected_index1 = -1
	selected_index2 = -1
	match int(RoomManager.current_progress):
		0:
			rank_weights = [70,25,5]
		1:
			rank_weights = [20, 50, 25, 5]
		2:
			rank_weights = [5, 30, 40, 20, 5]
		3:
			rank_weights = [0, 30, 35, 25, 10]
		_:
			rank_weights = [0, 30, 35, 25, 10]
	#populate UI
	for i in range(slot_nodes.size()):
		if i < offered_remnants.size():
			var temp_rank = weighted_random_index(rank_weights)
			offered_remnants[i].rank = max(offered_remnants[i].num_rem_required, temp_rank)
			
			slot_nodes[i].set_remnant(offered_remnants[i],false)
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
		if i < offered_remnants.size():
			_place_purple_selectable(slot_nodes[i],offered_remnants[i])
			_place_orange_selectable(slot_nodes[i],offered_remnants[i])
	visible = true
	
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
	


func meets_requirements(remnant : Remnant,names : Array[String]):
	var num_preqreqs_met = 0
	for rm in remnant.required_remnants:
		if rm.remnant_name in names:
			num_preqreqs_met += 1
	if(num_preqreqs_met < remnant.num_rem_required):
		return false
	return true


func _place_purple_selectable(slot : Node ,remnant : Resource):
	var rem_names : Array[String] = []
	for r in player1_remnants:
		rem_names.append(r.remnant_name)
	if remnant.remnant_name not in rem_names and meets_requirements(remnant,rem_names):
		var particle = preload("res://Game Elements/ui/purple_selectable.tscn").instantiate()
		particle.position = slot.position+slot.size+$MarginContainer/slots_hbox.position
		particle.position.x -= slot.size.x/2
		add_child(particle)

func _place_orange_selectable(slot : Node ,remnant : Resource):
	var rem_names : Array[String]= []
	for r in player2_remnants:
		rem_names.append(r.remnant_name)
	if remnant.remnant_name not in rem_names and meets_requirements(remnant,rem_names):
		var particle = preload("res://Game Elements/ui/orange_selectable.tscn").instantiate()
		particle.position = slot.position+slot.size+$MarginContainer/slots_hbox.position
		particle.position.x -= slot.size.x/2
		particle.position.y -= slot.size.y
		add_child(particle)

func weighted_random_index(weights: Array) -> int:
	var total = 100
	var r = randf() * total
	var cumulative = 0.0

	for i in range(weights.size()):
		cumulative += weights[i]
		if r < cumulative:
			return i+1

	return weights.size()

func _check_if_remnant_viable(remnant : Resource, remnant_array : Array):
	var names = []
	for r in remnant_array:
		names.append(r.remnant_name)
	var num_preqreqs_met = 0
	for rm in remnant.required_remnants:
		if rm.remnant_name in names:
			num_preqreqs_met += 1
	if(num_preqreqs_met < remnant.num_rem_required):
		return false
	if remnant.remnant_name not in names:
		return true
	return false
	
func inputs(input_device : String, is_player_1 : bool):
	if not visible:
		return
	if !is_purple:
		is_player_1=!is_player_1
	if current_weights != [] and (tricky1 + tricky2) != 0 and Input.is_action_just_pressed("special_" + input_device):
		var cost = max(tricky1,tricky2)
		if(tricky1 != 0 and tricky1 !=0):
			cost = min(tricky1,tricky2)
		if(is_player_1 && tricky1 != 0):
			if($"../../".timefabric_collected >= int(cost)):
				$"../../".timefabric_collected-=int(cost)
				popup_offer(player1_remnants,player2_remnants,current_weights)
		elif(!is_player_1 && tricky2 != 0):
			if($"../../".timefabric_collected >= int(cost)):
				$"../../".timefabric_collected-=int(cost)
				popup_offer(player1_remnants,player2_remnants,current_weights)
			
	if(input_device == "key"):
		return
	if Input.is_action_just_pressed("menu_right_"+input_device):
		if is_player_1:
			hover_index1 = min(offered_remnants.size() - 1, hover_index1 + 1)
			SFXManager.play(preload("res://Game Elements/sfx/world/remnant_hover.ogg"), 0.0, "UI")
		else:
			hover_index2 = min(offered_remnants.size() - 1, hover_index2 + 1)
			SFXManager.play(preload("res://Game Elements/sfx/world/remnant_hover.ogg"), 0.0, "UI")
	if Input.is_action_just_pressed("menu_left_"+input_device):
		if is_player_1:
			hover_index1 = max(0, hover_index1 - 1)
			SFXManager.play(preload("res://Game Elements/sfx/world/remnant_hover.ogg"), 0.0, "UI")
		else:
			hover_index2 = max(0, hover_index2 - 1)
			SFXManager.play(preload("res://Game Elements/sfx/world/remnant_hover.ogg"), 0.0, "UI")
	if Input.is_action_just_pressed("activate_"+input_device):
		if is_player_1:
			if _check_if_remnant_viable(offered_remnants[hover_index1], player1_remnants) and hover_index1 != selected_index2:
				selected_index1 = hover_index1
		else:
			if _check_if_remnant_viable(offered_remnants[hover_index2], player2_remnants) and hover_index2 != selected_index1:
				selected_index2 = hover_index2

func _on_slot_selected(idx: int) -> void:
	SFXManager.play(preload("res://Game Elements/sfx/world/remnant_hover.ogg"), 0.0, "UI")
	if Globals.is_multiplayer:
		if Globals.player1_input == "key" and _check_if_remnant_viable(offered_remnants[idx], player1_remnants) and idx != selected_index2:
			selected_index1 = idx
		elif Globals.player2_input == "key" and _check_if_remnant_viable(offered_remnants[idx], player2_remnants) and idx != selected_index1:
			selected_index2 = idx
	else:
		if is_purple:
			if  _check_if_remnant_viable(offered_remnants[idx], player1_remnants):
				if idx == selected_index2:
					selected_index2=-1
				selected_index1 = idx
		else:
			if _check_if_remnant_viable(offered_remnants[idx], player2_remnants):
				if idx == selected_index1:
					selected_index1=-1
				selected_index2 = idx
		if selected_index1 != selected_index2 and selected_index1 != -1 and selected_index2 != -1: #If we now have two different selections -> close the menu
			_close_after_two_chosen()

func _close_after_two_chosen():
	RemnantManager.has_gotten_remnant = true
	#Fade out animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, .5)
	await tween.finished
	#Emit the two chosen remnants
	emit_signal("remnant_chosen", offered_remnants[selected_index1], offered_remnants[selected_index2])
	visible = false
	$DrifterText.visible = false
	get_tree().paused = false
