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
	boss.boss_phase_change.connect(_phase_changed)
			
func _phase_changed(boss_node : Node) -> void:
	phase = boss_node.PROCESS_MODE_WHEN_PAUSED
	var bt_player = boss_node.get_node("BTPlayer")
	var board = bt_player.blackboard
	
	board.set_var("phase", phase)
	board.set_var("phase_changed", true)
	

var lifetime = 0.0
var animation_time = 7.0
var fade_time = .75
var camera_move_time = 3.0
func _process(delta: float) -> void:
	if !active:
		return
	lifetime+=delta
	if !boss or !is_instance_valid(boss):
		deactivate()
	
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
	if boss.current_health <= 0.0:
		deactivate()
		boss.boss_die = true
		boss.emit_signal("enemy_took_damage",100.0,boss.current_health,boss,Vector2(0,-1))

func finish_intro():
	player1.disabled = false
	if is_multiplayer:
		player2.disabled = false
	LayerManager.camera_override = false
	if boss and is_instance_valid(boss):
		if boss.phase == 0:
			boss.phase += 1
			_phase_changed(boss)
		boss.get_node("BTPlayer").blackboard.set_var("attack_mode", "NONE")
	return


func get_cells_in_radius(center : Vector2, radius : float):
	var spawn_cells : Array[Vector2i]
	for cell in LayerManager.placable_cells:
		if(center.distance_to(cell * 16.0) <= radius):
			spawn_cells.append(cell)
	return spawn_cells

func boss_signal(sig :String, value1, value2):
	return
	



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
	SFXManager.play(preload("res://Game Elements/sfx/enemies/bigt/bigt_dead.ogg"))
	for node in get_children():
		if node.is_in_group("pathway"):
			node.enable_pathway()
	active=false
	Hud.hide_boss_bar()
	SteamManager.unlock_achievement("BIG_T")
	


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
	print(player1.disabled)
	print(player1)
	if is_multiplayer:
		player2 = player2_in
		player2.disabled = true
		player2.input_direction = Vector2.UP
		player2.update_animation_parameters(player2.input_direction)
		player2.update_animation_parameters(Vector2.ZERO)
	Hud =LayerManager.hud
	LayerManager.BossIntro.get_node("BossName").text = boss_name
	LayerManager.BossIntro.get_node("Boss").texture = boss_splash_art
	LayerManager.BossIntro.get_node("BossName").add_theme_font_override("normal_font", boss_font)
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
