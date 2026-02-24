extends Node2D

@export var range: float = 48
@export var speed: float = 48
@export var wander_strength := 5
@export var center_pull := 1.5

var origin: Vector2
var velocity: Vector2

func _ready():
	randomize()
	origin = global_position
	velocity = Vector2.RIGHT.rotated(randf() * TAU)

func _process(delta):
	#Small random wander
	velocity = velocity.rotated(randf_range(-wander_strength, wander_strength) * delta)

	#Soft pull toward center
	var to_center = origin - global_position
	var dist = to_center.length()
	if dist > 0.01:
		var pull = to_center.normalized() * (dist / range) * center_pull
		velocity += pull * delta 

	velocity = velocity.normalized()
	global_position += velocity * speed * delta / 2
