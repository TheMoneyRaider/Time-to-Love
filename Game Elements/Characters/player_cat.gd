extends CharacterBody2D
var mouse_sensitivity: float = 1.0

@export var base_move_speed: float = 100
var move_speed: float
@export var max_health: float = 10.0
@export var current_health: float = 10.0
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

@onready var tether_line = $Line2D
@onready var crosshair = $Crosshair
@onready var crosshair_sprite = $Crosshair/Sprite2D

@onready var weapon_node = $WeaponSprite

@onready var sprite = $Sprite2D
@onready var purple_crosshair = preload("res://art/purple_crosshair.png")
@onready var orange_crosshair = preload("res://art/orange_crosshair.png")
@onready var purple_texture = preload("res://art/Sprout Lands - Sprites - Basic pack/Characters/Basic Purple Spritesheet-export.png")
@onready var orange_texture = preload("res://art/Sprout Lands - Sprites - Basic pack/Characters/Basic Orange Spritesheet-export.png")
var other_player
var disabled = false

var tether_momentum = Vector2.ZERO
var is_tethered = false
var tether_gradient
var tether_width_curve

var is_multiplayer = false
var input_device = "-1"
var input_direction : Vector2 = Vector2.ZERO
var invulnerable : bool = false
var debug_menu : bool = false

var effects : Array[Effect] = []
var last_liquid : Globals.Liquid = Globals.Liquid.Buffer

var forcefield_active : bool = false


#The scripts for loading default values into the attack
#The list of attacks for playercharacter
var weapons = [Weapon.create_weapon("res://Game Elements/Weapons/Crossbow.tres",self),Weapon.create_weapon("res://Game Elements/Weapons/LaserSword.tres",self)]
var attacks = [preload("res://Game Elements/Attacks/bolt.tscn"),preload("res://Game Elements/Attacks/smash.tscn")]
var revive = preload("res://Game Elements/Attacks/death_mark.tscn")
var cooldowns = [0,0]
var is_purple = true

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

func _ready():
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
	load_settings()
	set_weapon_sprite(weapons[is_purple as int],weapon_node)
	if is_multiplayer:
		tether_gradient = tether_line.gradient
		tether_width_curve = tether_line.width_curve
		tether_line.gradient = null			
	hide_forcefield(0.0)


func hide_forcefield(interp_time : float):
	forcefield_active = false
	if interp_time == 0.0:
		$Forcefield/CollisionShape2D.disabled  =true
		$Forcefield/Forcefield.modulate.a = 0.0
		return
	$Forcefield/CollisionShape2D.disabled  =true
	create_tween().tween_property($Forcefield/Forcefield,"modulate",Color(1.0,1.0,1.0,0.0),interp_time)

func show_forcefield(interp_time : float):
	forcefield_active = true
	if interp_time == 0.0:
		$Forcefield/CollisionShape2D.disabled  =false
		$Forcefield/Forcefield.modulate.a = 1.0
		return
	$Forcefield/CollisionShape2D.disabled  =false
	$Forcefield/Forcefield.modulate.a = 0.0
	create_tween().tween_property($Forcefield/Forcefield,"modulate",Color(1.0,1.0,1.0,1.0),interp_time)
	

func update_input_device(in_dev : String):
	input_device = in_dev
	crosshair.player_input_device = input_device

