extends Node2D

@export var active := true

@export var interact_key := "activate"
@onready var prompt1 := $Prompt1
@onready var player_area := $Area2D
var tracked_bodies: Array = []

var letter_id : int = -1

func _ready():
	prompt1.visible = false
	player_area.connect("body_entered", Callable(self, "_on_body_entered"))
	player_area.connect("body_exited", Callable(self, "_on_body_exited"))


func disable(_variant : Globals.RoomVariant):
	active = false
func enable():
	active = true


func spawn_letter():
	print("spawn_letter")
	
	
	Globals.save_state.letter_progress[letter_id]=true
	Globals.num_letters_collected= min(Globals.num_letters_collected+1,Globals.num_letters)
	Globals.letter_percentage = Globals.num_letters_collected/float(Globals.num_letters)
	queue_free()


func _on_body_entered(body):
	if !active:
		return
	if body.is_in_group("player"):
		tracked_bodies.append(body)
		prompt1.visible = true
		_set_display(tracked_bodies[0])
func _on_body_exited(body):
	if !active:
		return
	if body in tracked_bodies:
		tracked_bodies.erase(body)
	if len(tracked_bodies) == 0:
		prompt1.visible = false
	else:
		_set_display(tracked_bodies[0])

func _set_display(body : Node):
	if body.input_device == "key":
			prompt1.get_child(0).bbcode_text = "[font=res://addons/input_prompt_icon_font/icon.ttf]keyboard_e_outline[/font]: Pickup"
	else:
		prompt1.get_child(0).bbcode_text = "[font=res://addons/input_prompt_icon_font/icon.ttf]playstation_button_cross_outline[/font]: Pickup"
