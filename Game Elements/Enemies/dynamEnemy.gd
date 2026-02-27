class_name DynamEnemy
extends CharacterBody2D
@export var max_health: float = 10.0
@export var display_damage: bool =true
@export var hit_range: int = 64
@export var agro_distance: float = 150.0
@export var enemy_type : String = ""
@export var displays : Array[NodePath] = []
@export var min_timefabric = 10
@export var max_timefabric = 20
@export var can_sprint : bool = false
@export var min_sprint_time : float = 1.0
@export var max_sprint_time : float = 3.0
@export var min_sprint_cooldown : float = 3.0
@export var max_sprint_cooldown : float = 6.0
@export var sprint_multiplier : float = 2.0
var current_health: float = 10.0
@export var move_speed: float = 70
@onready var current_dmg_time: float = 0.0
@onready var in_instant_trap: bool = false
var damage_direction = Vector2(0,-1)
var sprint_timer : float = 0.0
var sprint_cool : float = 0.0
var display_pathways = false
var debug_menu = false
var debug_mode = false
var look_direction : Vector2 = Vector2(0,1)
@export var weapon_cooldowns : Array[float] = []
var last_hitter : Node = null
var exploded : float = 0

@export var hitable : bool = true
@export var is_boss : bool = false
@export var boss_phases : int = 0
@export var boss_healthpools : Array[float] = []
@export var grass_displacement_size = .5

var phase = 0
@onready var i_frames : int = 0
var weapon = null
var effects : Array[Effect] = []
var knockback_velocity : Vector2 = Vector2.ZERO
@export var knockback_decay : float = .90
var LayerManager : Node


var attacks = [preload("res://Game Elements/Attacks/bad_bolt.tscn"),preload("res://Game Elements/Attacks/robot_melee.tscn")]
signal attack_requested(new_attack : PackedScene, t_position : Vector2, t_direction : Vector2, damage_boost : float)

signal enemy_took_damage(damage : float,current_health : float,c_node : Node, direction : Vector2)
signal boss_phase_change(boss : Node)


func _input(event):
	if debug_menu and event.is_action_pressed("display_paths"):
		display_pathways = !display_pathways

func handle_attack(target_position: Vector2):
	var attack_direction = (target_position - global_position).normalized()
	var attack_position = attack_direction * 0		 + global_position
	if enemy_type=="robot":
		if self and !self.is_queued_for_deletion():
			weapon.request_attacks(attack_direction,global_position,self)
		return
	request_attack(attacks[0], attack_position, attack_direction)

func request_attack(t_attack: PackedScene, attack_position: Vector2, attack_direction: Vector2):
	var instance = t_attack.instantiate()
	instance.global_position = attack_position
	instance.direction = attack_direction
	instance.c_owner = self
	get_parent().add_child(instance)
	emit_signal("attack_requested", t_attack, attack_position, attack_direction)
# import like, takes damage or something like that

func load_settings():
	if Globals.config_safe:
		debug_mode = Globals.config.get_value("debug", "enabled", false)
	

func _ready():
	if is_boss:
		current_health = boss_healthpools[phase]
		max_health = boss_healthpools[phase]
	LayerManager = get_tree().get_root().get_node("LayerManager")
	if get_node_or_null("AnimationPlayer") and get_node("AnimationPlayer").has_animation("idle"):
		$AnimationPlayer.play("idle")
	if enemy_type=="robot":
		weapon = Weapon.create_weapon("res://Game Elements/Weapons/RobotMelee.tres",self)
	current_health = max_health
	add_to_group("enemy") #TODO might not be needed anymore. I added a global group and just put the scenes in that group
	load_settings()
	Globals.config_changed.connect(load_settings)

#need this for flipping the sprite movement
func update_flip():
	if enemy_type=="robot":
		return
	var sprite2d=get_node_or_null("Sprite2D")
	if sprite2d: 
		sprite2d.flip_h = look_direction.x < 0

func move(target_pos: Vector2, _delta: float): 
	look_direction = (target_pos - global_position).normalized()
	
	var target_velocity = look_direction * move_speed
	velocity = velocity.lerp(target_velocity, 0.05)
	
	update_flip()
	
	move_and_slide()
	
func apply_velocity(vel : Vector2):
	velocity=vel
	move_and_slide()
	
