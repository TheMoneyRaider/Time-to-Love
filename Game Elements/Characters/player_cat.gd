extends CharacterBody2D
var mouse_sensitivity: float = 1.0

@export var base_move_speed: float = 100
var move_speed: float
@export var max_health: float = 10.0 #TEST
@export var current_health: float = 10.0 #TEST
@onready var current_dmg_time: float = 0.0
@onready var current_liquid_time: float = 0.0
@onready var in_instant_trap: bool = false
@onready var disabled_countdown : int = 0
@onready var i_frames : int = 0

@export var state_machine : LimboHSM

#States
@onready var idle_state = $LimboHSM/Idle
@onready var move_state = $LimboHSM/Move
@onready var attack_state = $LimboHSM/Attack
@onready var swap_state = $LimboHSM/Swap

@export var starting_direction : Vector2 =  Vector2(0,1)
@export var grass_displacement_size = .5

@onready var tether_line = $Line2D
@onready var crosshair = $Crosshair
@onready var crosshair_sprite = $Crosshair/Sprite2D

@onready var weapon_node = $WeaponSprite

@onready var sprite = $Sprite2D

@onready var purple_crosshair = preload("res://art/purple_crosshair_with_shadow.png")
@onready var orange_crosshair = preload("res://art/orange_crosshair_with_shadow.png")
@onready var purple_texture = preload("res://art/Sprout Lands - Sprites - Basic pack/Characters/purple_spritesheet.png")
@onready var orange_texture = preload("res://art/Sprout Lands - Sprites - Basic pack/Characters/orange_spritesheet.png")
var damage_multiplier = 1.0
var effect_stacks : Array[int] = []
var effect_particles : Array
var other_player
var disabled = false
var current_room : Globals.RoomType
var lawman_aura : Node
var in_combat = 0
var time_since_last_hit = 0

var tether_momentum = Vector2.ZERO
var is_tethered = false
var tether_gradient
var tether_width_curve

var damage_resistance : float = 0.0
var is_multiplayer = false
var input_device = "-1"
var input_direction : Vector2 = Vector2.ZERO
var invulnerable : bool = false
var debug_menu : bool = false

var effects : Array[Effect] = []
var last_liquid : Globals.Liquid = Globals.Liquid.Buffer

var assist_enabled : bool = true
var forcefield_active : bool = false

var footstep_timer: float = 0.0
var footstep_interval: float = 0.25
var footstep_sounds = [
	preload("res://Game Elements/sfx/player/walk1.ogg"),
	preload("res://Game Elements/sfx/player/walk2.ogg"),
	preload("res://Game Elements/sfx/player/walk3.ogg"),
	preload("res://Game Elements/sfx/player/walk4.ogg"),
	preload("res://Game Elements/sfx/player/walk5.ogg")
]


#The scripts for loading default values into the attack
#The list of attacks for playercharacter
var weapons = [Weapon.create_weapon("res://Game Elements/Weapons/Crossbow.tres",self),Weapon.create_weapon("res://Game Elements/Weapons/Laser Sword.tres",self)]
var attacks = [preload("res://Game Elements/Attacks/bolt.tscn"),preload("res://Game Elements/Attacks/smash.tscn")]
var revive = preload("res://Game Elements/Attacks/death_mark.tscn")
var cooldowns = [0,0]
var is_purple = true
var mancermancer_values = [0,0]

signal attack_requested(new_attack : PackedScene, t_position : Vector2, t_direction : Vector2, damage_boost : float)
signal player_took_damage(damage : float, c_health : float, c_node : Node)
signal activate(player_node : Node)
signal special(player_node : Node)
signal swapped_color(player_node : Node)
signal max_health_changed(new_max_health : float, new_current_health : float, player_node : Node)
signal special_changed(is_purple : int, new_progress : int)
signal special_reset(is_purple : int)

var LayerManager: Node
var debug_mode : bool = false
var deflect_cooldown : float = 0.0
func _ready():
	effect_stacks.resize(9)
	effect_stacks.fill(0)
	effect_particles.resize(9)
	effect_particles.fill(null)
	if Input.get_connected_joypads().size() == 0:
		Globals.player1_input = "key"
		Globals.player2_input = "0"
	else:
		Globals.player1_input = Globals.config.get_value("inputs","player1_input", "key")
		Globals.player2_input = Globals.config.get_value("inputs","player2_input", "0")
	debug_mode = Globals.config.get_value("debug", 'enabled', false)
	LayerManager = get_tree().get_root().get_node("LayerManager")
	if !is_multiplayer:
		#Create Fake Player
		other_player = preload("res://Game Elements/Characters/fake_player.tscn").instantiate()
		get_parent().add_child(other_player)
		other_player.disable()
	
	$Forcefield/AnimationPlayer2.play("fritz")
	move_speed = base_move_speed
	_initialize_state_machine()
	update_animation_parameters(starting_direction)
	add_to_group("player")
	debug_menu = Globals.config.get_value("debug", "enabled", false)
	set_weapon_dr(weapons[is_purple as int])
	set_weapon_sprite(weapons[is_purple as int],weapon_node)
	if is_multiplayer:
		tether_gradient = tether_line.gradient
		tether_width_curve = tether_line.width_curve
		tether_line.gradient = null			
	hide_forcefield(0.0)
	
	special_changed.connect(check_tortoise)


func hide_forcefield(interp_time : float):
	forcefield_active = false
	if interp_time == 0.0:
		$Forcefield/CollisionShape2D.disabled  =true
		$Forcefield/Forcefield.modulate.a = 0.0
		return
	damage_resistance -=.5
	$Forcefield/CollisionShape2D.disabled  =true
	create_tween().tween_property($Forcefield/Forcefield,"modulate",Color(1.0,1.0,1.0,0.0),interp_time)

func show_forcefield(interp_time : float):
	forcefield_active = true
	if interp_time == 0.0:
		$Forcefield/CollisionShape2D.disabled  =false
		$Forcefield/Forcefield.modulate.a = 1.0
		return
	damage_resistance +=.5
	$Forcefield/CollisionShape2D.disabled  =false
	$Forcefield/Forcefield.modulate.a = 0.0
	create_tween().tween_property($Forcefield/Forcefield,"modulate",Color(1.0,1.0,1.0,1.0),interp_time)
	

func update_input_device(in_dev : String):
	input_device = in_dev
	crosshair.player_input_device = input_device
	if(input_device == "key"):
		assist_enabled = false


func _initialize_state_machine():
	#Define State transitions
	state_machine.add_transition(idle_state,move_state, "to_move")
	state_machine.add_transition(move_state,idle_state, "to_idle")
	
	state_machine.initial_state = idle_state
	state_machine.initialize(self)
	state_machine.set_active(true)

func apply_movement(_delta):
	velocity = input_direction * move_speed

