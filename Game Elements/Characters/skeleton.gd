extends Node2D

@export var anim_frame : int
@onready var sprite := get_node("../Sprite2D")
enum skel_type {NORMAL, RED, YELLOW, BLUE, PURPLE}
@export var skeleton_type : skel_type = 0

func set_frame(frame_in : int):
	sprite.frame = frame_in
