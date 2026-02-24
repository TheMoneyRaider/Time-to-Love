extends Node2D

var duration := 1.3
var peak_height := 80.0
var horizontal_offset := 60.0
var gravity_strength := 80.0
var is_heal := false

var _start_position: Vector2
var _start_rotation: float = 0.0
var _target_rotation: float
var _duration: float

@onready var line = $Line2D
func setup(in_points: PackedVector2Array, in_width: float, color: Color, heal: bool, flipped: bool):
	line.points = in_points
	line.width = in_width
	line.default_color = color
	
	is_heal = heal
	if is_heal:
		duration = .6
	
	_start_position = position
	_target_rotation = randf_range(-2.0, 2.0)
	_duration = duration
	# Direction based on flip
	horizontal_offset *= (-1 if flipped else 1)

func _process(delta: float) -> void:
	duration = max(duration - delta, 0.0)
	
	var forward_t = 1.0 - duration / _duration
	
	# Reverse time for healing
	var t = forward_t
	if is_heal:
		t = 1.0 - forward_t
	
	var x = _start_position.x + horizontal_offset * t
	
	var arc = -4.0 * peak_height * t * (t - 1.0)
	var gravity = gravity_strength * t
	
	var y = _start_position.y - arc + gravity
	
	position = Vector2(x, y)
	
	rotation = lerp(0.0, _target_rotation, t)
	
	modulate.a = 1- t
	
	if duration <= 0.0:
		queue_free()