var _debug_wedges : Array = []   # [{from, left, right, hit}]
func _draw() -> void:
	if !debug_angles:
		return

	for w in _debug_wedges:
		var from_local = to_local(w.from)
		var left_local = to_local(w.left)
		var right_local = to_local(w.right)

		var color = Color.GREEN if !w.blocked else Color.RED
		color.a = 0.2  # transparency

		var points = PackedVector2Array([
			from_local,
			left_local,
			right_local
		])

		draw_polygon(points, PackedColorArray([color, color, color]))
		
	var corrected_angle = compute_assist_angle((crosshair.position).angle(),output_angles)
	draw_line(Vector2.ZERO, (crosshair.position).normalized() * 64, Color.RED, 2.0)
	draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(corrected_angle) * 64, Color.GREEN, 2.0)

var debug_angles : bool = false
func smooth_aim_assist() -> Array[Vector2]:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	var angles: Array[Vector2] = []
	var is_boss_room := current_room == Globals.RoomType.Boss
	if !is_boss_room or assist_enabled:
		for enemy in enemies:
			var band = angular_band_circle(global_position, enemy.get_node("CollisionShape2D"))
			var blocked = false
			var to_enemy : Vector2= enemy.global_position - global_position
			var ray_length : float= to_enemy.length()
			var left_ray := Vector2(cos(band.x), sin(band.x))
			var right_ray := Vector2(cos(band.y), sin(band.y))

			var ray1 := cast_ray(global_position, left_ray, ray_length, self)
			var ray2 := cast_ray(global_position, right_ray, ray_length, self)

			if ray1 and (global_position - ray1.position).length_squared() <= (ray_length + 4) * (ray_length + 4):
				blocked = true
			if !blocked and ray2 and (global_position - ray2.position).length_squared() <= (ray_length + 4) * (ray_length + 4):
				blocked = true

			if debug_angles:
				_debug_wedges.append({
					"from": global_position,
					"left": ray1.position if ray1 else global_position + left_ray * ray_length,
					"right": ray2.position if ray2 else global_position + right_ray * ray_length,
					"blocked": blocked
				})

			if !blocked:
				angles.append(band)

	return angles


func cast_ray(origin: Vector2, direction: Vector2, distance: float, player_node : Node) -> Dictionary:
	var query = PhysicsRayQueryParameters2D.create(origin, origin + direction * distance)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 1 << 0
	return player_node.get_world_2d().direct_space_state.intersect_ray(query)


func angular_band_circle(player_pos: Vector2, collision_shape: CollisionShape2D) -> Vector2:
	var to_shape := collision_shape.global_position - player_pos
	var center_angle := to_shape.angle()
	var shape := collision_shape.shape

	if shape is CircleShape2D:
		var distance := to_shape.length()
		if distance < shape.radius:
			return Vector2(-PI, PI)
		var half_angle := asin(shape.radius / distance)
		return Vector2(center_angle - half_angle, center_angle + half_angle)

	if shape is CapsuleShape2D:
		# radius + half-height gives the bounding reach along the capsule's axis
		var reach : float= shape.radius + shape.height * 0.5
		var distance := to_shape.length()
		if distance < reach:
			return Vector2(-PI, PI)
		var half_angle := asin(reach / distance)
		return Vector2(center_angle - half_angle, center_angle + half_angle)

	if shape is RectangleShape2D:
		var extents : Vector2= shape.extents
		var min_angle := INF
		var max_angle := -INF
		for corner in [
			Vector2(-extents.x, -extents.y),
			Vector2( extents.x, -extents.y),
			Vector2( extents.x,  extents.y),
			Vector2(-extents.x,  extents.y)
		]:
			var a := (collision_shape.to_global(corner) - player_pos).angle()
			var diff_min := wrapf(a - min_angle, -PI, PI)
			var diff_max := wrapf(a - max_angle, -PI, PI)
			if diff_min < 0: min_angle = a
			if diff_max > 0: max_angle = a

		return Vector2(min_angle, max_angle)

	return Vector2(center_angle, center_angle)

func compute_assist_angle(player_angle: float, enemy_angles: Array, band_size: float = deg_to_rad(45)) -> float:
	var is_boss_room := current_room == Globals.RoomType.Boss
	if is_boss_room or !assist_enabled:
		return player_angle
	var half_band := band_size * 0.5
	var new_angle := player_angle

	for v in enemy_angles:
		var diff := wrapf(((v.x + v.y) * 0.5) - new_angle, -PI, PI)
		if abs(diff) < half_band:
			new_angle = wrapf(new_angle + diff * (1.0 - abs(diff) / half_band), -PI, PI)

	return new_angle



var output_angles = []

		
			
func _input(event):
	if event.is_action_pressed("toggle_enemy_angles") and debug_mode:
		debug_angles = !debug_angles
		_debug_wedges.clear()
		queue_redraw()

var last_footprint_location : Vector2 = Vector2(0,0)
var footprint_left : bool = false
func _physics_process(delta):
	if disabled:
		return
	deflect_cooldown-=delta
	attraction_effect()
	if debug_angles:
		_debug_wedges.clear()
	output_angles = smooth_aim_assist()
	if debug_angles:
		queue_redraw()
	#print(move_speed)
	if(i_frames > 0):
		i_frames -= 1
	#Trap stuff
	check_traps(delta)
	#Liquid stuff
	
	var idx = 0
	for effect in effects:
		effect.tick(delta,self)
		if effect.cooldown == 0:
			effects.remove_at(idx)
		idx +=1
	var in_liquid = check_liquids(delta)
	
	#Cat input detection
	input_direction = Vector2(
		Input.get_action_strength("right_" + input_device) - Input.get_action_strength("left_" + input_device),
		Input.get_action_strength("down_" + input_device) - Input.get_action_strength("up_" + input_device)
	)
	input_direction = input_direction.normalized()
	
	update_animation_parameters(input_direction)	
	
	tether(delta)
	if is_tethered:
		if is_multiplayer:
			input_direction += (tether_momentum / move_speed) * 1.5
		else:
			input_direction += (tether_momentum / move_speed) * 5.0
	weapon_node.weapon_direction = (crosshair.position).normalized()
	#move and slide function
	if(self.process_mode != PROCESS_MODE_DISABLED and disabled_countdown <= 0):
		move_and_slide()
		if !is_tethered and last_footprint_location.distance_to(global_position) > 8 and !in_liquid:
			footprint_left=!footprint_left
			last_footprint_location=global_position
			get_node("Footprints").spawn_footprint(global_position,input_direction,footprint_left)
	
	
	if debug_menu and Input.is_action_just_pressed("toggle_invulnerability"):
		invulnerable = !invulnerable
	
	if Input.is_action_just_pressed("attack_" + input_device):
		if Input.is_action_pressed("special_" + input_device) and weapons[is_purple as int].current_special_hits >= weapons[is_purple as int].special_hits:
			weapons[is_purple as int].use_normal_attack(Vector2.RIGHT.rotated(compute_assist_angle((crosshair.position).angle(),output_angles)), global_position,self)
		else:
			handle_attack()
	if has_bandit() and Input.is_action_pressed("attack_" + input_device):
		handle_attack(true)
	if Input.is_action_just_pressed("activate_" + input_device):
		emit_signal("activate",self)
	if Input.is_action_just_pressed("special_" + input_device):
		emit_signal("special",self)
	if Input.is_action_pressed("special_" + input_device):
		effects += weapons[is_purple as int].use_special(delta,false, Vector2.RIGHT.rotated(compute_assist_angle((crosshair.position).angle(),output_angles)), global_position,self)
	elif Input.is_action_just_released("special_" + input_device):
		effects += weapons[is_purple as int].use_special(delta, true, Vector2.RIGHT.rotated(compute_assist_angle((crosshair.position).angle(),output_angles)), global_position,self)
		
	in_combat -= delta
	if(in_combat > 0):
		time_since_last_hit += delta
	
	adjust_cooldowns(delta)
	red_flash()
	if disabled_countdown >= 1:
		disabled_countdown-=1
		
	if velocity.length() > 5.0 and !disabled and !is_tethered:
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			var speed_ratio = clamp(velocity.length() / base_move_speed, 1.0, 2.5)
			footstep_timer = footstep_interval / speed_ratio
			SFXManager.play(footstep_sounds[randi() % footstep_sounds.size()],0.0,"SFX",global_position)
	else:
		footstep_timer = 0.0

