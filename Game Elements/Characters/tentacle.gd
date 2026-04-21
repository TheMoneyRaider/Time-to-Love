extends Node2D

var killed : bool = false
@export var tentacle : Arm
@export var attack : Node
@export var particles : Node
@export var is_purple : bool = false
@export var is_boss_tent : bool = false
var active = false
func kill(dmg_owner : Node, damage : float, current_health : float, direction : Vector2):
	if killed:
		return
	killed = true
	var mat0 = tentacle.get_node("SubViewportContainer/SubViewport/TwoToneCanvasGroup").material
	var mat = mat0.duplicate(true)
	tentacle.get_node("SubViewportContainer/SubViewport/TwoToneCanvasGroup").material = mat
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
	if particles:
		tween.parallel().tween_method(
			func(value: Color): particles.modulate = value,
			Color(1.0, 1.0, 1.0, 1.0),
			Color(0.0, 0.0, 0.0, 0.0),
			1.4
		)
	await tween.finished
	
	if dmg_owner != null && dmg_owner.is_in_group("player"):
		dmg_owner.kill_enemy(get_parent())
	get_parent().emit_signal("enemy_took_damage",damage,current_health,get_parent(),direction)
	
var LayerManager: Node
var length
@export var Tween_Target : Node
@export var target : Node
func _process(delta: float) -> void:
	var bt_player = get_node_or_null("../BTPlayer")
	if !is_boss_tent:
		cooldown -= delta
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
	if !is_boss_tent and cooldown < 0.0:
		bt_player = get_node_or_null("../BTPlayer")
		if bt_player:
			var board = bt_player.blackboard
			if board.get_var("attack_status") == "RUNNING":
				shrink()
	target_tween(LayerManager.player1,ratio,true)
	
	
	
func spawn_enemies(value1, value2):
	if LayerManager.is_multiplayer:
		Spawner.spawn_enemies([LayerManager.player1,LayerManager.player2], LayerManager.room_instance, LayerManager.placable_cells.duplicate(),LayerManager.room_instance_data,LayerManager,true,value1,value2)
	else:
		Spawner.spawn_enemies([LayerManager.player1], LayerManager.room_instance, LayerManager.placable_cells.duplicate(),LayerManager.room_instance_data,LayerManager,true,value1,value2)
	var enemies : Array[Node]= []
	for child in LayerManager.room_instance.get_children():
		if child.is_in_group("enemy"):
			enemies.append(child)
	LayerManager.awareness_display.enemies = enemies.duplicate()
	
func activate():
	active = true
	get_parent().hitable = true
	var tween = create_tween()
	var mat0 = tentacle.get_node("SubViewportContainer/SubViewport/TwoToneCanvasGroup").material
	var mat = mat0.duplicate(true)
	tentacle.get_node("SubViewportContainer/SubViewport/TwoToneCanvasGroup").material = mat
	var col1 = mat.get_shader_parameter("light_color")
	var col2 = mat.get_shader_parameter("dark_color")
	var col1B = lerp(col1,Color(1.0, 1.0, 1.0, 1.0),.85)
	var col2B = lerp(col2,Color(0.712, 0.712, 0.712, 1.0),.85)
	tween.tween_method(
		func(value: Color): mat.set_shader_parameter("light_color", value),
		col1,
		col1B,
		.6
	)
	tween.parallel().tween_method(
		func(value: Color): mat.set_shader_parameter("dark_color", value),
		col2,
		col2B,
		.6
	)
	await tween.finished
	print(tentacle.light_color)
	if abs(tentacle.light_color.r - 1.0) < .01:
		spawn_enemies(int(randf()*8+16),"res://Game Elements/Characters/tentacle1.tscn")
	if abs(tentacle.light_color.g - 1.0) < .01:
		spawn_enemies(int(randf()*8+16),"res://Game Elements/Characters/tentacle2.tscn")
	if abs(tentacle.light_color.b - 1.0) < .01:
		spawn_enemies(int(randf()*8+16),"res://Game Elements/Characters/tentacle3.tscn")
	


func target_tween(player : Node, ratio : float, ignore_player : bool = false):
	#if Tween_Target.global_position.distance_to(global_position) > length * 2.0:
		#Tween_Target.global_position = global_position
	var cur_pos = Tween_Target.global_position
	var player_lerp_factor = .005
	if is_boss_tent:
		player_lerp_factor = .05
	if is_boss_tent and (player.global_position.y >= global_position.y-50 or !active):
		ignore_player = true
	if is_purple:
		Tween_Target.global_position = lerp(cur_pos,((player.global_position - global_position)*1.5 +global_position),.1)
		return
	if !target:
		return
	if ignore_player:
		Tween_Target.global_position = lerp(cur_pos,target.global_position,.1) if is_boss_tent else lerp(cur_pos,target.global_position,.01)
	else:
		Tween_Target.global_position = lerp(cur_pos,((player.global_position - global_position)*1.5 +global_position),.1)

func _ready() -> void:
	LayerManager = get_tree().get_root().get_node("LayerManager")
	if is_boss_tent:
		get_parent().enemy_took_damage.connect(LayerManager._on_enemy_take_damage)
		target = tentacle.target
		tentacle.target = Tween_Target
		length = tentacle.max_length
		get_parent().hitable = false
		return
	grow()
	if is_purple:
		var L = 32
		var X = 48
		length = randf() * X + L
		tentacle.max_length = length
		tentacle.num__segments = int(length / 10)
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
	

func shrink():
	var bt_player
	if !is_purple:
		get_parent().hitable = false
		attack.monitoring = false
		attack.monitorable = false
		print("shrink / FINISHING")
		bt_player = get_node_or_null("../BTPlayer")
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
	
	
	
	bt_player = get_node_or_null("../BTPlayer")
	if bt_player:
		print("finished shrinking ? MELEE / DONE")
		var board = bt_player.blackboard
		board.set_var("attack_mode","MELEE")
		board.set_var("attack_status","DONE")
		
var cooldown : float = 0.0
func grow():
	cooldown = randf() * 3.0 +2.0
	if is_purple:
		return
	var L = 32
	var X = 48
	length = randf() * X + L
	tentacle.max_length = length
	tentacle.num__segments = int(length / 10)

	target.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * length * 2.0
	target.origin = target.global_position
	Tween_Target.position = target.position

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
