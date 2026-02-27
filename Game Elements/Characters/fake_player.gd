extends RigidBody2D
var speed = 400.0
var is_purple : bool
var active : bool = false
var is_tethered : bool = false
var input_direction : Vector2 = Vector2.ZERO
@export var state_machine : LimboHSM
@onready var idle_state = $LimboHSM/Idle
@onready var move_state = $LimboHSM/Move
@onready var attack_state = $LimboHSM/Attack
@onready var swap_state = $LimboHSM/Swap
@onready var purple_texture = preload("res://art/Sprout Lands - Sprites - Basic pack/Characters/Basic Purple Spritesheet-export.png")
@onready var orange_texture = preload("res://art/Sprout Lands - Sprites - Basic pack/Characters/Basic Orange Spritesheet-export.png")


func _ready():
	_initialize_state_machine()
	
func disable():
	if !active:
		return
	active = false
	$CollisionShape2D.disabled = true
	visible = false
	linear_velocity = Vector2.ZERO
	
	
	
var _pending_teleport : bool = false
var _teleport_position : Vector2 = Vector2.ZERO

func enable(player : Node, direction : Vector2, is_purple_in : bool):
	if active:
		return
	active = true
	$CollisionShape2D.disabled = false

	_teleport_position = player.global_position
	global_position = player.global_position
	_pending_teleport = true
	linear_velocity = Vector2.ZERO
	apply_impulse(direction* speed, Vector2.ZERO)
	input_direction = direction
	is_purple = is_purple_in
	if(is_purple):
		$Sprite2D.texture = purple_texture
	else:
		$Sprite2D.texture = orange_texture

func _integrate_forces(state):
	if _pending_teleport:
		state.transform.origin = _teleport_position
		_pending_teleport = false
		visible = true

func _physics_process(_delta: float) -> void:
	if active:
		var direct = linear_velocity.normalized()
		if linear_velocity.length() < 24.0 and !_pending_teleport:
			input_direction =Vector2.ZERO
		update_animation_parameters(direct)
		
	
func update_animation_parameters(move_input : Vector2):
	if(move_input != Vector2.ZERO):
		idle_state.move_direction = move_input
		move_state.move_direction = move_input

func apply_movement(_delta):
	pass

func _initialize_state_machine():
	#Define State transitions
	state_machine.add_transition(idle_state,move_state, "to_move")
	state_machine.add_transition(move_state,idle_state, "to_idle")
	
	state_machine.initial_state = idle_state
	state_machine.initialize(self)
	state_machine.set_active(true)