func update_animation_parameters(move_input : Vector2):
	if(move_input != Vector2.ZERO):
		idle_state.move_direction = move_input
		move_state.move_direction = move_input
		

func request_attack(t_weapon : Weapon) -> float:
	weapon_node.flip_direction()
	var attack_direction = Vector2.RIGHT.rotated(compute_assist_angle((crosshair.position).angle(),output_angles))
	t_weapon.request_attacks(attack_direction,global_position,self,weapon_node.flip)
	return t_weapon.cooldown

func _check_reduction_remnants(damage_amount : float, _dmg_owner : Node):
	var remnants : Array[Remnant]
	if is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	for rem in remnants:
		if rem.active:
			match rem.remnant_name:
					_:
						pass
	return damage_amount

func _check_bulwark(damage_amount : float, _dmg_owner : Node, send_damage: bool):
	var remnants_purple : Array[Remnant]
	var remnants_orange : Array[Remnant]
	remnants_purple = LayerManager.player_1_remnants
	remnants_orange = LayerManager.player_2_remnants
	var bulk = load("res://Game Elements/Remnants/bulwark.tres")
	var purple_bulwark_rank = 0
	var orange_bulwark_rank = 0
	for rem in remnants_purple:
		if rem.remnant_name == bulk.remnant_name and rem.active:
			purple_bulwark_rank = rem.rank
	for rem in remnants_orange:
		if rem.remnant_name == bulk.remnant_name and rem.active:
			orange_bulwark_rank = rem.rank
	if(is_purple):
		if(purple_bulwark_rank != 0):
			damage_amount = damage_amount * (.9 - purple_bulwark_rank * .1)
		if(orange_bulwark_rank != 0):
			if(send_damage):
				if(is_multiplayer):
					other_player.take_damage(damage_amount, _dmg_owner, Vector2(0,-1), null, 0,true, false)
				else:
					take_damage(damage_amount * (.9 - orange_bulwark_rank * .1), _dmg_owner, Vector2(0,-1), null, 0,true, false)
	else:
		if(orange_bulwark_rank != 0):
			damage_amount = damage_amount * (.9 - orange_bulwark_rank * .1)
		if(purple_bulwark_rank != 0):
			if(send_damage):
				if(is_multiplayer):
					other_player.take_damage(damage_amount, _dmg_owner, Vector2(0,-1), null, 0,true, false)
				else:
					take_damage(damage_amount * (.9 - purple_bulwark_rank * .1), _dmg_owner, Vector2(0,-1), null, 0,true, false)
	return damage_amount

func pre_damage_trigger(damage_amount: float, _dmg_owner : Node) -> float:
	var remnants : Array[Remnant]
	if is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	var phase = preload("res://Game Elements/Remnants/body_phaser.tres")
	var invest = preload("res://Game Elements/Remnants/investment.tres")
	var emp = preload("res://Game Elements/Remnants/emp.tres")
	for rem in remnants:
		if rem.active:
			match rem.remnant_name:
				phase.remnant_name:
					var temp_move = 0
					if input_direction != Vector2.ZERO:
						temp_move = move_speed
					damage_amount *= (1.0-rem.variable_1_values[rem.rank-1]/100.0*((temp_move/base_move_speed)-1))
					damage_amount = max(0.0,damage_amount)
				invest.remnant_name:
					LayerManager.timefabric_collected-= LayerManager.timefabric_collected * (rem.variable_2_values[rem.rank-1])/100.0
					LayerManager.has_spent_timefabric = true
				emp.remnant_name:
					if _dmg_owner and _dmg_owner.is_in_group("enemy"):
						var instance = preload("res://Game Elements/Attacks/emp.tscn").instantiate()
						instance.c_owner = self
						instance.global_position = global_position
						LayerManager.room_instance.call_deferred("add_child",instance)
	return damage_amount


func post_damage_trigger(damage_amount: float, _dmg_owner : Node):
	if is_purple:
		LayerManager.hud.get_node("RootControl/Purple").trigger_pulse()
	else:
		LayerManager.hud.get_node("RootControl/Orange").trigger_pulse()
	
	
	randomize()
	var remnants : Array[Remnant]
	if is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	var cleric = preload("res://Game Elements/Remnants/cleric.tres")
	var barbarian = preload("res://Game Elements/Remnants/barbarian.tres")
	var thorns = preload("res://Game Elements/Remnants/thorns.tres")
	for rem in remnants:
		if rem.active:
			match rem.remnant_name:
				cleric.remnant_name:
					if rem.variable_1_values[rem.rank-1] > randf()*100 and current_health >= 0.0:
						var particle =  preload("res://Game Elements/Particles/heal_particles.tscn").instantiate()
						particle.position = self.position
						get_parent().add_child(particle)
						change_health(damage_amount * .01 * rem.variable_2_values[rem.rank-1])
				barbarian.remnant_name:
					for weapon in weapons:
						weapon.damage = weapon.damage * (1 + rem.variable_1_values[rem.rank-1] / 100.0)
					_reset_barb_damage(rem.variable_1_values[rem.rank-1] / 100.0,rem.variable_2_values[rem.rank-1])
				thorns.remnant_name:
					if(rem.rank == 5):
						var attack_instance = preload("res://Game Elements/Attacks/thorns_invisible.tscn").instantiate()
						attack_instance.get_node("CollisionShape2D").shape = get_camera_rect()
						attack_instance.damage = damage_amount * rem.variable_3_values[rem.rank - 1]
						attack_instance.c_owner = self
						attack_instance.global_position = self.global_position
						LayerManager.room_instance.call_deferred("add_child",attack_instance)
					else:
						var attack_instance = preload("res://Game Elements/Attacks/thorns_invisible.tscn").instantiate()
						attack_instance.damage = damage_amount * rem.variable_3_values[rem.rank - 1]
						attack_instance.scale = attack_instance.scale * ((rem.rank) / 2.0)
						attack_instance.c_owner = self
						attack_instance.global_position = self.global_position
						LayerManager.room_instance.call_deferred("add_child",attack_instance)

