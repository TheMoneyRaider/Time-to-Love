extends Camera2D

var shake_intensity = 0.0
var shake_decay = 12.0
var original_position = Vector2.ZERO


func get_cam_offset(delta : float):
	if shake_intensity > 0:
		shake_intensity = max(shake_intensity - shake_decay * delta, 0)
		return Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	return Vector2.ZERO

func shake(intensity: float):
	shake_intensity = intensity
