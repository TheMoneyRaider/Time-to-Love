extends ColorRect

@export var max_value := 1.0
@export var max_pulse := .6
@export var pulse_up_time := 0.125
@export var pulse_down_time := 0.5



func trigger_pulse():
	var tween := create_tween()
	off=false
	last_pulse_total=-1.0
	# rise
	tween.tween_method(_add_pulse_value, 0.0,max_value, pulse_up_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# fall
	tween.tween_method(_add_pulse_value, max_value, 0.0, pulse_down_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


var pulse_total := 0.0
var last_pulse_total := 0.0
var off :bool = true
func _process(_delta: float) -> void:
	if off:
		return
	material.set_shader_parameter("pulse_strength", pulse_total*max_pulse)
	pulse_total=0.0
	call_deferred("_check_off")

func _check_off():
	if last_pulse_total == 0.0:
		off = true
	last_pulse_total = 0.0

func _add_pulse_value(value: float):
	pulse_total+=value
	last_pulse_total+=value