func load_settings():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		debug_menu = config.get_value("debug", "enabled", false)

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

	var enemies : Array[Node] = []
	for child in LayerManager.room_instance.get_children():
		if child.is_in_group("enemy"):
			enemies.append(child)
	var angles : Array[Vector2]= []
	for enemy in enemies:
		var band = angular_band_circle(global_position, enemy.get_node("CollisionShape2D"))
		var ray_length = (enemy.global_position - global_position).length()

		var left_ray = Vector2(cos(band.x), sin(band.x))
		var right_ray = Vector2(cos(band.y), sin(band.y))

		var ray1 = cast_ray(global_position, left_ray, ray_length, self)
		var ray2 = cast_ray(global_position, right_ray, ray_length, self)

		var left_point = ray1.position if ray1 else global_position + left_ray * ray_length
		var right_point = ray2.position if ray2 else global_position + right_ray * ray_length

		var blocked = false
		if ray1 and ((global_position - ray1.position).length() - ray_length) < 4:
			blocked = true
		if ray2 and ((global_position - ray2.position).length() - ray_length) < 4:
			blocked = true
		if debug_angles:
			_debug_wedges.append({
				"from": global_position,
				"left": left_point,
				"right": right_point,
				"blocked": blocked
			})
		if !blocked:
			angles.append(band)
	return angles


func cast_ray(origin: Vector2, direction: Vector2, distance: float, player_node : Node) -> Dictionary:
	var space = player_node.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(origin - direction, origin + direction * distance)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 1 << 0
	return space.intersect_ray(query)


func angular_band_circle(player_pos: Vector2, collision_shape: CollisionShape2D) -> Vector2:
	var shape_pos = collision_shape.global_position
	var to_shape = shape_pos - player_pos
	if collision_shape.shape is CircleShape2D:
		var radius = collision_shape.shape.radius

		var distance = to_shape.length()

		# Handle case if player is inside the shape
		if distance < radius:
			return Vector2(-PI, PI)

		# Angular half-width
		var half_angle = asin(radius / distance)

		var center_angle = to_shape.angle()
		return Vector2(center_angle - half_angle, center_angle + half_angle)
	if collision_shape.shape is RectangleShape2D:
			var extents = collision_shape.shape.extents
			var corners = [
				Vector2(-extents.x, -extents.y),
				Vector2(extents.x, -extents.y),
				Vector2(extents.x, extents.y),
				Vector2(-extents.x, extents.y)
			]

			var angles = []
			for corner in corners:
				var global_corner = collision_shape.to_global(corner)
				var dir = global_corner - player_pos
				angles.append(dir.angle())

			# Handle -π/π wrapping
			var min_angle = angles[0]
			var max_angle = angles[0]
			for a in angles:
				var diff = wrapf(a - min_angle, -PI, PI)
				if diff < 0:
					min_angle = a
				diff = wrapf(a - max_angle, -PI, PI)
				if diff > 0:
					max_angle = a
			return Vector2(min_angle, max_angle)
	if collision_shape.shape is CapsuleShape2D:
		var radius =collision_shape.shape.radius + collision_shape.shape.height/2.0

		var distance = to_shape.length()

		# Handle case if player is inside the shape
		if distance < radius:
			return Vector2(-PI, PI)

		# Angular half-width
		var half_angle = asin(radius / distance)

		var center_angle = to_shape.angle()
		return Vector2(center_angle - half_angle, center_angle + half_angle)
	
	
	
	return Vector2(to_shape.angle(),to_shape.angle())

func compute_assist_angle(player_angle: float, enemy_angles: Array, band_size: float = deg_to_rad(45)) -> float:
	var new_angle = player_angle
	for v in enemy_angles:
		var center = (v.x + v.y) / 2
		var diff = circular_diff(center, new_angle)
		if abs(diff) <= band_size/2:
			# move along the circular difference, weighted by triangle shape
			var t = 1.0 - abs(diff)/(band_size/2)
			new_angle += diff * t
			new_angle = wrap_angle(new_angle)
	return new_angle

func circular_diff(a: float, b: float) -> float:
	var d = a - b
	while d > PI: d -= TAU
	while d < -PI: d += TAU
	return d

func wrap_angle(angle: float) -> float:
	while angle > PI: angle -= TAU
	while angle < -PI: angle += TAU
	return angle



var output_angles = []

		
			
func _input(event):
	if event.is_action_pressed("toggle_enemy_angles") and debug_mode:
		debug_angles = !debug_angles
		_debug_wedges.clear()
		queue_redraw()


