extends SubViewport

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		print("game-viewport sees click at: ", event.position)