func get_camera_rect() -> RectangleShape2D:
	var newRectangle = RectangleShape2D.new()
	newRectangle.set_size(get_viewport_rect().size / LayerManager.camera.zoom)	
	return newRectangle

func take_damage(damage_amount : float, _dmg_owner : Node,_direction = Vector2(0,-1), attack_body : Node = null, attack_i_frames : int = 20,creates_indicators : bool = true, bulwark : bool = true):
	in_combat = 3
	if(bulwark == false || i_frames <= 0 && !invulnerable):
		time_since_last_hit = 0
		i_frames = attack_i_frames
		damage_amount *= (1.0 - damage_resistance)
		damage_amount *= (1.0 - lich_effect(false))
		
		#damage_amount = _check_reduction_remnants(damage_amount,_dmg_owner)
		SFXManager.play(preload("res://Game Elements/sfx/player/take_damage.ogg"),0.0,"SFX",global_position)
		damage_amount = _check_bulwark(damage_amount, _dmg_owner, bulwark)
		if check_drones():
			LayerManager._damage_indicator(0, _dmg_owner,_direction, attack_body,self,Color(0.0, 0.666, 0.85, 1.0))
			return
		damage_amount = pre_damage_trigger(damage_amount, _dmg_owner)		
		current_health = current_health - damage_amount
		emit_signal("player_took_damage",damage_amount,current_health,self)
		if current_health >= 0.0 and creates_indicators:
			LayerManager._damage_indicator(damage_amount, _dmg_owner,_direction, attack_body,self)
		if(current_health <= 0.0):
			if(die(true)):
				var instance = revive.instantiate()
				instance.global_position = position
				instance.c_owner = self
				LayerManager.room_instance.call_deferred("add_child",instance)
				emit_signal("attack_requested",revive, position, Vector2.ZERO, 0)
		post_damage_trigger(damage_amount,_dmg_owner)

func set_weapon_dr(weapon : Weapon):
	damage_resistance = 0.0
	match weapon.type:
		"Mace":
			damage_resistance = .1
		"Laser Sword":
			damage_resistance = .1
		"Shovel":
			damage_resistance = .1
		"Shovel":
			damage_resistance = .1
		"Fist":
			damage_resistance = .1
		_:
			damage_resistance = 0.0
	

func set_weapon_sprite(weapon : Weapon, f_weapon_node : Node):
	var w_sprite = f_weapon_node.get_node("Sprite2D")
	w_sprite.texture = weapon.weapon_sprite
	f_weapon_node.weapon_type = weapon.type
	w_sprite.hframes = weapon.sprite_hframes
	w_sprite.vframes = weapon.sprite_vframes
	if weapon.has_animation:
		f_weapon_node.get_node("AnimationPlayer").play(weapon.sprite_animation)
	else:
		f_weapon_node.get_node("AnimationPlayer").play("RESET")
	
func reset_special():
	#var delta = get_process_delta_time()
	#effects += weapons[is_purple as int].use_special(delta, true, Vector2.RIGHT.rotated(compute_assist_angle((crosshair.position).angle(),output_angles)), global_position,self)
	weapons[is_purple as int].special_cleanup()

func swap_color():
	if LayerManager.room_instance:
		reset_special()
	emit_signal("swapped_color", self)
	if(is_purple):
		is_purple = false
		_check_hare()
		_check_giant()
		sprite.texture = orange_texture
		crosshair_sprite.texture = orange_crosshair
		set_weapon_dr(weapons[0])
		set_weapon_sprite(weapons[0],weapon_node)
		tether_line.default_color = Color("Orange")
		weapons[1].special_time_elapsed = 0.0
		if LayerManager.room_instance:
			var inst = preload("res://Game Elements/Particles/swap_particles.tscn").instantiate()
			inst.range_choice = 1
			inst.global_position = global_position
			LayerManager.room_instance.add_child(inst)
	else:
		is_purple = true
		_check_hare()
		_check_giant()
		sprite.texture = purple_texture
		crosshair_sprite.texture = purple_crosshair
		set_weapon_dr(weapons[1])
		set_weapon_sprite(weapons[1],weapon_node)
		tether_line.default_color = Color("Purple")
		weapons[0].special_time_elapsed = 0.0
		if LayerManager.room_instance:
			var inst = preload("res://Game Elements/Particles/swap_particles.tscn").instantiate()
			inst.range_choice = 0
			inst.global_position = global_position
			LayerManager.room_instance.add_child(inst)
		

var single_swap_duration : float = 0.0
var single_toggle : bool = false

func _check_hare():
	var remnants_purple : Array[Remnant]
	var remnants_orange : Array[Remnant]
	remnants_purple = LayerManager.player_1_remnants
	remnants_orange = LayerManager.player_2_remnants
	var purple_hare_rank = 0
	var orange_hare_rank = 0
	var hare = preload("res://Game Elements/Remnants/hare.tres")
	for rem in remnants_purple:
		if rem.remnant_name == hare.remnant_name and rem.active:
			purple_hare_rank = rem.rank
	for rem in remnants_orange:
		if rem.remnant_name == hare.remnant_name and rem.active:
			orange_hare_rank = rem.rank
	if(is_purple):
		move_speed *= ((1 + .05 * purple_hare_rank) / (1 + .05 * orange_hare_rank)) 
	else:
		move_speed *= ((1 + .05 * orange_hare_rank) / (1 + .05 * purple_hare_rank)) 

func _check_giant():
	var remnants_purple : Array[Remnant]
	var remnants_orange : Array[Remnant]
	remnants_purple = LayerManager.player_1_remnants
	remnants_orange = LayerManager.player_2_remnants
	var purple_giant_rank = 0
	var orange_giant_rank = 0
	var giant = preload("res://Game Elements/Remnants/giant.tres")
	for rem in remnants_purple:
		if rem.remnant_name == giant.remnant_name and rem.active:
			purple_giant_rank = rem.rank
	for rem in remnants_orange:
		if rem.remnant_name == giant.remnant_name and rem.active:
			orange_giant_rank = rem.rank		
	if is_purple:
		#GIANT CHANGE TEST
		var purple_max = max_health + (purple_giant_rank * 5) - (orange_giant_rank * 5)
		var orange_max = max_health
		change_health((-1 + purple_max / orange_max) * current_health, purple_max - orange_max,true)
		#if(purple_giant_rank != 0 && orange_giant_rank != 0):
		#	change_health(purple_max / orange_max * current_health, purple_max - orange_max)
		if(orange_giant_rank != 0 and purple_giant_rank !=0):
			pass
		elif(orange_giant_rank != 0):
			scale = scale / 1.5
			#change_health(-orange_giant_rank * 5, - orange_giant_rank * 5)
		elif(purple_giant_rank != 0):
			scale = scale * 1.5
			#change_health(purple_giant_rank * 5, purple_giant_rank * 5)
	else:
		var purple_max = max_health 
		var orange_max = max_health - (purple_giant_rank * 5) + (orange_giant_rank * 5)
		change_health((-1 + orange_max / purple_max) * current_health, orange_max - purple_max,true)
		#if(purple_giant_rank != 0 && orange_giant_rank != 0):
		#	change_health(orange_giant_rank * 5 - purple_giant_rank * 5, orange_giant_rank * 5 - purple_giant_rank * 5)
		if(orange_giant_rank != 0 and purple_giant_rank !=0):
			pass
		elif(purple_giant_rank != 0):
			scale = scale / 1.5
			#change_health(-purple_giant_rank * 5, - purple_giant_rank * 5)
		elif(orange_giant_rank != 0):
			scale = scale * 1.5
			#change_health(orange_giant_rank * 5, orange_giant_rank * 5)
	