func _physics_process(delta):
	if disabled:
		return
		
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
	check_liquids(delta)
	
	#Cat input detection
	input_direction = Vector2(
		Input.get_action_strength("right_" + input_device) - Input.get_action_strength("left_" + input_device),
		Input.get_action_strength("down_" + input_device) - Input.get_action_strength("up_" + input_device)
	)
	input_direction = input_direction.normalized()
	
	update_animation_parameters(input_direction)	
	
	tether(delta)
	if is_tethered:
		input_direction += (tether_momentum / move_speed)
	weapon_node.weapon_direction = (crosshair.position).normalized()
	#move and slide function
	if(self.process_mode != PROCESS_MODE_DISABLED and disabled_countdown <= 0):
		move_and_slide()
	
	
	if debug_menu and Input.is_action_just_pressed("toggle_invulnerability"):
		invulnerable = !invulnerable
	
	if Input.is_action_just_pressed("attack_" + input_device):
		if Input.is_action_pressed("special_" + input_device) and weapons[is_purple as int].current_special_hits >= weapons[is_purple as int].special_hits:
			weapons[is_purple as int].use_normal_attack(Vector2.RIGHT.rotated(compute_assist_angle((crosshair.position).angle(),output_angles)), global_position,self)
		else:
			handle_attack()
	if Input.is_action_just_pressed("activate_" + input_device):
		emit_signal("activate",self)
	if Input.is_action_pressed("special_" + input_device):
		effects += weapons[is_purple as int].use_special(delta,false, Vector2.RIGHT.rotated(compute_assist_angle((crosshair.position).angle(),output_angles)), global_position,self)
		emit_signal("special",self)
	elif Input.is_action_just_released("special_" + input_device):
		effects += weapons[is_purple as int].use_special(delta, true, Vector2.RIGHT.rotated(compute_assist_angle((crosshair.position).angle(),output_angles)), global_position,self)
		
	adjust_cooldowns(delta)
	red_flash()
	if disabled_countdown >= 1:
		disabled_countdown-=1

func update_animation_parameters(move_input : Vector2):
	if(move_input != Vector2.ZERO):
		idle_state.move_direction = move_input
		move_state.move_direction = move_input
		

func request_attack(t_weapon : Weapon) -> float:
	weapon_node.flip_direction()
	var attack_direction = Vector2.RIGHT.rotated(compute_assist_angle((crosshair.position).angle(),output_angles))
	t_weapon.request_attacks(attack_direction,global_position,self,weapon_node.flip)
	return t_weapon.cooldown

func take_damage(damage_amount : float, _dmg_owner : Node,_direction = Vector2(0,-1), attack_body : Node = null, attack_i_frames : int = 20,creates_indicators : bool = true):
	if(i_frames <= 0) and not invulnerable:
		i_frames = attack_i_frames
		if check_drones():
			LayerManager._damage_indicator(0, _dmg_owner,_direction, attack_body,self,Color(0.0, 0.666, 0.85, 1.0))
			return
		var remnants : Array[Remnant]
		if is_purple:
			remnants = LayerManager.player_1_remnants
		else:
			remnants = LayerManager.player_2_remnants
		var phase = load("res://Game Elements/Remnants/body_phaser.tres")
		var invest = load("res://Game Elements/Remnants/investment.tres")
		var emp = load("res://Game Elements/Remnants/emp.tres")
		for rem in remnants:
			if rem.remnant_name == phase.remnant_name:
				var temp_move = 0
				if input_direction != Vector2.ZERO:
					temp_move = move_speed
				damage_amount *= (1.0-rem.variable_1_values[rem.rank-1]/100.0*((temp_move/base_move_speed)-1))
				damage_amount = max(0.0,damage_amount)
			if rem.remnant_name == invest.remnant_name:
				LayerManager.timefabric_collected-= LayerManager.timefabric_collected * (rem.variable_2_values[rem.rank-1])/100.0
			if rem.remnant_name == emp.remnant_name and _dmg_owner and _dmg_owner.is_in_group("enemy"):
				var instance = load("res://Game Elements/Attacks/emp.tscn").instantiate()
				instance.c_owner = self
				instance.global_position = global_position
				LayerManager.room_instance.call_deferred("add_child",instance)
				
		current_health = current_health - damage_amount
		emit_signal("player_took_damage",damage_amount,current_health,self)
		if current_health >= 0.0 and creates_indicators:
			LayerManager._damage_indicator(damage_amount, _dmg_owner,_direction, attack_body,self)
		if(current_health <= 0.0):
			if(die(true)):
				var instance = revive.instantiate()
				instance.global_position = position
				instance.c_owner = self
				LayerManager.room_instance.add_child(instance)
				emit_signal("attack_requested",revive, position, Vector2.ZERO, 0)
		_cleric_chance()
		_barb_damage()

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
	


