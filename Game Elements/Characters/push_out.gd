extends Area2D


@export var push_strength := 1
@onready var parent = $".."

func _physics_process(delta):
	for body in get_overlapping_bodies():
		var dir = (body.global_position - global_position)
		var distance = dir.length()

		if distance > 0:
			dir = dir.normalized()
			
			# Stronger push near the center

			body.global_position += dir * distance * delta * push_strength
			parent.global_position -= dir * distance * delta * push_strength
