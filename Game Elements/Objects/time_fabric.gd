extends Node2D

@onready var sprite := $Sprite2D

# --- Movement variables ---
var velocity := Vector3.ZERO
var position_z := 0.0
var grounded := false
var first_jump := true
var rotation_speed := 0.0
var jump_cooldown := 0.0

# --- Environment ---
@onready var liquid_cells := []

@onready var blocked_cells := []

# --- Behavior params ---
@export var gravity := 300.0
@export var max_rotation_speed := 10
@export var bob_amplitude := .2
@export var bob_speed := 3
@export var min_jump_interval := 0.3
@export var max_jump_interval := 0.7

# --- Internal ---
var time_passed := 0.0
var freeze_time := 0.0
var bob_offset := 0.0
var attracted = false

signal absorbed_by_player(timefabric : Node)

func _ready() -> void:
	randomize()
	time_passed = randf() * 5
	bob_offset = randf() * 5
	position_z = 0.0
	grounded = false

func _process(delta: float) -> void:
	time_passed += delta
	freeze_time += delta
	if freeze_time < 0.2:
		return
	# Move toward player if needed
	if !first_jump:
		move_towards_player()
	# --- In air: apply gravity ---
	velocity.z += gravity * delta
	position += Vector2(velocity.x, velocity.y) * delta
	position_z += velocity.z * delta
		
	if not grounded:
		# Rotate sprite while in air
		sprite.rotation += deg_to_rad(rotation_speed * delta)

		# Wall collision
		_check_if_hitting_wall(delta)

		# Ground collision
		if position_z >= 0.0:
			position_z = 0.0
			# Landed fully
			grounded = true
			first_jump = false
			velocity = Vector3.ZERO
			rotation_speed = 0.0
			jump_cooldown = randf_range(min_jump_interval, max_jump_interval)

	if grounded:
		if in_liquid(delta):
			sprite.position.y = sin(time_passed* bob_speed) * bob_amplitude*3.5
			sprite.rotation = sin((time_passed+bob_offset)* bob_speed) * bob_amplitude
		elif !attracted:
			# Jump after cooldown
			jump_cooldown -= delta
			if jump_cooldown <= 0.0:
				perform_random_hop()


func in_liquid(delta):
	var cell := Vector2i(floor((position.x)/16), floor(position.y/16))
	if cell in liquid_cells[Globals.Liquid.Conveyer]:
		var tile_pos = Vector2i(int(floor(global_position.x / 16)),int(floor(global_position.y / 16)))
		var tile_data = get_tree().get_root().get_node("LayerManager").return_liquid_layer(tile_pos).get_cell_tile_data(tile_pos)
		if tile_data:
			position+=tile_data.get_custom_data("direction").normalized() *delta * 32
	if cell in liquid_cells[0]:
		return true
	return false

func set_direction(direction : Vector2):
	# Initial big toss
	var base_dir = direction.normalized()
	var max_angle = deg_to_rad(20.0)
	var angle_offset = randf_range(-max_angle, max_angle)
	var deviated_dir = base_dir.rotated(angle_offset)

	var orig_len = 100
	var random_scale = lerp(1.0, randf_range(0.5, 1.5), 0.4)
	var final_len = orig_len * random_scale
	var z = -randf_range(0.25, 1.0)

	velocity = Vector3(deviated_dir.x * final_len,
					   deviated_dir.y * final_len - 60,
					   z * final_len)
	grounded = false
	rotation_speed = randf_range(-max_rotation_speed, max_rotation_speed)

func perform_random_hop():
	var angle_offset = randf_range(-180, 180)
	var deviated_dir = Vector2(0,-1).rotated(angle_offset)
	var speed = randf_range(15, 30)
	velocity.x = deviated_dir.x * speed
	velocity.y = deviated_dir.y * speed
	velocity.z = -abs(deviated_dir.y * speed * .6)
	rotation_speed = randf_range(-max_rotation_speed*speed, max_rotation_speed*speed)
	grounded = false

func _check_if_hitting_wall(delta) -> void:
	var next_cellx := Vector2i(floor((position.x+velocity.x*delta)/16), floor(position.y/16))
	var next_celly := Vector2i(floor(position.x/16), floor((position.y+velocity.y*delta)/16))
	if next_cellx in blocked_cells or next_celly in blocked_cells:
		velocity = Vector3.ZERO
		grounded = true
		first_jump = false

func move_towards_player():
	var layer_manager = get_tree().get_root().get_node("LayerManager")
	if layer_manager.is_multiplayer:
		check_player(layer_manager.player1)
		check_player(layer_manager.player2)
	else:
		check_player(layer_manager.player1)

func check_player(player : Node):
	var dir = (player.position - position)
	var distance = dir.length()
	var attraction_radius = 60.0
	if distance < attraction_radius:
		var new_vel = dir.normalized() * (100.0 + (attraction_radius - distance) * 5.0)
		velocity = Vector3(new_vel.x, new_vel.y, 0)
		attracted = true
	if distance < 5:
		emit_signal("absorbed_by_player", self)

func set_arrays(layer_manager : Node) -> void:
	liquid_cells = layer_manager.liquid_cells
	blocked_cells = layer_manager.blocked_cells