func tether(delta : float):
	if is_tethered:
		TutorialManager.player_tethers(is_purple,delta)
	if(input_device != "key"):
		if Input.is_action_just_pressed("quick_swap_" + input_device):
			if(!is_multiplayer):
				swap_color()
				TutorialManager.player_tethers_short(is_purple,1.0)
	if Input.is_action_just_pressed("swap_" + input_device):
		if is_multiplayer:
			tether_momentum += (other_player.position - position)
			is_tethered = true
		else:
			single_toggle = false
			var direct = (crosshair.position).normalized()
			tether_momentum = direct*32
			other_player.enable(self,direct,!is_purple)
			var remnants : Array[Remnant]
			if(!is_purple):
				remnants = LayerManager.player_1_remnants
			else:
				remnants = LayerManager.player_2_remnants
			var giant_rank = 0
			var giant = preload("res://Game Elements/Remnants/giant.tres")
			for rem in remnants:
				if rem.remnant_name == giant.remnant_name and rem.active:
					giant_rank = rem.rank
			if(giant_rank != 0):
				other_player.collision_shape.scale = other_player.collision_shape.scale * 1.5
				other_player.sprite_2d.scale = other_player.sprite_2d.scale * 1.5
			update_animation_parameters(direct)
	if !Input.is_action_pressed("swap_" + input_device):
		single_toggle = false
	if Input.is_action_just_released("swap_" + input_device):
		if(!is_multiplayer and single_swap_duration <= .15 and single_swap_duration != 0):
			swap_color()
			TutorialManager.player_tethers_short(is_purple,1.0)
			single_toggle = true
			if !is_multiplayer:
				other_player.collision_shape.scale = Vector2(1,1)
				other_player.sprite_2d.scale = Vector2(1,1)
				other_player.disable()
			if tether_line.visible == true:
				tether_line.visible = false
				is_tethered = false
			if(abs(tether_momentum.length_squared()) <  .1):
				tether_momentum = Vector2.ZERO
			else:
				tether_momentum *= .92
			single_swap_duration = 0.0
	if !single_toggle and Input.is_action_pressed("swap_" + input_device) and (is_multiplayer or (global_position-other_player.global_position).length() >=6 or single_swap_duration <.25):
		if single_swap_duration+delta >=.25 and single_swap_duration <.25:
			is_tethered = true
		single_swap_duration+=delta
		if is_tethered:
			check_forcefield(delta)
			var effect = preload("res://Game Elements/Effects/tether.tres").duplicate(true)
			effect.cooldown = delta
			effect.value1 = 0.5
			effect.gained(self)
			effects.append(effect)
		
		tether_line.visible = true
		if other_player.is_tethered:
			if is_purple:
				tether_line.gradient = tether_gradient
			else:
				tether_line.visible = false
		else:
			tether_line.gradient = null
		tether_line.points[0] = position + (other_player.position - position).normalized() * 8
		tether_line.points[2] = other_player.position + (position - other_player.position).normalized() * 8
		tether_line.points[1] = (tether_line.points[0] + tether_line.points[2]) / 2
		var tether_scale = 1.0
		if ((other_player.position - position) / 25).length() > 8:
			tether_momentum += ((other_player.position - position).normalized() * 8 + (((other_player.position - position) - ((other_player.position - position).normalized() * 8)) / 100)) * tether_scale
		else:
			tether_momentum += (other_player.position - position) / 25
		tether_momentum *= .995
		tether_line.width_curve.set_point_value(1, min(max(50 / tether_momentum.length(),.4),1))
	else:
		if (global_position-other_player.global_position).length() <=6 and !is_multiplayer and single_swap_duration >.25:
			swap_color()
			single_toggle = true
		if !is_multiplayer:
			other_player.collision_shape.scale = Vector2(1,1)
			other_player.sprite_2d.scale = Vector2(1,1)
			other_player.disable()
		if tether_line.visible == true:
			tether_line.visible = false
			is_tethered = false
		if(abs(tether_momentum.length_squared()) <  .1):
			tether_momentum = Vector2.ZERO
		else:
			tether_momentum *= .92
		single_swap_duration = 0.0

func die(death : bool , insta_die : bool = false) -> bool:
	if !is_multiplayer:
		#Change to signal something
		self.process_mode = PROCESS_MODE_DISABLED
		visible = false
		LayerManager.open_death_menu()
		return false
	else:
		if other_player.current_health <= 0.0:
			insta_die = true
		if insta_die:
			LayerManager.open_death_menu()
			return false
		if death:
			self.process_mode = PROCESS_MODE_DISABLED
			visible = false
			if(max_health <= 0.0):
				#Change to signal 
				LayerManager.open_death_menu()
				return false
		else:
			Globals.death_time-=1
			i_frames = 60
			change_health(max_health/2.0-current_health)
			self.process_mode = PROCESS_MODE_INHERIT
			visible = true
	return true

func adjust_cooldowns(time_elapsed : float):
	
	if cooldowns[is_purple as int] > 0:
		cooldowns[is_purple as int] = max(cooldowns[is_purple as int]-time_elapsed,0.0)

func handle_attack(is_autofire : bool = false):
	if is_autofire:
		if cooldowns[is_purple as int] <= bandit_cooldown() / 2.0:
			TutorialManager.player_attacks(is_purple,1.0)
			cooldowns[is_purple as int] = request_attack(weapons[is_purple as int])
		return
	if cooldowns[is_purple as int] <= bandit_cooldown():
		TutorialManager.player_attacks(is_purple,1.0)
		cooldowns[is_purple as int] = request_attack(weapons[is_purple as int])


func has_bandit():
	var remnants : Array[Remnant]
	if is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	var bandit = preload("res://Game Elements/Remnants/bandit.tres")
	for rem in remnants:
		if rem.remnant_name == bandit.remnant_name and rem.active:
			return true
	return false

func bandit_cooldown():
	var remnants : Array[Remnant]
	if is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	var bandit = preload("res://Game Elements/Remnants/bandit.tres")
	for rem in remnants:
		if rem.remnant_name == bandit.remnant_name and rem.active:
			return weapons[is_purple as int].cooldown * rem.variable_1_values[rem.rank-1] / 100.0
	return 0.0


