extends Node2D

var active = false
var y_floor = 0
var pos_velocity = Vector2.ZERO
var rot_velocity = 0.0
var gravity = Vector2(0, 900)
var phy_scale = .4


var position_start : Vector2
var position_end : Vector2
var rotation_start : float
var rotation_end : float
var duration : float
var rewinding : bool = false
var timing = 0.0
func _process(delta: float) -> void:
	if rewinding and timing <= duration:
		timing+=delta
		var t = timing/duration
		position = lerp(position_end,position_start,t)
		rotation = lerp(rotation_end,rotation_start,t)
		if timing > duration: rewinding = false
	if !active:
		return
	if position.y < y_floor and pos_velocity.y > 0:
		pos_velocity +=gravity*delta * phy_scale
		position +=pos_velocity*delta * phy_scale
		rotation +=rot_velocity*delta * phy_scale
	else:
		rotation_end = rotation
		position_end = position
		active = false



func activate(move : Vector2, rotation_range : Vector2):
	rotation_start = rotation
	position_start = position
	rot_velocity = randf_range(rotation_range[0],rotation_range[1])
	pos_velocity = move * phy_scale
	y_floor = position.y + 48 + move.y
	active = true
	
	
func start_rewind(rewind_time : float):
	rewinding = true
	duration = rewind_time
	timing=0.0
	
	