func sprint(start : bool):
	if !can_sprint:
		return
	if !start and sprint_timer > 0.0:
		if get_node_or_null("AnimationPlayer") and get_node("AnimationPlayer").has_animation("move"):
			$AnimationPlayer.play("move")
		sprint_cool = randf_range(min_sprint_cooldown,max_sprint_cooldown)
		move_speed /=sprint_multiplier
		sprint_timer=0.0
	else:
		if sprint_timer == 0.0 and  sprint_cool == 0.0:
			if get_node_or_null("AnimationPlayer") and get_node("AnimationPlayer").has_animation("sprint"):
				$AnimationPlayer.play("sprint")
			move_speed *=sprint_multiplier
			sprint_timer = randf_range(min_sprint_time,max_sprint_time)

func _physics_process(_delta: float) -> void:
	
	if knockback_velocity != Vector2.ZERO and knockback_decay > 0.0: 
		var temp_velocity = velocity
		velocity = knockback_velocity
		move_and_slide()
		velocity = temp_velocity
		# Gradually reduce knockback over time
		knockback_velocity = knockback_velocity * knockback_decay
var last_phase
func _process(delta):
	#Boss stuff
	last_phase = phase
	#
	if sprint_timer!=0.0 and max(0.0,sprint_timer-delta)==0.0:
		sprint(false)
	sprint_timer = max(0.0,sprint_timer-delta)
	if sprint_timer ==0.0:
		sprint_cool = max(0.0,sprint_cool-delta)
	if enemy_type=="robot":
		_robot_process()
	if(i_frames > 0):
		i_frames -= 1
	for i in range(weapon_cooldowns.size()):
		weapon_cooldowns[i]-=delta
		
	#Trap stuff
	check_traps(delta)
	
	var idx = 0
	for effect in effects:
		effect.tick(delta,self)
		if effect.cooldown == 0:
			effects.remove_at(idx)
		idx +=1
		
	#Trap stuff
	check_traps(delta)
	check_liquids(delta)
	
	if debug_mode:
		queue_redraw()
	

func _robot_process():
	var dir = look_direction
	var block : int= $RobotBrain.anim_frame / 10 * 10
	var offset : int= $RobotBrain.anim_frame % 10

	if abs(dir.y) > abs(dir.x): # Vertical
		if dir.y < 0:# (0, -Y) → 5–9
			offset += 5
	else:# Horizontal
		# Horizontal blocks start at 220
		block +=220
		if dir.x > 0:# (+X, 0) → 5–9
			offset += 5
	$RobotBrain.set_frame(block + offset)


func take_damage(damage : float, dmg_owner : Node, direction = Vector2(0,-1), attack_body : Node = null, attack_i_frames : int = 0,creates_indicators : bool = true):
	if !hitable:
		return
	if current_health< 0.0:
		return
	if(i_frames > 0):
		return
	i_frames = attack_i_frames
	if dmg_owner:
		check_agro(dmg_owner)
	if enemy_type=="binary_bot":
		$Core.damage_glyphs()
	if current_health >= 0.0 and display_damage and creates_indicators:
		LayerManager._damage_indicator(damage, dmg_owner,direction, attack_body,self)
	if dmg_owner != null:
		last_hitter = dmg_owner
	_check_on_hit_remnants(dmg_owner, attack_body)
	
	if dmg_owner != null and dmg_owner.is_in_group("player"):
		if attack_body and !attack_body.combod:
			attack_body.combod = true
			dmg_owner.combo(attack_body.is_purple)
		dmg_owner.hit_enemy(attack_body,self)
	if attack_body:
		match attack_body.attack_type:
			"laser":
				knockback_velocity = Vector2.UP.rotated(attack_body.rotation+PI/2) * attack_body.knockback_force
			"forcefield":
				knockback_velocity = (global_position-attack_body.global_position).normalized() * attack_body.knockback_force
			"crowbar_explosion":
				knockback_velocity = (global_position-attack_body.global_position).normalized() * attack_body.knockback_force
			"ls_melee":
				knockback_velocity = (global_position-attack_body.global_position).normalized() * attack_body.knockback_force
			_:
				knockback_velocity = attack_body.direction * attack_body.knockback_force
	current_health -= damage
	if is_boss:
		LayerManager.hud.update_bossbar(clamp(current_health/max_health,0.0,1.0))
		if current_health <= 0.0 and phase != boss_phases - 1:
			if phase == last_phase:
				phase+=1
				if phase < boss_phases:
					emit_signal("boss_phase_change",self)
					return
			return
		if current_health <= 0.0:
			for child in get_parent().get_children():
				if child.is_in_group("enemy") and !child.is_boss:
					child.current_health = -1.0
					child.emit_signal("enemy_took_damage",100.0,child.current_health,child,Vector2(0,-1))
				
	if current_health < 0.0:
			
		for effect in effects:
			effect.lost(self)
		
		if  enemy_type == "laser_e":
			var bt_player = get_node("BTPlayer")
			var board = bt_player.blackboard
			if board:
				board.set_var("kill_laser", true)
				board.set_var("kill_damage", damage)
				board.set_var("kill_direction", direction)
			return
		if dmg_owner.is_in_group("player"):
			dmg_owner.kill_enemy(self)
	emit_signal("enemy_took_damage",damage,current_health,self,direction)

