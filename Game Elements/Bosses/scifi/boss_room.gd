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
	boss.boss_phase_change.connect(_on_boss_phase_change)
	boss.enemy_took_damage.connect(LayerManager._on_enemy_take_damage)
	
func _on_boss_phase_change(boss_in : Node):
	match boss_in.phase:
		0:
			pass
		1:
			if boss_type=="scifi":
				scifi_phase1_to_2()
		2:
			if boss_type=="scifi":
				scifi_phase2_to_3()
			
	
func scifi_phase1_to_2():
	boss.phase = 0
	if phase_changing:
		return
	phase_changing = true
	
	boss.hitable = false
	$Forcefield/CollisionShape2D.set_deferred("disabled", true)
	var tween = create_tween()
	tween.tween_property($Forcefield,"modulate",Color(1.0,1.0,1.0,0.0),1.0)
	await tween.finished
	update_art(2)
	boss.get_node("AnimationTree").set("parameters/conditions/idle",true)
	print(boss.get_node("AnimationTree").get("parameters/conditions/idle"))
	await get_tree().create_timer(3.0, false).timeout
	boss.get_node("CollisionShape2D").set_deferred("disabled", false)
	phase = 1
	boss.phase = 1
	Hud.show_boss_bar(healthbar_underlays[phase],healthbar_overlays[phase],boss_names[phase],boss_name_settings[phase],phase_overlay_index[phase])
	animation_change("idle")
	$Forcefield.queue_free()
	boss.current_health = boss.boss_healthpools[phase]
	boss.max_health = boss.boss_healthpools[phase]
	phase_changing = false
	boss.hitable = true

func explode_segment(child: Node2D):
	var offset = child.global_position - boss.global_position
	var distance = offset.length()

	var max_radius = 128.0
	var strength = clamp(1.0 - (distance / max_radius), 0.2, 1.0)

	var force = (offset+Vector2.UP).normalized() * strength * 200.0

	child.activate(force, Vector2(-.05, .05))

	
func scifi_phase2_to_3():
	boss.phase = 1
	if phase_changing:
		return
	phase_changing = true
	animation_change("dead")
	#Cleanup attacks and enemies
	for child in get_children():
		if child.is_in_group("enemy") and !child.is_boss:
			child.current_health = -1
			child.emit_signal("enemy_took_damage",100,child.current_health,child,Vector2(0,-1))
		if child.is_in_group("attack"):
			child.queue_free()
	#Cleanup possible laser
	var s_material = LayerManager.get_node("game_container").material
	s_material.set_shader_parameter("laser_impact_time", -2)
	
	#Explode boss
	for child in boss.get_node("Segments").get_children():
		if child.name != "GunParts" and child.name != "Rims":
			explode_segment(child)

	for child in boss.get_node("Segments/GunParts").get_children():
		explode_segment(child)

	for child in boss.get_node("Segments/Rims").get_children():
		explode_segment(child)
		
	#Disable animation system
	boss.get_node("AnimationTree").active = false
	boss.get_node("AnimationPlayer").active = false
	boss.get_node("BTPlayer").active = false
	
	
	
	
	await get_tree().create_timer(1.5, false).timeout

	boss.hitable = false
	Hud.update_bossbar(0.0)
	#Wave Attack
	var attack_inst = load("res://Game Elements/Bosses/scifi/wave_attack.tscn").instantiate()
	attack_inst.damage = 10
	attack_inst.global_position = boss.global_position
	attack_inst.c_owner = boss
	attack_inst.direction = Vector2.UP
	call_deferred("add_child",attack_inst)
	s_material.set_shader_parameter("ultimate", true)
	var tween = create_tween()
	tween.parallel().tween_property(LayerManager.hud.get_node("RootControl"),"modulate",Color(1.0,1.0,1.0,0.0),3.0)
	tween.parallel().tween_property(LayerManager.awareness_display,"modulate",Color(1.0,1.0,1.0,0.0),3.0)
	
	await get_tree().create_timer(1, false).timeout
	update_art(3)
	boss.get_node("AnimationTree").active = true
	boss.get_node("AnimationPlayer").active = true
	await get_tree().create_timer(2, false).timeout
	animation_change("idle")
	phase = 2
	boss.phase = 2
	Hud.show_boss_bar(healthbar_underlays[phase],healthbar_overlays[phase],boss_names[phase],boss_name_settings[phase],phase_overlay_index[phase])
	Hud.update_bossbar(1.0)
	await get_tree().create_timer(1, false).timeout
	boss.get_node("BTPlayer").active = true
	$Ground.visible = false
	$Filling.visible = false
	$Ground_Cyber.visible = true
	$ColorRect.visible = true
	$Filling_Cyber.visible = true

	await get_tree().create_timer(3, false).timeout
	var tween2 = create_tween()
	
	#Fully bring back boss
	phase_changing = false
	boss.current_health = boss.boss_healthpools[phase]
	boss.max_health = boss.boss_healthpools[phase]
	tween2.parallel().tween_property(LayerManager.hud.get_node("RootControl"),"modulate",Color(1.0,1.0,1.0,1.0),1.0)
	tween2.parallel().tween_property(LayerManager.awareness_display,"modulate",Color(1.0,1.0,1.0,1.0),1.0)

	boss.hitable = true
	
	var playback = boss.get_node("AnimationTree").get("parameters/playback")
	playback.travel("idle")
	await get_tree().create_timer(4, false).timeout
	s_material.set_shader_parameter("ultimate", false)
	print("finsihed phase change")
	print(phase)
	print(boss.phase)
	print(boss.current_health)
	

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
	scifi_binary_process(delta)
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


