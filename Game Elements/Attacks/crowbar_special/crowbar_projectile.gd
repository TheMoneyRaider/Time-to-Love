extends Node2D
var viewport_size = Vector2(64,64)
@export var room_root : Node
@export var mask : Node
@onready var vp = $SubViewport
var created : bool =false
@onready var sprites = [$Sprite1,$Sprite2,$Sprite3,$Sprite4,$Sprite5]

var target : Node

var velocity = Vector2.ZERO
var gravity = Vector2(0,150)
var original_position : Vector2
var player_owner : Node
var active = false
var lifetime =0.0
var duration = 0.0
var overshoot_height = 48.0
var start_position : Vector2
var disabled = false


func _ready() -> void:
	original_position= position
	var tex =await flatten_nodes_to_sprite(room_root,19)
	for sp in sprites:
		sp.texture = tex

func _process(delta: float) -> void:
	if disabled:
		return
	if sprites[0].texture and !created:
		for sp in sprites:
			sp.material = sp.material.duplicate(true)
			sp.material.set_shader_parameter("mask",mask.get_whole_image())
			sp.material.set_shader_parameter("mask_offset",global_position+sp.material.get_shader_parameter("mask_offset"))
			
		created=true
		velocity = Vector2(0,-100)
	if !created:
		return
	if active:
		 # Move node
		velocity += gravity * delta
		position += velocity * delta

		# Check if passed target
		var reached_x = (velocity.x > 0 and position.x >= target.global_position.x) or (velocity.x < 0 and position.x <= target.global_position.x)
		var reached_y = (velocity.y > 0 and position.y >= target.global_position.y)

		if reached_x and reached_y:
			global_position = target.global_position
			velocity = Vector2.ZERO
			attack()
			#DO BOOM
	else:
		velocity+= gravity * delta
		position+=velocity*delta
		if original_position.y - position.y <=0:
			queue_free()

func flatten_nodes_to_sprite(root: Node, z_limit: int) -> Texture:

	vp.size = viewport_size
	_copy_below_z(root,z_limit)

	# Force one frame update (optional)
	await get_tree().process_frame
	await get_tree().process_frame
	var img: Image = vp.get_texture().get_image()
	var texture := ImageTexture.create_from_image(img)

	vp.queue_free()

	return texture



func attack():
	var attack_inst = load("res://Game Elements/Attacks/crowbar_special/crowbar_final.tscn").instantiate()
	attack_inst.global_position = global_position
	attack_inst.c_owner = player_owner
	attack_inst.damage *= player_owner.damage_boost()
	attack_inst.direction = Vector2.UP
	get_parent().add_child(attack_inst)
	disabled = true
	player_owner.LayerManager.camera.shake(20)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.125) # notice the ':' syntax in Godot 4
	await tween.finished   # wait until tween actually finishes
	tween = create_tween()
	tween.tween_property(target, "modulate:a", 0.0, 4.0) # notice the ':' syntax in Godot 4
	await tween.finished   # wait until tween actually finishes
	queue_free()

func activate(input: Node, player : Node):
	player_owner = player
	for sp in sprites:
		sp.material.set_shader_parameter("masking_enabled", false)
	target = input
	active = true
	start_position = global_position

	var peak_y = min(start_position.y, target.global_position.y) - overshoot_height
	var delta_y = start_position.y - peak_y

	# Gravity magnitude
	var g = gravity.y

	# Initial vertical speed to reach the peak
	var vy0 = -sqrt(2 * g * delta_y)
	velocity.y = vy0

	# Solve quadratic to find total time to reach target Y
	var y0 = start_position.y
	var y_target = target.global_position.y
	var a = 0.5 * g
	var b = vy0
	var c = y0 - y_target

	var discriminant = b*b - 4*a*c
	if discriminant < 0:
		discriminant = 0

	var t_total = (-b + sqrt(discriminant)) / (2*a)
	if t_total <= 0.01:
		t_total = 0.1

	# Horizontal velocity to reach target X in that time
	var delta_x = target.global_position.x - start_position.x
	velocity.x = delta_x / t_total

func _copy_below_z(node: Node2D, z_limit: int):
	if node.z_index <= z_limit and node is TileMapLayer:
		var copy := node.duplicate()

		# Convert node transform into THIS node's local space
		var local_xform = global_transform.affine_inverse() * node.global_transform
		local_xform.origin += viewport_size * 0.5
		copy.transform = local_xform

		vp.add_child(copy)

	for child in node.get_children():
		if child is Node2D:
			_copy_below_z(child, z_limit)
