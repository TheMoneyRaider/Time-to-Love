extends Button

signal fragment_hovered
signal fragment_unhovered

var polygon_points : Array = []
var hovering := false


func _process(_delta):
	queue_redraw()
	if polygon_points.size() < 3:
		return

	var mouse = get_global_mouse_position() - position

	var inside = _point_in_polygon(mouse)
	if inside and !hovering:
		hovering = true
		emit_signal("fragment_hovered")

	elif !inside and hovering:
		hovering = false
		emit_signal("fragment_unhovered")

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		var uv = event.global_position
		if _point_in_polygon(uv):
			emit_signal("pressed")

func scale_polygon(points: Array, p_scale: float):
	var center := Vector2.ZERO
	
	for p in points:
		center += p
	center /= points.size()
	
	var new_points := []
	for p in points:
		var dir = p - center
		new_points.append(center + dir * p_scale)

	polygon_points = new_points

func _draw():
	if polygon_points.size() < 3:
		return
	
	var pts := PackedVector2Array()

	for p in polygon_points:
		pts.append(p * size)

	draw_colored_polygon(pts, Color(0,1,0,0.2))
	draw_polyline(pts, Color(0,1,0), 2.0, true)

func _point_in_polygon(p : Vector2) -> bool:
	var inside = false
	var n = polygon_points.size()

	for i in range(n):
		var a = polygon_points[i]
		var b = polygon_points[(i + 1) % n]

		if ((a.y > p.y) != (b.y > p.y)) \
		and (p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y + 0.00001) + a.x):
			inside = not inside

	return inside
