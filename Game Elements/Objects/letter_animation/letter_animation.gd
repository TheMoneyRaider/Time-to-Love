extends Sprite2D

var active = false
var direction : Vector2 = Vector2.ZERO

var bezier_values : Array[Vector2] = []
var time : float = 2.0
var duration = 0.0
var rotation_speed

func launch(direct : Vector2):
	bezier_values.clear()
	self_modulate = Color.WHITE
	direction = direct.rotated(deg_to_rad(randf_range(-45,45)))
	active = true
	
	var screen_size = get_viewport_rect().size
	var right_edge = screen_size.x / 2 / get_parent().zoom.x
	
	bezier_values.clear()
	bezier_values.append(position)
	bezier_values.append(position + direction * 300)
	bezier_values.append(Vector2(right_edge, 0))
	
	rotation_speed = randf_range(-.1,.1)
	
func _process(delta: float) -> void:
	if !active:
		return
	duration+=delta
	duration = clamp(duration,0.0,time)
	position = quadratic_bezier(duration/time)
	rotation+=rotation_speed
	
	
	
	#End effect
	if duration >= time:
		var particles = preload("res://Game Elements/Particles/letter_particles.tscn").instantiate()
		var screen_size = get_viewport_rect().size
		var right_edge = screen_size.x / 2 / get_parent().zoom.x
		particles.position = Vector2(right_edge,0)
		get_parent().add_child(particles)
		queue_free()
	

	
func quadratic_bezier(t: float) -> Vector2:
	var q0 = bezier_values[0].lerp(bezier_values[1], t)
	var q1 = bezier_values[1].lerp(bezier_values[2], t)
	var r = q0.lerp(q1, t)
	return r
