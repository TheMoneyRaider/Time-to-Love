extends Node2D

var lifetime : float = 10.0

var duration = 0.0
var fade_in = .125
var fade_out = .25
var p_owner : Node

func _ready() -> void:
	$Shell.visible = false
	$Cover.modulate.a = 0.0
	var tween  =create_tween()
	tween.tween_property($Cover,"modulate:a", 1.0, fade_in)
	tween.tween_property($Shell, "visible", true, 0.01)
	tween.tween_property($Cover,"modulate:a", 0.0, fade_in)
	$Deflection.c_owner = p_owner

var fading : bool = false
func _process(delta: float) -> void:
	if duration +fade_out > lifetime and !fading:
		var tween =create_tween()
		tween.tween_property($Shell, "modulate.a", 0.0, fade_out)
		fading = true
	duration+=delta
	if duration > lifetime:
		queue_free()