func check_agro(dmg_owner : Node):
	if dmg_owner != null && dmg_owner.is_in_group("player"):
		if get_node_or_null("BTPlayer") == null:
			return
		var board = get_node("BTPlayer").blackboard
		if board.get_var("state") == "spawning":
			return
		var positions = board.get_var("player_positions")
		var distances_squared = []
		for pos in positions: 
			distances_squared.append(global_position.distance_squared_to(pos))
		var i = 0
		if distances_squared.size()>1 and distances_squared[1]<distances_squared[0]:
			i= 1
		board.set_var("target_pos", dmg_owner.global_position)
		board.set_var("player_idx", i)
		board.set_var("state", "agro")


func _check_on_hit_remnants(dmg_owner: Node, attack_body: Node):
	if dmg_owner != null and dmg_owner.is_in_group("player"):
		var remnants : Array[Remnant] = []
		if dmg_owner.is_purple:
			remnants = get_tree().get_root().get_node("LayerManager").player_1_remnants
		else:
			remnants = get_tree().get_root().get_node("LayerManager").player_2_remnants
		var pyromancer = load("res://Game Elements/Remnants/pyromancer.tres")
		var winter = load("res://Game Elements/Remnants/winters_embrace.tres")
		var hydromancer = load("res://Game Elements/Remnants/hydromancer.tres")
		var effect : Effect
		exploded = 0
		for rem in remnants:
			match rem.remnant_name:
				winter.remnant_name:
					effect = load("res://Game Elements/Effects/winter_freeze.tres").duplicate(true)
					effect.cooldown = rem.variable_2_values[rem.rank-1]
					effect.value1 =  rem.variable_1_values[rem.rank-1]
					effect.gained(self)
					effects.append(effect)
				pyromancer.remnant_name:
					exploded = rem.variable_2_values[rem.rank-1]
				hydromancer.remnant_name:
					apply_hydromancer(rem, attack_body)
				_:
					pass

func apply_hydromancer(rem : Remnant, attack_body : Node):
	var effect : Effect
	match attack_body.last_liquid:
		Globals.Liquid.Water:
			for i in range(rem.rank * 8):
				effect = load("res://Game Elements/Effects/slow_down.tres").duplicate()
				effect.cooldown = rem.rank
				effect.value1 = 0.023
				effect.gained(self)
				effects.append(effect)
		Globals.Liquid.Lava:
			for i in range(1, rem.rank + 1):
				effect = load("res://Game Elements/Effects/burn.tres").duplicate()
				effect.cooldown = i
				effect.value1 = 2
				effect.gained(self)
				effects.append(effect)
		_:
			pass
		

func check_traps(delta):
	var tile_pos = Vector2i(int(floor(global_position.x / 16)),int(floor(global_position.y / 16)))
	if tile_pos in LayerManager.trap_cells:
		var tile_data = LayerManager.return_trap_layer(tile_pos).get_cell_tile_data(tile_pos)
		if tile_data:
			var dmg = tile_data.get_custom_data("trap_instant")
			#Instant trap
			if dmg and !in_instant_trap:
				take_damage(dmg, null)
				in_instant_trap = true
			if !dmg:
				in_instant_trap = false
			#Ongoing trap
			if tile_data.get_custom_data("trap_ongoing"):
				current_dmg_time += delta
				if current_dmg_time >= tile_data.get_custom_data("trap_ongoing_seconds"):
					current_dmg_time -= tile_data.get_custom_data("trap_ongoing_seconds")
					take_damage(tile_data.get_custom_data("trap_ongoing_dmg"), null)
			else:
				current_dmg_time = 0
		else:
			current_dmg_time = 0
			in_instant_trap = false
	else:
		current_dmg_time = 0
		in_instant_trap = false

