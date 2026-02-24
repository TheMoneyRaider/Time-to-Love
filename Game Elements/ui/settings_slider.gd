extends HSlider


func _gui_input(event):
	if event.is_action_pressed("ui_left"):
		value -= step
	elif event.is_action_pressed("ui_right"):
		value += step
