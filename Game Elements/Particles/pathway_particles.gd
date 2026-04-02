extends Node2D
func _ready():
	for child in get_children():
		child.emitting = true
var duration =0.0
func _process(delta: float) -> void:
	duration+=delta
	if duration >= get_child(0).lifetime:
		queue_free()