func check_traps(delta):
	var tile_pos = Vector2i(int(floor(global_position.x / 16)),int(floor(global_position.y / 16)))
	if tile_pos in LayerManager.trap_cells:
		var tile_data = LayerManager.return_trap_layer(tile_pos).get_cell_tile_data(tile_pos)
		if tile_data:
			var dmg = tile_data.get_custom_data("trap_instant")
			#Instant trap
			if dmg and !in_instant_trap:
				if _crafter_chance():
					take_damage(dmg, null)
				in_instant_trap = true
			if !dmg:
				in_instant_trap = false
			#Ongoing trap
			if tile_data.get_custom_data("trap_ongoing"):
				current_dmg_time += delta
				if current_dmg_time >= tile_data.get_custom_data("trap_ongoing_seconds"):
					current_dmg_time -= tile_data.get_custom_data("trap_ongoing_seconds")
					if _crafter_chance():
						take_damage(tile_data.get_custom_data("trap_ongoing_dmg"),null)
			else:
				current_dmg_time = 0
		else:
			current_dmg_time = 0
			in_instant_trap = false
	else:
		current_dmg_time = 0
		in_instant_trap = false

func _check_hydromancer(liquid : Globals.Liquid):
	var remnants : Array[Remnant]
	if is_purple:
		remnants = get_tree().get_root().get_node("LayerManager").player_1_remnants
	else:
		remnants = get_tree().get_root().get_node("LayerManager").player_2_remnants
	var hydromancer = preload("res://Game Elements/Remnants/hydromancer.tres")
	for rem in remnants:
		if rem.remnant_name == hydromancer.remnant_name and rem.active:
			last_liquid = liquid

func check_liquids(delta) -> bool:
	if is_tethered:
		return false
	var in_liquid = false
	var tile_pos = Vector2i(int(floor(global_position.x / 16)),int(floor(global_position.y / 16)))
	if tile_pos in LayerManager.liquid_cells[0]:
		var tile_data = LayerManager.return_liquid_layer(tile_pos).get_cell_tile_data(tile_pos)
		if tile_data:
			var type = tile_data.get_custom_data("liquid")
			match type:
				Globals.Liquid.Water:
					var effect = preload("res://Game Elements/Effects/slow_down.tres").duplicate(true)
					effect.cooldown = 20*delta
					effect.value1 = 0.023
					effect.gained(self)
					effects.append(effect)
					_check_hydromancer(Globals.Liquid.Water)
					in_liquid =true
				Globals.Liquid.Lava:
					var idx = 0
					for effect in effects:
						if effect.type == "slow":
							var particle =  preload("res://Game Elements/Particles/steam_particles.tscn").instantiate()
							#particle.position = self.position
							self.add_child(particle)
							effect.tick(delta,self)
							if effect.cooldown == 0:
								effects.remove_at(idx)
							current_liquid_time -= .01
						idx +=1
					current_liquid_time += delta
					if current_liquid_time >= .25:
						current_liquid_time -= .25
						take_damage(2.0,null)
					_check_hydromancer(Globals.Liquid.Lava)
					in_liquid =true
				Globals.Liquid.Conveyer:
					position+=tile_data.get_custom_data("direction").normalized() *delta * 32
					in_liquid =true
				Globals.Liquid.Glitch:
					_glitch_move()
					_check_hydromancer(Globals.Liquid.Glitch)
					in_liquid =true
	return in_liquid
					




func _glitch_move(input_move_dir : Vector2 = Vector2(-1234,-1234)) -> void:
	var move_dir_l
	var move_dir_r
	if(input_move_dir == Vector2(-1234,-1234)):
		move_dir_l = velocity.normalized() * 16
		move_dir_r = velocity.normalized() * 16
	else:
		move_dir_l = input_move_dir
		move_dir_r = input_move_dir

	var attempts = 0
	var max_attempts = 36 # prevent infinite loops
	var condition1 = cast_ray(position, move_dir_r.normalized(), move_dir_r.length(), self)
	var condition2 = cast_ray(position, move_dir_l.normalized(), move_dir_l.length(), self)
	while condition1 and condition2 and attempts < max_attempts:
		condition1 = cast_ray(position, move_dir_r.normalized(), move_dir_r.length(), self)
		condition2 = cast_ray(position, move_dir_l.normalized(), move_dir_l.length(), self)
		move_dir_r = move_dir_r.rotated(deg_to_rad(-5))
		move_dir_l = move_dir_l.rotated(deg_to_rad(5))
		attempts += 1

	if velocity.length() < .1:
		return

	var move_dir = move_dir_r
	if not cast_ray(position, move_dir_l.normalized(), move_dir_l.length(), self):
		move_dir = move_dir_l

	position += move_dir / 2.0
	var saved_position = position
	var saved_velocity = velocity
	var position_variance = 16
	var hue_variance = .08
	var color1 = shift_hue(Color(0.0, 0.867, 0.318, 1.0), randf_range(-hue_variance, hue_variance))
	var color2 = shift_hue(Color(0.0, 0.116, 0.014, 1.0), randf_range(-hue_variance, hue_variance))
	position += Vector2(randf_range(-position_variance, position_variance), randf_range(-position_variance, position_variance))
	Spawner.spawn_after_image(self, LayerManager, color1, color1, 0.5, 1.0, 1 + randf_range(-.1, .1), .75)
	position = saved_position
	velocity = move_dir / 2.0
	move_and_slide()
	saved_position = position
	position += Vector2(randf_range(-position_variance, position_variance), randf_range(-position_variance, position_variance))
	Spawner.spawn_after_image(self, LayerManager, color2, color2, 0.5, 1.0, 1 + randf_range(-.1, .1), .75)
	position = saved_position
	move_and_slide()
	velocity = saved_velocity

func shift_hue(color: Color, amount: float) -> Color:
	var h = color.h + amount
	h = fposmod(h, 1.0) # wrap hue to 0–1
	return Color.from_hsv(h, color.s, color.v, color.a)

func _crafter_chance() -> bool:
	if is_tethered:
		return false
	randomize()
	var remnants : Array[Remnant]
	if is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	var crafter = preload("res://Game Elements/Remnants/crafter.tres")
	for rem in remnants:
		if rem.remnant_name == crafter.remnant_name and rem.active:
			if rem.variable_1_values[rem.rank-1] > randf()*100:
				var particle =  preload("res://Game Elements/Particles/crafter_particles.tscn").instantiate()
				particle.position = self.position
				get_parent().add_child(particle)
				return false
			
	return true

func _reset_barb_damage(percent : float, time : float):
	await get_tree().create_timer(time).timeout
	for weapon in weapons:
		weapon.damage = weapon.damage / (1 + percent)

