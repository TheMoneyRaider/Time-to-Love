extends Control

@export var hold_time: float = 2.0          # seconds of input needed to skip
@export var decay_rate: float = 1.0         # how fast it drains per second

var progress: float = 0.0
var is_any_input_held: bool = false

signal skip_requested

var active : bool = false
func _process(delta: float) -> void:
	if active:
		if is_any_input_held:
			progress += delta / hold_time
		else:
			progress -= delta * decay_rate / hold_time

		progress = clamp(progress, 0.0, 1.0)
		modulate.a = clamp(progress*4.0,0.0,1.0)
		$ProgressBar.value = progress * 100
		if progress >= 1.0:
			emit_signal("skip_requested")
			progress = 0.0
			active = false

func _input(event: InputEvent) -> void:
	if active:
		# Ignore mouse movement
		if event is InputEventMouseMotion:
			return
		
		# Block all non-mouse-movement input from reaching other nodes
		get_viewport().set_input_as_handled()
		
		if event is InputEventKey or \
		   event is InputEventJoypadButton or \
		   event is InputEventMouseButton:
			is_any_input_held = not event.is_released()
