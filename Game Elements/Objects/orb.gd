extends Area2D

@export var interact_key := "activate"
@onready var prompt1 := $Prompt1
var tracked_bodies: Array = []
var cost : int = 0
var enabled : bool = true

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

func set_cost(in_cost : int):
	cost = in_cost
	if cost!= 0:
		$Prompt1/TextureRect.visible = true
	else:
		$Prompt1/TextureRect.visible = false

func _ready():
	prompt1.visible = false
	self.connect("body_entered", Callable(self, "_on_body_entered"))
	self.connect("body_exited", Callable(self, "_on_body_exited"))
	_slice_frames()
	if cost!= 0:
		$Prompt1/TextureRect.visible = true
	else:
		$Prompt1/TextureRect.visible = false

func _process(delta: float) -> void:
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
	$Prompt1/TextureRect.texture = _blend_textures(frames[current_frame], frames[next_frame], smear_t)


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



func _on_body_entered(body):
	if body.is_in_group("player"):
		tracked_bodies.append(body)
		if enabled:
			prompt1.visible = true
		if len(tracked_bodies) == 1:
			_set_display(tracked_bodies[0])
func _on_body_exited(body):
	if body in tracked_bodies:
		tracked_bodies.erase(body)
	if len(tracked_bodies) == 0:
		if enabled:
			prompt1.visible = false
	else:
		_set_display(tracked_bodies[0])
		
		
func _set_display(body : Node):
	if cost != 0:
		if body.input_device == "key":
			prompt1.get_child(0).bbcode_text = ""+str(cost)+" to buy   [font=res://addons/input_prompt_icon_font/icon.ttf]keyboard_e_outline[/font]"
		else:
			prompt1.get_child(0).bbcode_text = ""+str(cost)+" to buy   [font=res://addons/input_prompt_icon_font/icon.ttf]playstation_button_cross_outline[/font]"
		return
		
	if body.input_device == "key":
			prompt1.get_child(0).bbcode_text = "[font=res://addons/input_prompt_icon_font/icon.ttf]keyboard_e_outline[/font]"
	else:
		prompt1.get_child(0).bbcode_text = "[font=res://addons/input_prompt_icon_font/icon.ttf]playstation_button_cross_outline[/font]"
