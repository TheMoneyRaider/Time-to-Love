extends Area2D


@export var push_strength := 1
@onready var parent = $".."

func _physics_process(delta):
	var do_push = true
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body is TileMapLayer:
			do_push = false
	for body in bodies:
		if body is TileMapLayer:
			continue
		var dir = (body.global_position - global_position)
		var distance = dir.length()

		if distance > 0:
			dir = dir.normalized()
			
			# Stronger push near the center
			
			body.global_position += dir * distance * delta * push_strength
			if(do_push):
				parent.global_position -= dir * distance * delta * push_strength
			else:
				parent.global_position += dir * distance * delta * push_strength
