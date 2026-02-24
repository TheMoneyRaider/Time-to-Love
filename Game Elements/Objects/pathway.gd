extends Node2D

@export var used := false
@export var active := false
@export var is_wave = false
@export var reward1_type = Globals.Reward.Remnant
@export var reward1_texture = null
@export var reward1_frame = 0
@export var reward1_hframes = 1
@export var reward1_vframes = 1
@export var reward1_material = null
@export var reward2_type = Globals.Reward.Remnant
@export var reward2_texture = null
@export var reward2_frame = 0
@export var reward2_hframes = 1
@export var reward2_vframes = 1
@export var reward2_material = null

@export var interact_key := "activate"
@onready var prompt1 := $Prompt1
@onready var prompt2 := $Prompt2
@onready var player_area := $Area2D
var tracked_bodies1: Array = []
var tracked_bodies2: Array = []

######Timefabric animation
@export var spritesheet : Texture2D = load("res://art/time_fabric.png")            #The sprite sheet
@export var frame_width : int = 16             #adjust to match your sheet
@export var frame_height : int = 16            #adjust to match your sheet
@export var frame_count : int = 6              #number of frames in sheet
@export var fps := 1                           #animation speed
@export var smear_strength := 0.6              #0=sharp, 1=ghost-smear

var frames : Array[Texture2D] = []
var current_frame := 0
var next_frame := 1
var anim_time := 0.0
######
var tricky : int = -1

func _ready():
	prompt1.visible = false
	prompt2.visible = false
	player_area.connect("body_entered", Callable(self, "_on_body_entered"))
	player_area.connect("body_exited", Callable(self, "_on_body_exited"))
	_slice_frames()
	
	if !Globals.is_multiplayer:
		get_tree().get_root().get_node("LayerManager").player1.swapped_color.connect(_swapped_color)


func _process(delta):
	$ShaderSprite.material.set_shader_parameter("mask_texture", $MaskViewport.get_texture())
	if frames.is_empty():
		return

	var prev_frame_index := int(anim_time)
	anim_time += delta * fps
	var new_frame_index := int(anim_time)

	if new_frame_index != prev_frame_index:
		current_frame = next_frame
		next_frame = (next_frame + 1) % frame_count

	var t := anim_time - int(anim_time)
	var smear_t := pow(t, smear_strength)
	$Prompt2/TextureRect.texture = _blend_textures(frames[current_frame], frames[next_frame], smear_t)

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

func disable_pathway(fully : bool):
	if fully:
		visible = false
	$ShaderSprite.visible = false
	active = false
func enable_pathway():
	visible = true
	$Icons/PathwayIcon1.z_index=0
	$Icons/PathwayIcon2.z_index=0
	$ShaderSprite.visible = true
	active = true
	$Icons/PathwayIcon1.texture = reward1_texture
	$Icons/PathwayIcon1.hframes = reward1_hframes
	$Icons/PathwayIcon1.vframes = reward1_vframes
	$Icons/PathwayIcon1.frame = reward1_frame
	$Icons/PathwayIcon1.material = reward1_material
	$Icons/PathwayIcon2.texture = reward2_texture
	$Icons/PathwayIcon2.hframes = reward2_hframes
	$Icons/PathwayIcon2.vframes = reward2_vframes
	$Icons/PathwayIcon2.frame = reward2_frame
	$Icons/PathwayIcon2.material = reward2_material
	if is_wave:
		$Icons/PathwayIcon1.material = reward1_material.duplicate()
		$Icons/PathwayIcon2.material = reward2_material.duplicate()
		$Icons/PathwayIcon1.material.set_shader_parameter("split", true)
		$Icons/PathwayIcon2.material.set_shader_parameter("split", true)
		$Icons/PathwayIcon1.material.set_shader_parameter("upper_left", true)
		$Icons/PathwayIcon2.material.set_shader_parameter("upper_left", false)

