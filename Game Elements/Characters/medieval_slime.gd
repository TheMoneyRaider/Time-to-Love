extends Node2D

@export var anim_frame : int
@onready var sprite := get_node("../Sprite2D")


func set_frame(frame_in : int):
	sprite.frame = frame_in