func swap_color():
	emit_signal("swapped_color", self)
	if(is_purple):
		is_purple = false
		sprite.texture = orange_texture
		crosshair_sprite.texture = orange_crosshair
		set_weapon_sprite(weapons[0],weapon_node)
		tether_line.default_color = Color("Orange")
		weapons[1].special_time_elapsed = 0.0
	else:
		is_purple = true
		sprite.texture = purple_texture
		crosshair_sprite.texture = purple_crosshair
		set_weapon_sprite(weapons[1],weapon_node)
		tether_line.default_color = Color("Purple")
		weapons[0].special_time_elapsed = 0.0
		

var single_swap_duration : float = 0.0
var single_toggle : bool = false



func tether(delta : float):
	if Input.is_action_just_pressed("swap_" + input_device):
		if is_multiplayer:
			tether_momentum += (other_player.position - position)
			is_tethered = true
		else:
			single_toggle = false
			var direct = (crosshair.position).normalized()
			tether_momentum = direct*32
			other_player.enable(self,direct,!is_purple)
			update_animation_parameters(direct)
	if !Input.is_action_pressed("swap_" + input_device):
		single_toggle = false
	if !single_toggle and Input.is_action_pressed("swap_" + input_device) and (is_multiplayer or (global_position-other_player.global_position).length() >=6 or single_swap_duration <.5):
		if single_swap_duration+delta >=.5 and single_swap_duration <.5:
			is_tethered = true
		single_swap_duration+=delta
		if is_tethered:
			check_forcefield(delta)
			var effect = load("res://Game Elements/Effects/tether.tres").duplicate(true)
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
		if ((other_player.position - position) / 25).length() > 8:
			tether_momentum += (other_player.position - position).normalized() * 8 + (((other_player.position - position) - ((other_player.position - position).normalized() * 8)) / 100)
		else:
			tether_momentum += (other_player.position - position) / 25
		tether_momentum *= .995
		tether_line.width_curve.set_point_value(1, min(max(50 / tether_momentum.length(),.4),1))
	else:
		if (global_position-other_player.global_position).length() <=6 and !is_multiplayer and single_swap_duration >.5:
			swap_color()
			single_toggle = true
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
			max_health = max_health/2.0 if max_health > 40 else max_health-2.0
			emit_signal("max_health_changed",max_health,current_health, self)
			self.process_mode = PROCESS_MODE_DISABLED
			visible = false
			if(max_health <= 0.0):
				#Change to signal 
				LayerManager.open_death_menu()
				return false
		else:
			current_health = max_health / 2.0
			emit_signal("player_took_damage",-max_health / 2.0,current_health,self)
			self.process_mode = PROCESS_MODE_INHERIT
			visible = true
	return true

func adjust_cooldowns(time_elapsed : float):
	
	if cooldowns[is_purple as int] > 0:
		cooldowns[is_purple as int] = max(cooldowns[is_purple as int]-time_elapsed,0.0)

