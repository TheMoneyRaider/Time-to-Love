extends Sprite2D

var active = false
var direction : Vector2 = Vector2.ZERO

var bezier_values : Array[Vector2] = []
var time : float = 3.0
var duration = 0.0

func launch(direct : Vector2):
	direction = direct.rotated(deg_to_rad(randf_range(-45,45)))
	active = true
	bezier_values.append(position)
	bezier_values.append(position+direction* 300)
	bezier_values.append(Vector2(get_parent().get_parent().get_parent().size.x/2/get_parent().scale.x,0))
	
func _process(delta: float) -> void:
	if !active:
		return
	duration+=delta
	duration = clamp(duration,0.0,time)
	position = quadratic_bezier(duration/time)
	
	
	
	#End effect
	if duration >= time:
		queue_free()
	

	
func quadratic_bezier(t: float) -> Vector2:
	var q0 = bezier_values[0].lerp(bezier_values[1], t)
	var q1 = bezier_values[1].lerp(bezier_values[2], t)
	var r = q0.lerp(q1, t)
	return r
