extends CharacterBody2D

enum SLIME_STATE { IDLE, WALK, DIE, HIT }
@export var player : CharacterBody2D
@export var move_speed : float = 12
@export var health : float = 100.0


@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var sprite = $Sprite2D

var move_direction : Vector2 = Vector2.ZERO
var current_state : SLIME_STATE = SLIME_STATE.IDLE

func _ready():
	pick_new_state()


func walk_towards_player():
	move_direction = (player.position - position).normalized()
	if(move_direction.x <0):
		sprite.flip_h = true
	elif(move_direction.x >0):
		sprite.flip_h = false


func _physics_process(_delta):
	pick_new_state()
	if(current_state==SLIME_STATE.WALK):
		walk_towards_player()
		velocity = move_direction * move_speed
		# Update velocity
		velocity = move_direction * move_speed
		#move and slide function
		move_and_slide()




func pick_new_state():
	if(position.distance_to(player.position) < 100 and current_state != SLIME_STATE.WALK):
		#change to walk state
		state_machine.travel("slime_move")
		current_state = SLIME_STATE.WALK
	elif(current_state != SLIME_STATE.IDLE and position.distance_to(player.position) > 100):
		#change to idle state
		state_machine.travel("slime_idle")
		current_state = SLIME_STATE.IDLE


#func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	##do state machine stuff