func boss_signal(sig :String, value1, value2):
	match sig:
		"spawn_enemies":
			if is_multiplayer:
				Spawner.spawn_enemies([player1,player2], self, LayerManager.placable_cells.duplicate(),LayerManager.room_instance_data,LayerManager,true,value1,value2)
			else:
				Spawner.spawn_enemies([player1], self, LayerManager.placable_cells.duplicate(),LayerManager.room_instance_data,LayerManager,true,value1,value2)
			var enemies : Array[Node]= []
			var positions : Array[Vector2] = []
			positions.append(player1.global_position)
			if is_multiplayer:
				positions.append(player2.global_position)
			for child in get_children():
				if child.is_in_group("enemy"):
					enemies.append(child)
				
					var board = child.get_node("BTPlayer").blackboard
					if board.get_var("state") == "spawning":
						continue
					if phase < 2 and !child.is_boss:
						child.global_position.y = max(child.global_position.y,-80)
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


func _on_enemy_take_damage(_damage : int,current_health : int,_enemy : Node, direction = Vector2(0,-1)) -> void:
	var boss_health1 = boss.current_health
	if boss_type =="scifi" and current_health <= 0 and phase == 0:
		if is_multiplayer:
			if .5 < randf():
				boss.take_damage(10,player1,direction)
			else:
				boss.take_damage(10,player2,direction)
		else:
			boss.take_damage(10,player1,direction)
		pass
	var boss_health2 = boss.current_health
	if boss_type == "scifi":
		var mini_phase1 = int(( boss_health1 / float(boss.max_health) ) * 3)
		var mini_phase2 = int(( boss_health2 / float(boss.max_health) ) * 3)
		print("P1: "+str(mini_phase1)+"P2: "+str(mini_phase2))
		if  mini_phase1 != 3 and mini_phase1 >  mini_phase2:
			scifi_phase1_middles()
		
var middle_active : int = 0
func scifi_phase1_middles():
	var attack_inst = load("res://Game Elements/Bosses/scifi/wave_attack.tscn").instantiate()
	attack_inst.global_position = boss.global_position
	attack_inst.c_owner = boss
	attack_inst.direction = Vector2.UP
	call_deferred("add_child",attack_inst)
	var bt_player = boss.get_node("BTPlayer")
	var board = bt_player.blackboard
	if board:
		board.set_var("attack_mode", "DISABLED")
	middle_active +=1
	# Disable the forcefield collision
	$Forcefield/CollisionShape2D.set_deferred("disabled", true)
	# Enable the boss collision
	boss.get_node("CollisionShape2D").set_deferred("disabled", false)
	var tween = create_tween()
	tween.tween_property($Forcefield,"modulate",Color(1.0,1.0,1.0,0.0),1.0)
	await get_tree().create_timer(8.0, false).timeout
	if middle_active <= 1:
		# Disable the boss collision
		boss.get_node("CollisionShape2D").set_deferred("disabled", true)
		# Enable the forcefield collision
		$Forcefield/CollisionShape2D.set_deferred("disabled", false)
	var tween2 = create_tween()
	tween2.tween_property($Forcefield,"modulate",Color(1.0,1.0,1.0,1.0),1.0)
	if board:
		board.set_var("attack_mode", "NONE")
	middle_active -=1
	