func set_reward(reward1 : Globals.Reward, in_is_wave : bool = false, reward2 : Globals.Reward = Globals.Reward.Remnant, _weapon_type : String = ""):
	var new_icon1 = null
	var new_icon2 = null
	is_wave = in_is_wave
	match reward1:
		Globals.Reward.Remnant:
			var inst = load("res://Game Elements/Objects/remnant_orb.tscn").instantiate()
			new_icon1 = inst.get_node("Image")
		Globals.Reward.TimeFabric:
			var inst =load("res://Game Elements/Objects/timefabric_orb.tscn").instantiate()
			new_icon1 = inst.get_node("Image")
		Globals.Reward.RemnantUpgrade:
			var inst =load("res://Game Elements/Objects/upgrade_orb.tscn").instantiate()
			new_icon1 = inst.get_node("Image")
		Globals.Reward.HealthUpgrade:
			var inst =load("res://Game Elements/Objects/health_upgrade.tscn").instantiate()
			new_icon1 = inst.get_node("Image")
		Globals.Reward.Health:
			var inst =load("res://Game Elements/Objects/health.tscn").instantiate()
			new_icon1 = inst.get_node("Image")
		Globals.Reward.Shop:
			var inst = load("res://Game Elements/Objects/vision.tscn").instantiate()
			new_icon1 = inst.get_node("Image")
		Globals.Reward.Boss:
			new_icon1 = load("res://Game Elements/Bosses/boss_symbol.png")
	if !is_wave:
		new_icon2 = new_icon1
	else:
		match reward2:
			Globals.Reward.Remnant:
				var inst = load("res://Game Elements/Objects/remnant_orb.tscn").instantiate()
				new_icon2 = inst.get_node("Image")
			Globals.Reward.TimeFabric:
				var inst =load("res://Game Elements/Objects/timefabric_orb.tscn").instantiate()
				new_icon2 = inst.get_node("Image")
			Globals.Reward.RemnantUpgrade:
				var inst =load("res://Game Elements/Objects/upgrade_orb.tscn").instantiate()
				new_icon2 = inst.get_node("Image")
			Globals.Reward.HealthUpgrade:
				var inst =load("res://Game Elements/Objects/health_upgrade.tscn").instantiate()
				new_icon2 = inst.get_node("Image")
			Globals.Reward.Health:
				var inst =load("res://Game Elements/Objects/health.tscn").instantiate()
				new_icon2 = inst.get_node("Image")
	if reward1 == Globals.Reward.Boss:
		reward2 = reward1
		reward1_type = reward1
		reward2_type = reward1
		reward1_texture = new_icon1
		reward2_texture = new_icon1
		if active:
			enable_pathway()
		
	else:
		reward1_type = reward1
		reward1_texture = new_icon1.texture
		reward1_frame = new_icon1.frame
		reward1_hframes = new_icon1.hframes
		reward1_vframes = new_icon1.vframes
		reward1_material = new_icon1.material
		reward2_type = reward2
		reward2_texture = new_icon2.texture
		reward2_frame = new_icon2.frame
		reward2_hframes = new_icon2.hframes
		reward2_vframes = new_icon2.vframes
		reward2_material = new_icon2.material
		if active:
			enable_pathway()

func _on_body_entered(body):
	if !active:
		return
	if body.is_in_group("player"):
		tracked_bodies1.append(body)
		prompt1.visible = true
		tricky = _has_trickster(body,false)
		if tricky != -1:
			tracked_bodies2.append(body)
			prompt2.visible = true
			_set_display(tracked_bodies2[0])
		if len(tracked_bodies1) == 1:
			_set_display(tracked_bodies1[0])
func _on_body_exited(body):
	if !active:
		return
	if body in tracked_bodies1:
		tracked_bodies1.erase(body)
	if body in tracked_bodies2:
		tracked_bodies2.erase(body)
	if len(tracked_bodies1) == 0:
		prompt1.visible = false
	else:
		tricky = _has_trickster(tracked_bodies1[0],false)
		_set_display(tracked_bodies1[0])
	if len(tracked_bodies2) == 0:
		prompt2.visible = false
	else:
		tricky = _has_trickster(tracked_bodies2[0],false)
		_set_display(tracked_bodies2[0])
		
		
func _has_trickster(body : Node, is_switched : bool = false) -> int:
	if reward1_type == Globals.Reward.Shop:
		return -1
	var remnants : Array[Remnant] = []
	var player_col = body.is_purple
	if is_switched:
		player_col = !player_col
	if player_col:
		remnants = get_tree().get_root().get_node("LayerManager").player_1_remnants
	else:
		remnants = get_tree().get_root().get_node("LayerManager").player_2_remnants
	var trickster = load("res://Game Elements/Remnants/trickster.tres")
	for rem in remnants:
		if rem.remnant_name == trickster.remnant_name:
			return int(rem.variable_1_values[rem.rank-1])
	return -1

func _swapped_color(player : Node):
	if len(tracked_bodies2) == 0 and len(tracked_bodies1) == 0:
		return
	for body in tracked_bodies2:
		tricky = _has_trickster(body,true)
		if body == player and tricky ==-1:
			tracked_bodies2.erase(body)
			tracked_bodies1.append(body)
			prompt2.visible = false
			return
	for body in tracked_bodies1:
		tricky = _has_trickster(body,true)
		if body == player and tricky !=-1:
			tracked_bodies1.erase(body)
			tracked_bodies2.append(body)
			prompt2.visible = true
			_set_display(tracked_bodies2[0])
			return
			
func _set_display(body : Node):
	if body.input_device == "key":
			prompt2.get_child(0).bbcode_text = "[font=res://addons/input_prompt_icon_font/icon.ttf]keyboard_f_outline[/font]: Reroll for "+str(tricky)+"  "
			prompt1.get_child(0).bbcode_text = "[font=res://addons/input_prompt_icon_font/icon.ttf]keyboard_e_outline[/font]: Enter"
	else:
		prompt2.get_child(0).bbcode_text = "[font=res://addons/input_prompt_icon_font/icon.ttf]playstation_button_triangle_outline[/font]: Reroll for "+str(tricky)+"  "
		prompt1.get_child(0).bbcode_text = "[font=res://addons/input_prompt_icon_font/icon.ttf]playstation_button_cross_outline[/font]: Enter"