func check_liquids(delta):
	if enemy_type == "laser_e":
		return
	var tile_pos = Vector2i(int(floor(global_position.x / 16)),int(floor(global_position.y / 16)))
	if tile_pos in LayerManager.liquid_cells[0]:
		var tile_data = LayerManager.return_liquid_layer(tile_pos).get_cell_tile_data(tile_pos)
		if tile_data:
			var type = tile_data.get_custom_data("liquid")
			match type:
				Globals.Liquid.Water:
					var effect = load("res://Game Elements/Effects/slow_down.tres").duplicate(true)
					effect.cooldown = 20*delta
					effect.value1 = 0.023
					effect.gained(self)
					effects.append(effect)
				Globals.Liquid.Conveyer:
					position+=tile_data.get_custom_data("direction").normalized() *delta * 32
				Globals.Liquid.Glitch:
					_glitch_move()

func _glitch_move() -> void:
	var ground_cells = LayerManager.room_instance.get_node("Ground").get_used_cells()
	var move_dir_l = velocity.normalized() *16
	var move_dir_r = velocity.normalized() *16
	var check_pos_r = Vector2i(((position + move_dir_r)/16).floor())
	var check_pos_l = Vector2i(((position + move_dir_l)/16).floor())
	var attempts = 0
	var max_attempts = 36 # prevent infinite loops
	while check_pos_r not in ground_cells and check_pos_l not in ground_cells and attempts < max_attempts:
		move_dir_r = move_dir_r.rotated(deg_to_rad(-5))
		move_dir_l = move_dir_l.rotated(deg_to_rad(5))
		check_pos_l = Vector2i(((position + move_dir_l)/16).floor())
		check_pos_r = Vector2i(((position + move_dir_r)/16).floor())
		attempts += 1
	if velocity.length() < .1:
		return
	var move_dir =move_dir_r
	if check_pos_l in ground_cells:
		move_dir =move_dir_l
	position+=move_dir/2.0
	var saved_position = position
	var saved_velocity = velocity
	var position_variance = 16
	var hue_variance = .08
	var color1 = shift_hue(Color(0.0, 0.867, 0.318, 1.0),randf_range(-hue_variance,hue_variance))
	var color2 = shift_hue(Color(0.0, 0.116, 0.014, 1.0),randf_range(-hue_variance,hue_variance))
	position+= Vector2(randf_range(-position_variance,position_variance),randf_range(-position_variance,position_variance))
	Spawner.spawn_after_image(self,LayerManager,color1,color1,0.5,1.0,1+randf_range(-.1,.1),.75)
	position = saved_position
	velocity=move_dir/2.0
	move_and_slide()
	saved_position = position
	position+= Vector2(randf_range(-position_variance,position_variance),randf_range(-position_variance,position_variance))
	Spawner.spawn_after_image(self,LayerManager,color2,color2,0.5,1.0,1+randf_range(-.1,.1),.75)
	position = saved_position
	move_and_slide()
	velocity = saved_velocity


func shift_hue(color: Color, amount: float) -> Color:
	var h = color.h + amount
	h = fposmod(h, 1.0) # wrap hue to 0–1
	return Color.from_hsv(h, color.s, color.v, color.a)



func boss_signal(sig :String, value1, value2):
	if is_boss:
		get_parent().boss_signal(sig,value1,value2)

func clear_effects():
	for effect in effects:
		effect.lost(self)
var animation = ""

func _draw():
	if !debug_mode:
		return
	# Get path from blackboard if behavior tree exists
	if not display_pathways:
		return
	
	if not has_node("BTPlayer"):
		return
	
	var bt_player = get_node("BTPlayer")
	if not bt_player.blackboard.has_var("path"):
		return
		
	var path = bt_player.blackboard.get_var("path", [])
	if path.is_empty():
		return
	# Draw lines between waypoints
	for i in range(path.size() - 1):
		var start = to_local(path[i])
		var end = to_local(path[i + 1])
		draw_line(start, end, Color.YELLOW, 2.0)
	
	# Draw circles at each waypoint
	for waypoint in path:
		draw_circle(to_local(waypoint), 4, Color.RED)
		
	# Draw larger circle at current target
	var waypoint_index = bt_player.blackboard.get_var("waypoint_index", 0)
	if waypoint_index < path.size():
		draw_circle(to_local(path[waypoint_index]), 6, Color.GREEN)
