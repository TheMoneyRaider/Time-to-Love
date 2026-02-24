extends GPUParticles2D

@export var color_range1 : Texture2D
@export var color_range2 : Texture2D
@export var color_range3 : Texture2D

@export var range_choice : int = -1


func _ready() -> void:
	match range_choice:
		0:
			process_material.color_ramp = color_range1
		1:
			process_material.color_ramp = color_range2
		2:
			process_material.color_ramp = color_range3
		_:
			pass
	emitting = true
	if one_shot:
		await get_tree().create_timer(lifetime).timeout
		queue_free()