func handle_attack():
	if cooldowns[is_purple as int] <= 0:
		cooldowns[is_purple as int] = request_attack(weapons[is_purple as int])

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
	var hydromancer = load("res://Game Elements/Remnants/hydromancer.tres")
	for rem in remnants:
		if rem.remnant_name == hydromancer.remnant_name:
			last_liquid = liquid

func check_liquids(delta):
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
					_check_hydromancer(Globals.Liquid.Water)
				Globals.Liquid.Lava:
					var idx = 0
					for effect in effects:
						if effect.type == "slow":
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
				Globals.Liquid.Conveyer:
					position+=tile_data.get_custom_data("direction").normalized() *delta * 32
				Globals.Liquid.Glitch:
					_glitch_move()
					_check_hydromancer(Globals.Liquid.Glitch)
					
					
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

func _crafter_chance() -> bool:
	randomize()
	var remnants : Array[Remnant]
	if is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	var crafter = load("res://Game Elements/Remnants/crafter.tres")
	for rem in remnants:
		if rem.remnant_name == crafter.remnant_name:
			if rem.variable_1_values[rem.rank-1] > randf()*100:
				var particle =  load("res://Game Elements/Effects/crafter_particles.tscn").instantiate()
				particle.position = self.position
				get_parent().add_child(particle)
				return false
			
	return true

func _cleric_chance():
	randomize()
	var remnants : Array[Remnant]
	if is_purple:
		remnants = get_tree().get_root().get_node("LayerManager").player_1_remnants
	else:
		remnants = get_tree().get_root().get_node("LayerManager").player_2_remnants
	var cleric = load("res://Game Elements/Remnants/cleric.tres")
	for rem in remnants:
		if rem.remnant_name == cleric.remnant_name:
			if rem.variable_1_values[rem.rank-1] > randf()*100:
				var particle =  load("res://Game Elements/Effects/heal_particles.tscn").instantiate()
				particle.position = self.position
				get_parent().add_child(particle)
				change_health(rem.variable_2_values[rem.rank-1])

func _barb_damage():
	var remnants : Array[Remnant]
	if is_purple:
		remnants = get_tree().get_root().get_node("LayerManager").player_1_remnants
	else:
		remnants = get_tree().get_root().get_node("LayerManager").player_2_remnants
	var barbarian = load("res://Game Elements/Remnants/barbarian.tres")
	for rem in remnants:
		if rem.remnant_name == barbarian.remnant_name:
			for weapon in weapons:
				weapon.damage = weapon.damage * (1 + rem.variable_1_values[rem.rank-1] / 100.0)
			_reset_barb_damage(rem.variable_1_values[rem.rank-1] / 100.0,rem.variable_2_values[rem.rank-1])

func _reset_barb_damage(percent : float, time : float):
	await get_tree().create_timer(time).timeout
	for weapon in weapons:
		weapon.damage = weapon.damage / (1 + percent)

func damage_boost() -> float:
	var boost : float = 1.0
	randomize()
	var remnants : Array[Remnant]
	if is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	var hunter = load("res://Game Elements/Remnants/hunter.tres")
	var kinetic = load("res://Game Elements/Remnants/kinetic_battery.tres")
	var ninja = load("res://Game Elements/Remnants/ninja.tres")
	for rem in remnants:
		if rem.remnant_name == hunter.remnant_name:
			var min_dist = 100000
			for child in LayerManager.room_instance.get_children():
				if child is DynamEnemy:
					min_dist = min(min_dist,self.position.distance_to(child.position))
			if rem.variable_2_values[rem.rank-1]*16 < min_dist:
				boost = (100+float(rem.variable_1_values[rem.rank-1]))/100.0
		if rem.remnant_name == kinetic.remnant_name:
			var temp_move = 0
			if input_direction != Vector2.ZERO:
				temp_move = move_speed
			boost *= (1.0+rem.variable_1_values[rem.rank-1]/100.0*((temp_move/base_move_speed)-1))
		if rem.remnant_name == ninja.remnant_name:
			if is_purple:
				boost *= LayerManager.hud.player1_combo
			else:
				boost *= LayerManager.hud.player2_combo
	return boost

