extends GPUParticles2D

@export var color_range1 : Texture2D
@export var color_range2 : Texture2D
@export var color_range3 : Texture2D

@export var range_choice : int = -1


func _ready() -> void:
	if process_material:
		process_material = process_material.duplicate(true)
	
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
var duration =0.0
func _process(delta: float) -> void:
	if one_shot:
		duration+=delta
		if duration >= lifetime:
			queue_free()