func damage_boost() -> float:
	var boost : float = 0.0
	randomize()
	var remnants : Array[Remnant]
	if is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	var kinetic = preload("res://Game Elements/Remnants/kinetic_battery.tres")
	var ninja = preload("res://Game Elements/Remnants/ninja.tres")
	var assassin = preload("res://Game Elements/Remnants/assassin.tres")
	var hoard = preload("res://Game Elements/Remnants/hoard.tres")
	for rem in remnants:
		if rem.active:
			match rem.remnant_name:
				kinetic.remnant_name:
					var temp_move = 0
					if input_direction != Vector2.ZERO:
						temp_move = move_speed
					boost += (rem.variable_1_values[rem.rank-1]/100.0*((temp_move/base_move_speed)-1))
				ninja.remnant_name:
					if is_purple:
						boost += LayerManager.hud.player1_combo-1.0
					else:
						boost += LayerManager.hud.player2_combo-1.0
				assassin.remnant_name:
					boost += (min(time_since_last_hit * rem.variable_1_values[rem.rank-1],rem.variable_2_values[rem.rank-1]) / 100.0)
				hoard.remnant_name:
					boost += ((rem.variable_1_values[rem.rank-1] * floor(LayerManager.timefabric_collected/50.0)  / 100.0))
	return boost+1.0

func change_health(add_to_current : float, add_to_max : float = 0, ignore_health_change : bool = false):
	if add_to_current > 0.0:
		if add_to_current >= 1.0:
			SFXManager.play(preload("res://Game Elements/sfx/player/gain_health.ogg"),0.0,"SFX",global_position)
		var healer = preload("res://Game Elements/Remnants/healer.tres")
		var hospital = preload("res://Game Elements/Remnants/hospital.tres")
		var remnants = []
		if is_purple:
			remnants = LayerManager.player_1_remnants
		else:
			remnants = LayerManager.player_2_remnants
		for rem in remnants:
			if rem.remnant_name == hospital.remnant_name and rem.active:
				var amnt = rem.variable_1_values[rem.rank - 1] / 100.0
				add_to_current *= (1 + amnt)
		for rem in remnants:
			if rem.remnant_name == healer.remnant_name and rem.active:
				if(add_to_max == 0):
					var amnt = rem.variable_1_values[rem.rank - 1] / 100.0
					var health_restored = min(max_health - current_health, add_to_current)
					add_to_max = health_restored * amnt
	var lich_amount = 1.0- lich_effect(true)
	if add_to_current >= 0.0:	add_to_current *= lich_amount
	if add_to_max >= 0.0:	add_to_max *= lich_amount
	current_health+=add_to_current
	max_health+=add_to_max
	current_health = clamp(current_health,0.0,max_health)
	emit_signal("max_health_changed",max_health,current_health,self,ignore_health_change)
	

func red_flash() -> void:
	if(i_frames > 0) and not invulnerable:
		sprite.self_modulate = Color(1.0, 0.378, 0.31, 1.0)
	else:
		sprite.self_modulate = Color(1.0, 1.0, 1.0)

func set_weapon(purple : bool, resource_loc : String):
	weapons[purple as int] = Weapon.create_weapon(resource_loc,self)
	if LayerManager:
		LayerManager.hud.set_max_cooldowns()
	
func update_weapon(resource_name : String):
	var resource_loc = "res://Game Elements/Weapons/" + resource_name + ".tres"
	weapons[is_purple as int] = Weapon.create_weapon(resource_loc,self)
	weapons[is_purple as int].current_special_hits = weapons[is_purple as int].special_hits
	if is_purple:
		Globals.weapon1 = resource_loc
	else:
		Globals.weapon2 = resource_loc
	set_weapon_dr(weapons[is_purple as int])
	set_weapon_sprite(weapons[is_purple as int],weapon_node)
	if LayerManager:
		LayerManager.hud.set_max_cooldowns()
	LayerManager.hud._on_special_changed(is_purple,1.0)
	

func combo(input_purple : bool):
	var remnants : Array[Remnant]
	if is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	var ninja = preload("res://Game Elements/Remnants/ninja.tres")
	for rem in remnants:
		if rem.remnant_name == ninja.remnant_name and rem.active:
			LayerManager.hud.combo_change(input_purple,true)
			
func display_combo():
	var remnants : Array[Remnant]
	var ninja = preload("res://Game Elements/Remnants/ninja.tres")
	if !Globals.is_multiplayer:
		if !is_purple:
			remnants = LayerManager.player_1_remnants
		else:
			remnants = LayerManager.player_2_remnants
		for rem in remnants:
			if rem.remnant_name == ninja.remnant_name and rem.active:
				LayerManager.hud.combo(rem,!self.is_purple)
		
	if is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	for rem in remnants:
		if rem.remnant_name == ninja.remnant_name and rem.active:
			LayerManager.hud.combo(rem,self.is_purple)
	

func player_special_reset():
	emit_signal("special_reset", is_purple)

func hit_enemy(attack_body : Node, enemy : Node):
	var temp_purple = is_purple
	if attack_body:
		temp_purple=attack_body.is_purple
	var remnants : Array[Remnant] = []
	var effect : Effect
	if attack_body and attack_body.attack_type == "emp":
		if temp_purple:
			remnants = get_tree().get_root().get_node("LayerManager").player_1_remnants
		else:
			remnants = get_tree().get_root().get_node("LayerManager").player_2_remnants
		var emp = preload("res://Game Elements/Remnants/emp.tres")
		for rem in remnants:
			if rem.remnant_name == emp.remnant_name and rem.active:
				effect = preload("res://Game Elements/Effects/stun.tres").duplicate(true)
				effect.cooldown = rem.variable_1_values[rem.rank-1]
				effect.gained(enemy)
				enemy.effects.append(effect)
		
		return
	var cur_weapon = weapons[temp_purple as int]
	cur_weapon.current_special_hits +=1
	if cur_weapon.current_special_hits > cur_weapon.special_hits:
		cur_weapon.current_special_hits = cur_weapon.special_hits
	else:
		emit_signal("special_changed",temp_purple,cur_weapon.current_special_hits/float(cur_weapon.special_hits))
		
	
	if temp_purple:
		remnants = get_tree().get_root().get_node("LayerManager").player_1_remnants
	else:
		remnants = get_tree().get_root().get_node("LayerManager").player_2_remnants
		
	#var winter = preload("res://Game Elements/Remnants/winters_embrace.tres")
	#for rem in remnants:
		#if rem.remnant_name == winter.remnant_name:
			#effect = preload("res://Game Elements/Effects/winter_freeze.tres").duplicate(true)
			#effect.cooldown = rem.variable_2_values[rem.rank-1]
			#effect.value1 =  rem.variable_1_values[rem.rank-1]
			#effect.gained(enemy)
			#enemy.effects.append(effect)


func check_drones():
	var remnants : Array[Remnant]
	if is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	var drone = preload("res://Game Elements/Remnants/drone.tres")
	for rem in remnants:
		if rem.remnant_name == drone.remnant_name and rem.active:
			var drones = get_tree().get_nodes_in_group("drones")
			var drones_player = []
			for drone_inst in drones:
				if drone_inst.player == self and drone_inst.killed != true:
					drones_player.append(drone_inst)
			if drones_player.size()>0:
				drones_player[0].kill()
				return true
	return false