func change_health(add_to_current : float, add_to_max : float = 0):
	current_health+=add_to_current
	max_health+=add_to_max
	current_health = clamp(current_health,0.0,max_health)
	emit_signal("max_health_changed",max_health,current_health,self)

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
	set_weapon_sprite(weapons[is_purple as int],weapon_node)
	

func combo(input_purple : bool):
	var remnants : Array[Remnant]
	if is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	var ninja = load("res://Game Elements/Remnants/ninja.tres")
	for rem in remnants:
		if rem.remnant_name == ninja.remnant_name:
			LayerManager.hud.combo_change(input_purple,true)
			
func display_combo():
	var remnants : Array[Remnant]
	var ninja = load("res://Game Elements/Remnants/ninja.tres")
	if !Globals.is_multiplayer:
		if !is_purple:
			remnants = LayerManager.player_1_remnants
		else:
			remnants = LayerManager.player_2_remnants
		for rem in remnants:
			if rem.remnant_name == ninja.remnant_name:
				LayerManager.hud.combo(rem,!self.is_purple)
		
	if is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	for rem in remnants:
		if rem.remnant_name == ninja.remnant_name:
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
		var emp = load("res://Game Elements/Remnants/emp.tres")
		for rem in remnants:
			if rem.remnant_name == emp.remnant_name:
				effect = load("res://Game Elements/Effects/stun.tres").duplicate(true)
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
		
	var winter = load("res://Game Elements/Remnants/winters_embrace.tres")
	for rem in remnants:
		if rem.remnant_name == winter.remnant_name:
			effect = load("res://Game Elements/Effects/winter_freeze.tres").duplicate(true)
			effect.cooldown = rem.variable_2_values[rem.rank-1]
			effect.value1 =  rem.variable_1_values[rem.rank-1]
			effect.gained(enemy)
			enemy.effects.append(effect)


func check_drones():
	var remnants : Array[Remnant]
	if is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	var drone = load("res://Game Elements/Remnants/drone.tres")
	for rem in remnants:
		if rem.remnant_name == drone.remnant_name:
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
	var force = load("res://Game Elements/Remnants/forcefield.tres")
	for rem in remnants:
		if rem.remnant_name == force.remnant_name:
			var effect = load("res://Game Elements/Effects/forcefield.tres").duplicate(true)
			effect.cooldown = 2* delta
			$Forcefield.damage = force.variable_1_values[rem.rank-1]
			effect.gained(self)
			effects.append(effect)
	


func kill_enemy(enemy: Node):
	var remnants : Array[Remnant]
	if is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	var adrenal = load("res://Game Elements/Remnants/adrenal_injector.tres")
	var drone = load("res://Game Elements/Remnants/drone.tres")
	for rem in remnants:
		if rem.remnant_name == adrenal.remnant_name:
			if move_speed < 3*base_move_speed:
				var effect = load("res://Game Elements/Effects/speed.tres").duplicate(true)
				effect.cooldown = adrenal.variable_2_values[rem.rank-1]
				effect.value1 = adrenal.variable_1_values[rem.rank-1] / 100.0
				if move_speed * (1+effect.value1) >3*base_move_speed:
					effect.value1 = 4*base_move_speed/move_speed - 1
				effect.gained(self)
				effects.append(effect)
		if rem.remnant_name == drone.remnant_name:
			var drones = get_tree().get_nodes_in_group("drones")
			var drone_num = 0
			for drone_inst in drones:
				if drone_inst.player == self:
					drone_num+=1
			if drone_num >= rem.variable_2_values[rem.rank-1]:
				break
			var dr_inst = load("res://Game Elements/Remnants/drone/drone.tscn").instantiate()
			LayerManager.room_instance.add_child(dr_inst)
			dr_inst.global_position = enemy.global_position
			dr_inst.prep(self, rem.variable_1_values[rem.rank-1])