func boss_animation():
	var eye = boss.get_node("Segments/Eye/3")
	var board = boss.get_node("BTPlayer").blackboard
	var is_purple = board.get_var("player_idx") as bool
	var track_position = player1.global_position if is_purple else player2.global_position
	eye.position = (track_position-eye.global_position).normalized()*6
	match animation:
		"idle":
			boss.get_node("Segments").z_index=0
			var count = 0
			for child in boss.get_node("Segments/Rims").get_children():
				count+=1
				var angle = 45 *count+lifetime*20
				var new_position =Vector2.UP.rotated(deg_to_rad(angle)) * (rim_distance +sin(lifetime*count/3)*2)
				child.get_node("RimVis").global_position = new_position + boss.global_position
				child.get_node("RimVis").global_rotation = deg_to_rad(angle - 224)
		"basic_laser":
			var gun = boss.get_node("Segments/GunParts")
			gun.rotation = lerp_angle(gun.rotation, (track_position - boss.global_position).angle(), 0.03)
		"laser_ultra":
			var count = 0
			for child in boss.get_node("Segments/Rims").get_children():
				count+=1
				var angle = 45 *count+rad_to_deg(current_rotation)
				var new_position =Vector2.UP.rotated(deg_to_rad(angle)) * (rim_distance +sin(lifetime*count/3)*2)
				child.get_node("RimVis").global_position = new_position + boss.global_position
				child.get_node("RimVis").global_rotation = deg_to_rad(angle - 224)
		"binary_lunge":
			var count = 0
			for child in boss.get_node("Segments/Rims").get_children():
				count+=1
				var angle = 45 *count+lifetime*20
				var new_position =Vector2.UP.rotated(deg_to_rad(angle)) * (rim_distance)
				child.get_node("RimVis").global_position = new_position + boss.global_position
				child.get_node("RimVis").global_rotation = deg_to_rad(angle - 224)

var resetting = 0

func animation_change(new_anim: String) -> void:
	animation_reset()
	animation = new_anim
	if boss:
		boss.animation = new_anim

func animation_reset() -> void:
	if boss:
		var rims = boss.get_node("Segments/Rims")
		for rim in rims.get_children():
			var rimvis = rim.get_node("RimVis")
			rimvis.position = Vector2.ZERO
			rimvis.rotation = 0

var current_rotation = 0.0
func scifi_laser_attack(num_lasers):
	if !laser_legal():
		return
	print("LASEEERRRRRRR")
	print(num_lasers)
	if num_lasers > 1:
		animation_change("laser_ultra")
	else:
		animation_change("basic_laser")
	if num_lasers == 1:
		boss.get_node("AnimationTree").set("parameters/conditions/laser_basic",true)
		await get_tree().create_timer(3.0, false).timeout
	boss.get_node("AnimationTree").set("parameters/conditions/laser_basic",false)
	if !laser_legal():
		return
	
	var gun = boss.get_node("Segments/GunParts")
	var board = boss.get_node("BTPlayer").blackboard
	var is_purple = board.get_var("player_idx") as bool
	var track_position = player1.global_position if is_purple else player2.global_position
	var inst = load("res://Game Elements/Bosses/scifi/singul_laser_attack.tscn").instantiate()
	
	inst.direction = Vector2.RIGHT.rotated(lerp_angle(gun.rotation, (track_position - boss.global_position).angle(), 0.03))
	
	inst.global_position = boss.global_position
	inst.c_owner= boss
	inst.laser_rotation = false
	inst.num_lasers = num_lasers
	inst.laser_wave_width = 2048
	inst.lifespan = 12.1
	call_deferred("add_child",inst)
	
	
	# Optional longer idle wait, also using frame loop
	var idle_timer = Timer.new()
	idle_timer.wait_time = 12.0
	idle_timer.one_shot = true
	add_child(idle_timer)
	idle_timer.start()
	
	var angular_velocity := 0.0
	current_rotation = 0
	var max_speed := .5        # radians per second (tweak)
	var accel_time := 2.0
	var hold_time := 8.0
	var decel_time := 2.0

	var total_time := 0.0
	
	
	while idle_timer.time_left > 0 and laser_legal():
		if num_lasers == 1:
			track_position = player1.global_position if is_purple else player2.global_position
			if inst:
				# Update laser direction
				inst.direction = Vector2.RIGHT.rotated(gun.rotation)
				inst.l_rotation = rad_to_deg(gun.rotation)
				inst._update_laser_collision_shapes()
				#Update shader
				var s_material = LayerManager.get_node("game_container").material
				s_material.set_shader_parameter("laser_rotation",inst.l_rotation)
		else:
			var delta := get_process_delta_time()
			total_time += delta

			# Phase 1: Accelerate
			if total_time < accel_time:
				var t := total_time / accel_time
				angular_velocity = lerp(0.0, max_speed, t)

			# Phase 2: Constant speed
			elif total_time < accel_time + hold_time:
				angular_velocity = max_speed

			# Phase 3: Decelerate
			elif total_time < accel_time + hold_time + decel_time:
				var t := (total_time - accel_time - hold_time) / decel_time
				angular_velocity = lerp(max_speed, 0.0, t)

			# Done
			else:
				angular_velocity = 0.0

			if inst:
				# Apply rotation
				current_rotation += angular_velocity * delta
				inst.l_rotation = rad_to_deg(current_rotation)
				inst._update_laser_collision_shapes()
				#Update shader
				var s_material = LayerManager.get_node("game_container").material
				s_material.set_shader_parameter("laser_rotation",inst.l_rotation)
			
		if get_tree():
			await get_tree().create_timer(0.0, false).timeout
	if inst and is_instance_valid(inst):
		inst.queue_free()
	if animation == "basic_laser" or animation =="laser_ultra":
		animation_change("idle")
	




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