func check_forcefield(delta : float):
	var remnants : Array[Remnant]
	if is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	var force = preload("res://Game Elements/Remnants/forcefield.tres")
	for rem in remnants:
		if rem.remnant_name == force.remnant_name and rem.active:
			var effect = preload("res://Game Elements/Effects/forcefield.tres").duplicate(true)
			effect.cooldown = 2* delta
			$Forcefield.damage = force.variable_1_values[rem.rank-1]
			effect.gained(self)
			effects.append(effect)
	
func check_tortoise(temp_is_purple : bool, new_progress : float, used_special : bool = false):
	if !used_special:
		return
	var remnants : Array[Remnant]
	if temp_is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	var tort = preload("res://Game Elements/Remnants/tortoise.tres")
	var litho = preload("res://Game Elements/Remnants/terramancer.tres")
	for rem in remnants:
		if rem.active:
			match rem.remnant_name:
				tort.remnant_name:
					var shield = preload("res://Game Elements/Remnants/tortoise/shield.tscn").instantiate()
					var shield2 = preload("res://Game Elements/Remnants/tortoise/shield_deflection.tscn").instantiate()
					shield2.c_owner = self
					shield2.direction = (crosshair.position).normalized()
					LayerManager.room_instance.add_child(shield)
					LayerManager.room_instance.add_child(shield2)
					shield.rotation = (crosshair.position).normalized().angle() +PI/2
					shield2.rotation = (crosshair.position).normalized().angle() +PI/2
					shield.lifetime = tort.variable_2_values[rem.rank-1]
					shield.scale = Vector2(tort.variable_3_values[rem.rank-1],tort.variable_3_values[rem.rank-1])
					shield2.scale = Vector2(tort.variable_3_values[rem.rank-1],tort.variable_3_values[rem.rank-1])
					shield.global_position = global_position
					shield2.global_position = global_position
					shield.deflection  =shield2
				litho.remnant_name:
					var lith_area = preload("res://Game Elements/Remnants/lithomancer/lithomancer.tscn").instantiate()
					lith_area.scale *= 1 + (rem.rank -1) * .2
					lith_area.lifetime = rem.rank * 3
					lith_area.litho_value = rem.variable_2_values[rem.rank - 1]
					LayerManager.room_instance.add_child(lith_area)
					lith_area.global_position = global_position
					
			
	


func kill_enemy(enemy: Node):
	var remnants : Array[Remnant]
	if is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	var killer = preload("res://Game Elements/Remnants/killer.tres")
	var killer_chance = 0
	for rem in remnants:
		if rem.remnant_name == killer.remnant_name and rem.active:
			killer_chance =  rem.variable_1_values[rem.rank -1 ] / 100.0
	
	var adrenal = preload("res://Game Elements/Remnants/adrenal_injector.tres")
	var drone = preload("res://Game Elements/Remnants/drone.tres")
	var blood_moon = preload("res://Game Elements/Remnants/blood_moon.tres")
	for rem in remnants:
		if rem.remnant_name == adrenal.remnant_name and rem.active:
			var num_times = 2 if randf() < killer_chance else 1
			for i in range(0,num_times):
				if move_speed < 3*base_move_speed:
					var effect = preload("res://Game Elements/Effects/speed.tres").duplicate(true)
					effect.cooldown = adrenal.variable_2_values[rem.rank-1]
					effect.value1 = adrenal.variable_1_values[rem.rank-1] / 100.0
					if move_speed * (1+effect.value1) >3*base_move_speed:
						effect.value1 = 4*base_move_speed/move_speed - 1
					effect.gained(self)
					effects.append(effect)
		if rem.remnant_name == drone.remnant_name and rem.active:
			var num_times = 2 if randf() < killer_chance else 1
			for i in range(0,num_times):
				var drones = get_tree().get_nodes_in_group("drones")
				var drone_num = 0
				for drone_inst in drones:
					if drone_inst.player == self:
						drone_num+=1
				if drone_num >= rem.variable_2_values[rem.rank-1]:
					break
				var dr_inst = preload("res://Game Elements/Remnants/drone/drone.tscn").instantiate()
				LayerManager.room_instance.add_child(dr_inst)
				dr_inst.global_position = enemy.global_position
				dr_inst.prep(self, rem.variable_1_values[rem.rank-1])
		if rem.remnant_name == blood_moon.remnant_name:
			var num_times = 2 if randf() < killer_chance else 1
			for i in range(0,num_times):
				var heal_chance = rem.variable_1_values[rem.rank-1]
				if(randf() * 100 <= heal_chance):
					var particle =  preload("res://Game Elements/Particles/heal_particles.tscn").instantiate()
					particle.position = self.position
					get_parent().add_child(particle)
					change_health(rem.variable_2_values[rem.rank-1] * .01 * max_health)

func deflect_chance():
	var remnants : Array[Remnant]
	if is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	var big = preload("res://Game Elements/Remnants/big_t.tres")
	for rem in remnants:
		if rem.active:
			match rem.remnant_name:
				big.remnant_name:
					return rem.variable_1_values[rem.rank-1] / 100.0
	return 0.0
	
func lich_effect(is_health : bool = false):
	var remnants : Array[Remnant]
	if is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	var lich = preload("res://Game Elements/Remnants/archlich.tres")
	for rem in remnants:
		if rem.active:
			match rem.remnant_name:
				lich.remnant_name:
					if is_health:
						return rem.variable_2_values[rem.rank-1] / 100.0
					else:
						return rem.variable_1_values[rem.rank-1] / 100.0
	return 0.0
func attraction_effect():
	var effect_radius := 64.0
	var attraction_strength = 0.0
	var timefabric_strength = 60.0
	var sing = preload("res://Game Elements/Remnants/singularity.tres")
	for rem in LayerManager.player_1_remnants:
		if rem.active:
			match rem.remnant_name:
				sing.remnant_name:
					effect_radius =rem.variable_3_values[rem.rank-1]
					if is_purple: attraction_strength = rem.variable_4_values[rem.rank-1]
					if !is_purple: timefabric_strength = rem.variable_5_values[rem.rank-1]
	for rem in LayerManager.player_2_remnants:
		if rem.active:
			match rem.remnant_name:
				sing.remnant_name:
					effect_radius =rem.variable_3_values[rem.rank-1]
					if !is_purple: attraction_strength = rem.variable_4_values[rem.rank-1]
					if is_purple: timefabric_strength = rem.variable_5_values[rem.rank-1]
	if attraction_strength == 0.0: return timefabric_strength
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	for enemy in enemies:
		if not enemy.is_inside_tree() or enemy.is_boss:
			continue
		# Ensure the physics body has a valid space
		if not enemy.get_rid().is_valid():
			continue
		var dir = enemy.global_position - global_position
		var dist = dir.length()
		if dist < effect_radius and dist > 0:
			var force = dir.normalized() * attraction_strength * (1.0 - dist / effect_radius)
			var temp_velocity = enemy.velocity
			enemy.apply_velocity(force)
			enemy.velocity = temp_velocity
	return timefabric_strength
