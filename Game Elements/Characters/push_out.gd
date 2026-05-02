extends Area2D


@export var push_strength := 1
@onready var parent = $".."
var last_locations : Array[Vector2] = [Vector2(0,0)]


func _physics_process(delta):
	var do_push = true
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body is TileMapLayer:
			do_push = false
	#if(do_push == false):
		#var dir = (last_locations[0] - global_position)
		#call_deferred("delay_trigger",(dir * delta * push_strength * 5))
	for body in bodies:
		if body is TileMapLayer:
			continue
		if body == parent:
			continue
		if do_push == true:
			last_locations.append(global_position)
			if(last_locations.size() > 5):
				last_locations.pop_front()
		var dir = (body.global_position - global_position)
		var distance = dir.length()
		
		if distance > 0:
			dir = dir.normalized()
			# Stronger push near the center				
			call_deferred("delay_trigger",-(dir * distance * delta * push_strength))
			
			
func delay_trigger(movement : Vector2):
	#await get_tree().process_frame
	parent.global_position += movement
