extends RigidBody2D



@export var force_strength := 320
@export var attack: Node2D
@export var player: Node2D
var temp_scale : Vector2
func setup(node : Node):
	attack = node
	player = node.c_owner
	temp_scale = attack.scale
	apply_impulse(attack.direction *attack.speed, Vector2.ZERO)
func _physics_process(_delta: float) -> void:
	if attack:
		if scale != temp_scale:
			scale = temp_scale
		attack.global_position = global_position
		attack.global_rotation = global_rotation
		attack.direction = linear_velocity.normalized()
		var dir = (player.global_position - global_position).normalized()
		apply_force(dir * force_strength)
