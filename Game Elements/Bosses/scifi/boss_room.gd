extends Node2D

var trap_cells := []
var blocked_cells := []
var liquid_cells : Array[Array]= [[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[]]

var camera : Node = null
var player1 : Node = null
var player2 : Node = null
var LayerManager : Node = null
var screen : Node = null
var active : bool = false
var is_multiplayer : bool = false

@export var boss_splash_art : Texture2D
@export var boss : Node
@export var boss_name : String
@export var boss_font : Font


func _ready() -> void:
	is_multiplayer = Globals.is_multiplayer
	

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

func finish_intro():
	player1.disabled = false
	if is_multiplayer:
		player2.disabled = false
	LayerManager.camera_override = false
	return


func finish_animation():
	var tween = create_tween()
	tween.tween_property(LayerManager.BossIntro.get_node("Transition"),"modulate",Color(0.0,0.0,0.0,0.0),fade_time)
	await tween.finished
	LayerManager.BossIntro.visible = false
	LayerManager.BossIntro.get_node("Transition").modulate = Color(0.0,0.0,0.0,1.0)
	return
	
	


func activate(layermanager : Node, camera_in : Node, player1_in : Node, player2_in : Node):
	print("boss room activate")
	active = true
	camera = camera_in
	player1 = player1_in
	player2 = player1_in
	player1.disabled = true
	print(player1.disabled)
	print(player1)
	if is_multiplayer:
		player2 = player2_in
		player2.disabled = true
	LayerManager =layermanager
	LayerManager.BossIntro.get_node("BossName").text = boss_name
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
