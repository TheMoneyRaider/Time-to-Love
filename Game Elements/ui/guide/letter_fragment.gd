extends Button

var polygon_points : Array = []

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		var local_pos = event.position / size
		if _point_in_polygon(local_pos):
			emit_signal("pressed")

func _point_in_polygon(p : Vector2) -> bool:
	# Use ray-casting method
	var inside = false
	var n = polygon_points.size()
	for i in range(n):
		var a = polygon_points[i]
		var b = polygon_points[(i + 1) % n]
		if ((a.y > p.y) != (b.y > p.y)) and (p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y + 0.00001) + a.x):
			inside = not inside
	return inside
