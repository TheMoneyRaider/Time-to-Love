extends Node2D
func _ready():
	$Orange.emitting = true
	$Purple.emitting = true
var duration =0.0
func _process(delta: float) -> void:
	duration+=delta
	if duration >= $Orange.lifetime and duration >= $Purple.lifetime:
		queue_free()
