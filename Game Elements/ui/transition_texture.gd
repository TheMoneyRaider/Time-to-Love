extends CanvasLayer
@export var fade_duration: float = 0.5  # seconds

func _ready():
	var tex_rect2 = get_child(1)
	# Start fade-out
	var tween = create_tween()
	tween.tween_property(tex_rect2, "modulate:a", 1.0, fade_duration)
	await tween.finished
	_fade_out()


func get_properties(texture : TextureRect) -> void:
	var tex_rect = get_child(0)
	tex_rect.material.set_shader_parameter("intensity", texture.material.get_shader_parameter("intensity"))
	tex_rect.material.set_shader_parameter("time", texture.material.get_shader_parameter("time"))
	

func _fade_out():
	var tex_rect = get_child(0)
	var tex_rect2 = get_child(1)
	tex_rect.visible = false
	var tween = create_tween()
	# Fade alpha to 0 to disappear
	tween.tween_property(tex_rect2, "modulate:a", 0.0, fade_duration)
	await tween.finished
	queue_free()
