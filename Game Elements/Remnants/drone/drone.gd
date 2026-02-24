extends Sprite2D

@export var orbit_radius : float = 32.0
@export var orbit_speed : float = 2        # radians/sec
@export var follow_lerp : float = 2.0        # smoothing
@export var follow_lerp_final : float = 4.0        # smoothing

var player : Node2D
var killed : bool = false
var lifetime = 1000.0
var life = 0.0

func _ready():
	add_to_group("drones")
	$AnimationPlayer.play("fly")
	material = material.duplicate(true)
	var tween = create_tween()
	tween.tween_property(
		material,
		"shader_parameter/progress",
		0.0,
		3.0
	)

func prep(player_path : Node,in_life : float):
	lifetime =in_life
	player = player_path


func kill():
	killed = true
	var tween = create_tween()
	tween.tween_property(
		self.material,
		"shader_parameter/progress",
		1.0,
		0.3
	)
	await tween.finished
	queue_free()

func _process(delta):
	life+= delta
	if life > lifetime and !killed:
		kill()
	follow_lerp = lerp(follow_lerp,follow_lerp_final, delta / 4.0)
	if player == null:
		return

	var drones = get_tree().get_nodes_in_group("drones")
	drones.sort_custom(func(a,b): return a.get_instance_id() < b.get_instance_id())

	var index = drones.find(self)
	var count = drones.size()
	if count == 0:
		return

	# Even spacing around circle
	var spacing = TAU / count

	# Each drone has its own base angle offset
	var base_angle = index * spacing

	# Rotate around player over time
	var ring_angle = Time.get_ticks_msec() * 0.001 * orbit_speed
	var final_angle = base_angle + ring_angle

	var target_pos = player.global_position + Vector2.RIGHT.rotated(final_angle) * orbit_radius

	# Smoothly move to orbit position
	global_position = global_position.lerp(target_pos, follow_lerp * delta)
