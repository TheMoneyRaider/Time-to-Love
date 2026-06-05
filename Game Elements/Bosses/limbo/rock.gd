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

# --- Throwing physics ---
var active: bool = false
var disabled: bool = false
var velocity: Vector2 = Vector2.ZERO
var gravity: Vector2 = Vector2(0, 150)
var overshoot_height: float = 48.0
var start_position: Vector2
var target_position: Vector2

@export var shadow: Node2D

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
	if disabled:
		return

	if active:
		_process_throw(delta)
	else:
		_process_float(delta)
		
func _process_float(delta):
	process += delta
	var t  = _cubic_bezier_ease(.65, 0, .35, 1.0, clamp(process / float_speed, 0.0, 1.0))
	var t2 = _cubic_bezier_ease(.65, 0, .35, 1.0, clamp(process / rotation_speed, 0.0, 1.0))
	current_offset = last_offset.lerp(target_offset, t)
	current_rot = lerp(last_rot, target_rotation, t2)
	position = origin + current_offset
	rotation = current_rot

	if current_offset.distance_to(target_offset) < 0.5:
		process = 0.0
		float_speed = randf() * 2.0 + 6.0
		rotation_speed = randf() * 2.0 + 6.0
		last_offset = current_offset
		last_rot = current_rot
		_pick_new_target()
		
func _process_throw(delta):
	velocity += gravity * delta
	position += velocity * delta

	# Shadow tracks straight line between start and target
	if shadow:
		shadow.global_position.x = global_position.x
		shadow.global_position.y = lerp(
			start_position.y,
			target_position.y,
			(global_position.x - start_position.x) / (target_position.x - start_position.x)
		)
		var y_diff = global_position.y - shadow.global_position.y
		var t = clamp(-y_diff / overshoot_height, 0.0, 1.0)
		shadow.scale = Vector2.ONE * lerp(1.0, 1.35, t)
		shadow.modulate.a = lerp(0.45, 0.15, t)

	var reached_x = (velocity.x > 0 and position.x >= target_position.x) \
				 or (velocity.x < 0 and position.x <= target_position.x)
	var reached_y = (velocity.y > 0 and position.y >= target_position.y)

	if reached_x and reached_y:
		global_position = target_position
		velocity = Vector2.ZERO
		_on_land()

		
func activate(input: Node):
	SFXManager.play(preload("res://Game Elements/sfx/weapons/crowbar/falling_rock.ogg"), 10.0, "SFX", global_position)
	target_position = input.global_position
	active = true
	start_position = global_position

	var peak_y = min(start_position.y, target_position.y) - overshoot_height
	var delta_y = start_position.y - peak_y
	var g = gravity.y
	var vy0 = -sqrt(2 * g * delta_y)
	velocity.y = vy0

	var y0 = start_position.y
	var y_target = target_position.y
	var a = 0.5 * g
	var b = vy0
	var c = y0 - y_target
	var discriminant = max(b * b - 4 * a * c, 0.0)
	var t_total = (-b + sqrt(discriminant)) / (2 * a)
	if t_total <= 0.01:
		t_total = 0.1

	velocity.x = (target_position.x - start_position.x) / t_total

	if shadow:
		shadow.global_position = start_position
		shadow.modulate = Color(0, 0, 0, 0.45)

func _on_land():
	disabled = true
	SFXManager.play(preload("res://Game Elements/sfx/weapons/crowbar/crowbar_special_impact.ogg"), 5.0)
	var attack_inst = load("res://Game Elements/Attacks/rock_final.tscn").instantiate()
	attack_inst.global_position = global_position
	attack_inst.c_owner = get_parent().boss
	attack_inst.direction = Vector2.UP
	get_parent().add_child(attack_inst)
	get_parent().LayerManager.camera.shake(20)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.125)
	await tween.finished   # wait until tween actually finishes
	queue_free()

# --- Bezier easing ---
func _cubic_bezier_ease(x1: float, y1: float, x2: float, y2: float, t: float) -> float:
	var sample = t
	for i in range(8):
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