func scifi_binary_attack():
	animation_change("binary_lunge")
	tracked_player_pos = _get_player_position()
	attack_direct = 1
	attack_cooldown = 1.2
	melee_phase = MeleePhase.SHRINK
	melee_timer = 0.0

	melee_tween = create_tween()
	melee_tween.tween_property(self, "rim_distance", 16, 0.5)
	

func scifi_binary_process(delta : float):
	if melee_phase ==  MeleePhase.NONE:
		return
	match melee_phase:
		MeleePhase.SHRINK:
			# Track the player
			tracked_player_pos = tracked_player_pos.lerp(
				tracked_player.global_position,
				1.0 - exp(-track_strength * delta)
			)

			# Wait for tween to finish
			if !melee_tween.is_running():
				melee_phase = MeleePhase.LUNGE
				melee_timer = 0.0
				boss.set_collision_layer_value(3, false)
				boss.set_collision_mask_value(3, false)
				boss.set_collision_mask_value(2, false)

		MeleePhase.LUNGE:
			# Compute target on first frame
			if melee_timer == 0.0:
				var movement_vector = tracked_player_pos - boss.global_position
				if movement_vector.length() < 32:
					movement_vector = movement_vector.normalized() * 32
				target_vector = movement_vector.normalized() * movement_vector.length() * 1.5
				attack = load("res://Game Elements/Bosses/scifi/singul_binary_lunge.tscn").instantiate()
	
				attack.direction = target_vector.normalized()
				attack.c_owner= boss
				boss.call_deferred("add_child",attack)

			melee_timer += delta
			var t = delta / melee_duration
			lunge_velocity = target_vector * t * attack_direct * 60
			boss.apply_velocity(lunge_velocity)

			if melee_timer >= melee_duration:
				melee_phase = MeleePhase.DECEL

		MeleePhase.DECEL:
			lunge_velocity = lunge_velocity.move_toward(Vector2.ZERO, friction * delta * 100)
			boss.apply_velocity(lunge_velocity)
			if lunge_velocity.length() <= 5.0:
				boss.apply_velocity(Vector2.ZERO)
				if attack:
					attack.queue_free()
				melee_phase = MeleePhase.EXPAND
				melee_timer = -randf_range(0,2)
				melee_tween = create_tween()
				melee_tween.tween_property(self, "rim_distance", 32, 1.0)
				boss.set_collision_layer_value(3, true)
				boss.set_collision_mask_value(3, true)
				boss.set_collision_mask_value(2, true)
		MeleePhase.EXPAND:
			melee_timer += delta
			if melee_timer >= .8:
				melee_phase = MeleePhase.NONE
				animation_change("idle")
	
	
func laser_legal():
	if phase_changing:
		return false
	return true
	
	
	
func update_art(p_in : int):
	randomize()
	for child in boss.get_node("Segments").get_children():
		if child.name != "GunParts" and child.name != "Rims":
			child.material.set_shader_parameter("phase",p_in)
			child.material.set_shader_parameter("time_offset",Time.get_ticks_msec() / 1000.0+randf_range(1,1.5))

	for child in boss.get_node("Segments/GunParts").get_children():
		child.material.set_shader_parameter("phase",p_in)
		child.material.set_shader_parameter("time_offset",Time.get_ticks_msec() / 1000.0+randf_range(1,1.5))

	for child in boss.get_node("Segments/Rims").get_children():
		child.get_node("RimVis").material.set_shader_parameter("phase",p_in)
		child.get_node("RimVis").material.set_shader_parameter("time_offset",Time.get_ticks_msec() / 1000.0+randf_range(1,1.5))
	

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
