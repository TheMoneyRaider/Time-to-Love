extends Node2D

var trap_cells := []
var blocked_cells := []
var liquid_cells : Array[Array]= [[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[]]

var camera : Node = null
var player1 : Node = null
var player2 : Node = null
var LayerManager : Node = null
var Hud : Node = null
var screen : Node = null
var active : bool = false
var is_multiplayer : bool = false
var phase = 0
enum skel_type {NORMAL, RED, YELLOW, BLUE, PURPLE}


@export var boss_splash_art : Texture2D
@export var healthbar_underlays : Array[Texture2D]
@export var healthbar_overlays : Array[Texture2D]
@export var boss_names : Array[String]
@export var boss_name_settings : Array[LabelSettings]
@export var boss : Node
@export var boss_name : String
@export var boss_font : Font
#This is what values the bossbar shader is looking for
@export var phase_overlay_index : Array[int]
@export var boss_type : String =""
var phase_changing : bool = false
var animation : String = ""


func _ready() -> void:
	LayerManager = get_tree().get_root().get_node("LayerManager")
	is_multiplayer = Globals.is_multiplayer
	boss.enemy_took_damage.connect(LayerManager._on_enemy_take_damage)
			
	

var lifetime = 0.0
var animation_time = 7.0
var fade_time = .75
var camera_move_time = 3.0
func _process(delta: float) -> void:
	if !active:
		return
	lifetime+=delta
	
	if lifetime >= animation_time and lifetime < animation_time+fade_time:
		finish_animation()
	if lifetime >= animation_time+fade_time and lifetime < animation_time+fade_time+camera_move_time:
		var linear_t = (lifetime-(animation_time+fade_time))/camera_move_time
		var t = ease(linear_t, -2.0) # smooth ease in/out
		camera.global_position = ((player1.global_position + player2.global_position) / 2).lerp(boss.global_position,t) +camera.get_cam_offset(delta)
	elif lifetime >= animation_time+fade_time+camera_move_time and lifetime < animation_time+fade_time+camera_move_time+camera_move_time:
		var linear_t = (lifetime-(animation_time+fade_time+camera_move_time))/camera_move_time
		var t = ease(linear_t, -2.0) # smooth ease in/out
		camera.global_position = ((player1.global_position + player2.global_position) / 2).lerp(boss.global_position,1-t) +camera.get_cam_offset(delta)
	elif lifetime>= animation_time+fade_time+camera_move_time+camera_move_time:
		finish_intro()		
	if animation!= "" and boss and is_instance_valid(boss):
		boss_animation()
	if !boss or !is_instance_valid(boss):
		deactivate()

func finish_intro():
	player1.disabled = false
	if is_multiplayer:
		player2.disabled = false
	LayerManager.camera_override = false
	if boss and is_instance_valid(boss):
		boss.get_node("BTPlayer").blackboard.set_var("attack_mode", "NONE")
	return


func get_cells_in_radius(center : Vector2, radius : float):
	var spawn_cells : Array[Vector2i]
	for cell in LayerManager.placable_cells:
		if(center.distance_to(cell * 16.0) <= radius):
			spawn_cells.append(cell)
	return spawn_cells

func lich_signal(sig :String, value1, value2, value3, value4):
	match sig:
		"spawn_enemies":
			var attack_instance = load("res://Game Elements/Attacks/summoning_circle.tscn").instantiate()
			attack_instance.c_owner = boss
			attack_instance.global_position = value3
			attack_instance.scale = attack_instance.scale * value4 / 64.0
			call_deferred("add_child",attack_instance)
			await get_tree().create_timer(1.0).timeout
			for i in range(value1 / 3):
				if is_multiplayer:
					Spawner.spawn_enemies([player1,player2], self, get_cells_in_radius(value3,value4).duplicate(),LayerManager.room_instance_data,LayerManager,true,value1,value2, false, true)
				else:
					Spawner.spawn_enemies([player1], self, get_cells_in_radius(value3,value4).duplicate(),LayerManager.room_instance_data,LayerManager,true,value1,value2, false, true)
			var color = (randi() % 4) + 1
			var enemies : Array[Node]= []
			var positions : Array[Vector2] = []
			positions.append(player1.global_position)
			if is_multiplayer:
				positions.append(player2.global_position)
			for child in get_children():
				if child.is_in_group("enemy"):
					if(child.global_position.distance_to(value3) <= value4 && child.has_node("SkeletonBrain") && child.get_node("SkeletonBrain").skeleton_type == 0):
						enemies.append(child)
						child.get_node("SkeletonBrain").skeleton_type = color
						match color:
							skel_type.RED:
								child.modulate = Color("Red")
								var attack_scene = load("res://Game Elements/Attacks/skeleton_red_swipe.tscn")
								child.attacks[0] = attack_scene
							skel_type.YELLOW:
								child.modulate = Color("Yellow")
								child.move_speed = 250.0
							skel_type.BLUE:
								child.modulate = Color("Blue")
								child.max_health = 12
								child.current_health = 12
							skel_type.PURPLE:
								child.modulate = Color("Purple")
								child.purple_explode = true
						var board = child.get_node("BTPlayer").blackboard
						if board.get_var("state") == "spawning":
							continue
						#if phase < 2 and !child.is_boss:
						#	child.global_position.y = max(child.global_position.y,-80)
						var distances_squared = []
						for pos in positions: 
							distances_squared.append(child.global_position.distance_squared_to(pos))
						var i = 0
						if distances_squared.size()>1 and distances_squared[1]<distances_squared[0]:
							i= 1
						board.set_var("target_pos", positions[i])
						board.set_var("player_idx", i)
						board.set_var("state", "agro")
			LayerManager.awareness_display.enemies = enemies.duplicate()


func finish_animation():
	var tween = create_tween()
	tween.tween_property(LayerManager.BossIntro.get_node("Transition"),"modulate",Color(0.0,0.0,0.0,0.0),fade_time)
	await tween.finished
	LayerManager.BossIntro.visible = false
	LayerManager.BossIntro.get_node("Transition").modulate = Color(0.0,0.0,0.0,1.0)
	return



func boss_death():
	Hud.hide_boss_bar()


func _on_enemy_take_damage(_damage : float,current_health : int,_enemy : Node, direction = Vector2(0,-1)) -> void:
	pass

func boss_animation():
	pass

var resetting = 0

func animation_change(new_anim: String) -> void:
	animation_reset()
	animation = new_anim
	if boss:
		boss.animation = new_anim

func animation_reset() -> void:
	pass



enum MeleePhase { NONE, SHRINK, LUNGE, DECEL, EXPAND }
	
var attack_cooldown
var attack_direct
var tracked_player
var melee_phase : int = MeleePhase.NONE
var melee_timer : float = 0.0
var melee_duration : float = 0.25
var tracked_player_pos : Vector2
var lunge_velocity : Vector2 = Vector2.ZERO
var target_vector : Vector2 = Vector2.ZERO
var friction : float = 10.0
var track_strength := 6.0
var melee_tween : Tween
var rim_distance = 32.0

func _deflect_melee_attack():
	attack_direct = -1

func _get_player_position() -> Vector2:
	var players = get_tree().get_nodes_in_group("player")
	var positions_array = []
	for player in players: 
		positions_array.append(player.global_position)

	var board = boss.get_node("BTPlayer").blackboard
	
	tracked_player =players[board.get_var("player_idx")]
	return positions_array[board.get_var("player_idx")]

var attack


func update_art(p_in : int):
	pass

func deactivate():
	for node in get_children():
		if node.is_in_group("pathway"):
			node.enable_pathway()
	active=false
	Hud.hide_boss_bar()
	


func activate(camera_in : Node, player1_in : Node, player2_in : Node):
	print("boss room activate")
	active = true
	camera = camera_in
	player1 = player1_in
	player2 = player1_in
	if boss_type=="scifi":
		animation_change("dead")
		var bt_player = boss.get_node("BTPlayer")
		bt_player.blackboard.set_var("attack_mode", "DISABLED")
	#return
	player1.disabled = true
	player1.input_direction = Vector2.UP
	player1.update_animation_parameters(player1.input_direction)
	player1.update_animation_parameters(Vector2.ZERO)
	if is_multiplayer:
		player2 = player2_in
		player2.disabled = true
		player2.input_direction = Vector2.UP
		player2.update_animation_parameters(player2.input_direction)
		player2.update_animation_parameters(Vector2.ZERO)
	Hud =LayerManager.hud
	LayerManager.BossIntro.get_node("BossName").text = boss_name
	LayerManager.BossIntro.get_node("Boss").texture = boss_splash_art
	LayerManager.BossIntro.get_node("BossName").add_theme_font_override("font", boss_font)
	screen = LayerManager.get_node("game_container/game_viewport")
	for node in get_children():
		if node.is_in_group("pathway"):
			node.disable_pathway(true)
	LayerManager.camera_override = true
	screen.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var transition1 = LayerManager.get_node("Transition/Transition")
	transition1.visible = true
	var tween = create_tween()
	tween.tween_property(transition1,"modulate:a",1.0,1.0)
	await tween.finished
	LayerManager.BossIntro.visible = true
	screen.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	transition1.visible = false
	transition1.modulate.a = 0.0
	LayerManager.BossIntro.get_node("AnimationPlayer").play("main")
	camera.global_position = ((player1.global_position + player2.global_position) / 2)
	Hud.show_boss_bar(healthbar_underlays[phase],healthbar_overlays[phase],boss_names[phase],boss_name_settings[phase],phase_overlay_index[phase])
