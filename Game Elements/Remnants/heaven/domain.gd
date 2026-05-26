extends Node2D

var lifetime : float = 10.0
@export var domain_type = ""
@export var domain_range : float
@export var damage_change : float = 0.0
var duration = 0.0
@export var fade_out = .25
var deflection : Node

func _ready() -> void:
	$AnimationPlayer.play("start")
	$AnimationPlayer.queue("main")
	if $GPUParticles2D:
		$GPUParticles2D.process_material.gravity *= scale.x
		$GPUParticles2D.process_material.radial_velocity *= scale.x
		$GPUParticles2D.process_material.radial_accel *= scale.x
		$GPUParticles2D.amount *= scale.x
		


var fading : bool = false
func _process(delta: float) -> void:
	if duration +fade_out > lifetime and !fading:
		var tween =create_tween()
		tween.tween_property($Art, "modulate:a", 0.0, fade_out)
		fading = true
	duration+=delta
	if duration > lifetime:
		queue_free()
		if deflection: deflection.queue_free()
