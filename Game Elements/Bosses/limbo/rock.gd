extends Node2D

@export var float_range: Vector2 = Vector2(16.0, 64.0)  # max drift in x/y
@export var float_speed: float = 1.0                   # how fast it drifts
@export var rotation_range: float = 0.08               # max rotation in radians
@export var rotation_speed: float = 0.7               

var origin: Vector2
var target_offset: Vector2
var target_rotation: float
var current_offset: Vector2
var last_offset: Vector2  = Vector2.ZERO
var current_rot: float
var last_rot: float

func _ready():
	float_speed = randf() * 4.0 +2.0
	rotation_speed = randf() * 4.0 +2.0
	origin = position
	last_rot = rotation
	_pick_new_target()

func _pick_new_target():
	target_offset = Vector2(
		randf_range(-float_range.x, float_range.x),
		randf_range(-float_range.y, float_range.y)
	)
	target_rotation = randf_range(-rotation_range, rotation_range)
var process = 0.0
func _process(delta):
	process+=delta
	var t =_cubic_bezier_ease(.65,0,.35,1.0,clamp(process / float_speed,0.0,1.0))
	var t2 = _cubic_bezier_ease(.65,0,.35,1.0,clamp(process / rotation_speed,0.0,1.0))
	current_offset = last_offset.lerp(target_offset, t)
	current_rot = lerp(last_rot, target_rotation, t2)
	
	position = origin + current_offset
	rotation = current_rot
	
	# pick a new target once we're close enough to the current one
	if current_offset.distance_to(target_offset) < 0.5:
		process=0.0
		float_speed = randf() * 2.0 +6.0
		rotation_speed = randf() * 2.0 +6.0
		last_offset=current_offset
		last_rot=current_rot
		_pick_new_target()
		
		
		
func _cubic_bezier_ease(x1: float, y1: float, x2: float, y2: float, t: float) -> float:
	# Approximate the Y value for a given T using newton's method
	# P0=(0,0), P1=(x1,y1), P2=(x2,y2), P3=(1,1)
	var sample = t
	for i in range(8):  # iterate to find the t that gives us x == t
		var x = _bezier_coord(x1, x2, sample)
		var dx = _bezier_coord_derivative(x1, x2, sample)
		if abs(dx) < 0.0001: break
		sample -= (x - t) / dx
	return _bezier_coord(y1, y2, sample)

func _bezier_coord(p1: float, p2: float, t: float) -> float:
	return 3.0 * p1 * t * (1.0 - t) * (1.0 - t) \
		 + 3.0 * p2 * t * t * (1.0 - t) \
		 + t * t * t

func _bezier_coord_derivative(p1: float, p2: float, t: float) -> float:
	return 3.0 * p1 * (1.0 - t) * (1.0 - 2.0 * t) \
		 + 3.0 * p2 * t * (2.0 - 3.0 * t) \
		 + 3.0 * t * t
