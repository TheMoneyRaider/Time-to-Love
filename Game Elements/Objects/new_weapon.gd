extends Area2D

@export var interact_key := "activate"
@onready var prompt1 := $Prompt1
var weapon_type = ""
var tracked_bodies: Array = []
var cost : int = 0
var enabled : bool = true

func set_cost(in_cost : int):
	cost = in_cost
	if cost!= 0:
		$Prompt1/TextureRect.visible = true
	else:
		$Prompt1/TextureRect.visible = false

func _ready():
	prompt1.visible = false
	var weapon_resource = load("res://Game Elements/Weapons/" + weapon_type + ".tres")
	$Image.texture = weapon_resource.weapon_sprite
	self.connect("body_entered", Callable(self, "_on_body_entered"))
	self.connect("body_exited", Callable(self, "_on_body_exited"))
	if cost!= 0:
		$Prompt1/TextureRect.visible = true
	else:
		$Prompt1/TextureRect.visible = false


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
