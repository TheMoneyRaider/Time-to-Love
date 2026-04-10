extends Node2D

var killed : bool = false
@export var tentacle : Node
func kill(dmg_owner : Node, damage : float, current_health : float, direction : Vector2):
	if killed:
		return
	killed = true
	var mat0 = get_parent().get_node("Tentacle/SubViewportContainer/SubViewport/TwoToneCanvasGroup").material
	var mat = mat0.duplicate(true)
	get_parent().get_node("Tentacle/SubViewportContainer/SubViewport/TwoToneCanvasGroup").material = mat
	var tween = create_tween()
	var col1 = mat.get_shader_parameter("light_color")
	var col2 = mat.get_shader_parameter("dark_color")
	tween.tween_method(
		func(value: Color): mat.set_shader_parameter("light_color", value),
		col1,
		Color(1.0,1.0,1.0,0.25),
		1.4
	)
	tween.parallel().tween_method(
		func(value: Color): mat.set_shader_parameter("dark_color", value),
		col2,
		Color(0.0, 0.0, 0.0, 0.15),
		1.4
	)
	await tween.finished
	
	if dmg_owner != null && dmg_owner.is_in_group("player"):
		dmg_owner.kill_enemy(get_parent())
	get_parent().emit_signal("enemy_took_damage",damage,current_health,get_parent(),direction)
	#$Tentacle/SubViewportContainer/SubViewport/TwoToneCanvasGroup.material.set_shader_parameter("light_color",light_color)
	#$Tentacle/SubViewportContainer/SubViewport/TwoToneCanvasGroup.material.set_shader_parameter("dark_color",dark_color)
var target : Node
var LayerManager: Node
var length
func _process(_delta: float) -> void:
	if LayerManager.player1.global_position.distance_to(global_position) < length*1.5:
		tentacle.target = LayerManager.player1
	if LayerManager.is_multiplayer:
		if LayerManager.player2.global_position.distance_to(global_position) < length*1.5:
			tentacle.target = LayerManager.player2
	

func _ready() -> void:
	LayerManager = get_tree().get_root().get_node("LayerManager")
	var L = 16
	var X = 80
	length = randf()*X+L
	tentacle.max_length = length
	tentacle.num__segments = int(length/5.33)
	target = preload("res://Game Elements/Objects/moving_target.tscn").instantiate()
	target.range = 32.0
	target.speed = 32.0
	target.wander_strength = 6
	target.center_pull = 2.0
	target.position = Vector2(randf_range(-1.0,1.0),randf_range(-1.0,1.0)).normalized() * length * (4/3.0 + randf()*1/3.0)
	get_parent().add_child.call_deferred(target)
	tentacle.target = target
	tentacle._initialize_segments()
	
