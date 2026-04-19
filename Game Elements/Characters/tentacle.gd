extends Node2D

var killed : bool = false
@export var tentacle : Node
@export var attack : Node
@export var particles : Node
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
var target : Node
var LayerManager: Node
var length
@export var Tween_Target : Node
func _process(delta: float) -> void:
	cooldown -= delta
	var bt_player = get_node("../BTPlayer")
	if bt_player:
		var board = bt_player.blackboard
		var attack_mode = board.get_var("attack_mode")
		var attack_status = board.get_var("attack_status")
		if attack_status == "STARTING" and attack_mode == "NONE":
			print("start growth/ RUNNING")
			board.set_var("attack_status","RUNNING")
			grow()
	var ratio = LayerManager.player1.global_position.distance_to(global_position) / (length*1.1)
	if ratio < 1.0:
		target_tween(LayerManager.player1,ratio)
		return
	if LayerManager.is_multiplayer:
		ratio = LayerManager.player2.global_position.distance_to(global_position) / (length*1.1)
		if ratio < 1.0:
			target_tween(LayerManager.player2,ratio)
			return
	if cooldown < 0.0:
		bt_player = get_node("../BTPlayer")
		if bt_player:
			var board = bt_player.blackboard
			if board.get_var("attack_status") == "RUNNING":
				shrink()
	target_tween(LayerManager.player1,ratio,true)
	
	
	
	
	


func target_tween(player : Node, ratio : float, ignore_player : bool = false):
	if !target:
		return
	var cur_pos = Tween_Target.global_position
	if ignore_player:
		Tween_Target.global_position = lerp(cur_pos,target.global_position,.01)
		return
	else:
		Tween_Target.global_position = lerp(cur_pos,(player.global_position - global_position)*1.5 +global_position ,.005+.1 * (1.0-ratio))
		
func _ready() -> void:
	LayerManager = get_tree().get_root().get_node("LayerManager")
	grow()
	

func shrink():
	get_parent().hitable = false
	attack.monitoring = false
	attack.monitorable = false
	print("shrink / FINISHING")
	var bt_player = get_node("../BTPlayer")
	if bt_player:
		var board = bt_player.blackboard
		board.set_var("attack_status","FINISHING")
	var tween = create_tween()
	tween.tween_method(
		tentacle.set_length_scale,
		1.0, 0.0, 0.4
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await tween.finished
	var tween2 = create_tween()
	# Fade out (timed to finish with the shrink)
	tween2.parallel().tween_property(tentacle, "modulate:a", 0.0, 0.2)
	await tween2.finished
	target.queue_free()
	
	
	
	bt_player = get_node("../BTPlayer")
	if bt_player:
		print("finished shrinking ? MELEE / DONE")
		var board = bt_player.blackboard
		board.set_var("attack_mode","MELEE")
		board.set_var("attack_status","DONE")
		
var cooldown : float = 0.0
func grow():
	var L = 32
	var X = 48
	length = randf() * X + L
	cooldown = randf() * 3.0 +2.0
	tentacle.max_length = length
	tentacle.num__segments = int(length / 5.33)

	target = preload("res://Game Elements/Objects/moving_target.tscn").instantiate()
	target.range = 32.0
	target.speed = 32.0
	target.wander_strength = 6
	target.center_pull = 2.0
	target.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * length * (4/3.0 + randf() * 1/3.0)
	get_parent().add_child.call_deferred(target)

	tentacle._initialize_segments()
	tentacle.set_length_scale(0.0)
	# Fade in
	tentacle.modulate.a = 0.0
	var fade_tween = create_tween()
	fade_tween.tween_property(tentacle, "modulate:a", 1.0, 0.4)
	
	var tween = create_tween()
	tween.tween_method(
		tentacle.set_length_scale,
		0.0, 1.0, 1.2
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	get_parent().hitable = true
	attack.monitoring = true
	attack.monitorable = true
