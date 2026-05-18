extends GPUParticles2D

@export var color_range1 : Texture2D
@export var color_range2 : Texture2D
@export var color_range3 : Texture2D

@export var range_choice : int = -1

@export var letter : bool = false

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
	if one_shot:
		emitting = true
var duration =0.0
var fade_in := lifetime * 0.2   # first 20% fading in
var fade_out := lifetime * 0.2  # last 20% fading out
func _process(delta: float) -> void:
	if one_shot:
		duration+=delta
	if letter:
		# middle 60% is fully visible
		var alpha: float
		if duration < fade_in:
			alpha = duration / fade_in
		elif duration > lifetime - fade_out:
			alpha = (lifetime - duration) / fade_out
		else:
			alpha = 1.0
		get_tree().get_root().get_node("LayerManager/LettersPopup").modulate.a = clamp(alpha, 0.0, 1.0)
	if one_shot and duration >= lifetime:
		queue_free()
