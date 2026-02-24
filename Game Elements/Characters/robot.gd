extends Node2D

@export var anim_frame : int
@export var min_time : float = 2.0
@export var max_time : float = 6.0
var spawn_time : float
var time : float
@onready var sprite := get_node("../Sprite2D")
@onready var coll := get_node("../CollisionShape2D")
@onready var bt := get_node("../BTPlayer")

func set_frame(frame_in : int):
	sprite.frame = frame_in

func _ready() -> void:
	if sprite.material:
		sprite.material = sprite.material.duplicate() 
	spawn_time = randf_range(min_time,max_time)
	time = spawn_time
	sprite.material.set_shader_parameter("frame", sprite.frame)
	sprite.material.set_shader_parameter("hframes", sprite.hframes)
	sprite.material.set_shader_parameter("vframes", sprite.vframes)
	start_spawn()
	
func start_spawn():
	coll.disabled = true
func end_spawn():
	coll.disabled = false
	self.process_mode = Node.PROCESS_MODE_DISABLED
	bt.blackboard.set_var("state","idle")
	sprite.material=null
	
func _process(delta: float) -> void:
	if time==0.0:
		return
	if time!=0.0 and time<=delta:
		end_spawn()
		return
	time = max(0.0,time-delta)
	var progress= clamp(float(time/spawn_time),0.0,1.0)
	sprite.material.set_shader_parameter("progress", progress)
	
