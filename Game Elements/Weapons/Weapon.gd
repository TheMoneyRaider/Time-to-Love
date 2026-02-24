extends Resource
class_name Weapon

# Exposed fields for editor
@export var type: String = "Error"
@export var cooldown_icon: Resource = preload("res://art/weapons/mace/mace_bright.png")
@export var weapon_sprite: Resource = null
@export var num_attacks: int = 1

@export var random_spread : bool = true
@export var attack_spread: float = 0
@export var split_attacks: bool = false

@export var attack_type: String = "smash"
@export var attack_scene: String = "res://Game Elements/Attacks/smash.tscn"
@export var special_attack_scene: String = "res://Game Elements/Attacks/smash.tscn"
@export var spawn_distance: float = 20
@export var special_hits : int = 5
@export var special_on_release : bool =  true
@export var has_animation : bool = false
@export var sprite_animation : String = ""
@export var sprite_hframes : int = 1
@export var sprite_vframes : int = 1
var current_special_hits = 0

var speed = 60.0
#How fast the attack is moving
var damage = 1.0
#How much damage the attack will do
var lifespan = 1.0
#How long attack lasts in seconds before despawning
var hit_force = 0.0
#How much speed it adds to deflected objects
var start_lag = 0.0
#How much time after pressing attack does the attack start in seconds
var cooldown = .5
var pierce = 0.0
#How many enemies the attack will pierce through (-1 for inf)
var c_owner: Node = null
#If the attack can hit walls

#Variables for Specials
var special_time_elapsed : float = 0.0
var special_time_period_elapsed : int = 0
var special_start_damage : float = 1.0
var special_started : bool = false
var special_nodes = []

static func create_weapon(resource_location : String, current_owner : Node2D):
	var new_weapon = load(resource_location).duplicate(true)
	var attack_instance = load(new_weapon.attack_scene).instantiate()
	new_weapon.speed = attack_instance.speed
	new_weapon.damage = attack_instance.damage
	new_weapon.lifespan = attack_instance.lifespan
	new_weapon.hit_force = attack_instance.hit_force
	new_weapon.start_lag = attack_instance.start_lag
	new_weapon.cooldown = attack_instance.cooldown
	new_weapon.pierce = attack_instance.pierce
	new_weapon.c_owner = current_owner
	attack_instance.queue_free()
	#Modify sprites in c_owner
	
	return new_weapon

func request_attacks(direction : Vector2, char_position : Vector2, node_attacking : Node, flip : int = 1):
	
	var attack_direction
	if(!split_attacks):
		attack_direction = direction.rotated(deg_to_rad((-attack_spread / 2) + randf_range(0,attack_spread)))
	else:
		attack_direction = direction.rotated(deg_to_rad(-attack_spread / 2))
		if(random_spread):
			attack_direction = attack_direction.rotated(deg_to_rad(randf_range(-attack_spread / (4 * num_attacks), attack_spread / (4 * num_attacks))))
	if(num_attacks > 1):
		for i in range(num_attacks):
			#If there is weapon specific interactions write that here
			match type:
				"Shotgun":
					@warning_ignore("integer_division")
					speed = randi_range(170 - ( (135 / num_attacks) * abs(i - num_attacks / 2.0)), 280 - ( (180 / num_attacks) * abs(i - num_attacks / 2.0)))
				_:
					pass
			var attack_position = attack_direction * spawn_distance + char_position
			spawn_attack(attack_direction,attack_position,node_attacking,"",flip)
			if(!split_attacks):
				attack_direction = direction.rotated(deg_to_rad((-attack_spread / 2) + randf_range(0,attack_spread)))
			else:
				attack_direction = attack_direction.rotated(deg_to_rad(attack_spread / (num_attacks-1)))
				if(random_spread):
					attack_direction = attack_direction.rotated(deg_to_rad(randf_range(-attack_spread / (2*num_attacks), attack_spread / (2*num_attacks))))
			
	else:
		var attack_position = attack_direction * spawn_distance + char_position
		spawn_attack(attack_direction,attack_position,node_attacking,"",flip)

func spawn_attack(attack_direction : Vector2, attack_position : Vector2, node_attacking : Node = null,particle_effect : String = "", flip : int = 1, variant : bool = false):
	if !c_owner:
		return
	var instance
	if variant:
		instance = load(special_attack_scene).instantiate()
		apply_remnants(instance)
		if instance.attack_type=="crowbar_melee":
			instance.scale.x *= flip *-1
		instance.direction = attack_direction
		instance.global_position = attack_position
		instance.c_owner = c_owner
		if c_owner.is_in_group("player"):
			instance.damage *= c_owner.damage_boost()
	else:
		instance = load(attack_scene).instantiate()
		apply_remnants(instance)
		if instance.attack_type=="crowbar_melee":
			instance.scale.x *= flip *-1
		instance.direction = attack_direction
		instance.global_position = attack_position
		instance.c_owner = c_owner
		instance.speed = speed
		if c_owner.is_in_group("player"):
			instance.damage = damage * c_owner.damage_boost()
		else:
			instance.damage = damage
		instance.lifespan = lifespan
		instance.hit_force = hit_force
		instance.start_lag = start_lag
		instance.cooldown = cooldown
		instance.pierce = pierce
	instance.is_purple = c_owner.is_purple if c_owner.is_in_group("player") else false
	if(particle_effect != ""):
		var effect = load("res://Game Elements/Effects/" + particle_effect + ".tscn").instantiate()
		instance.add_child(effect)
	c_owner.get_tree().get_root().get_node("LayerManager").room_instance.add_child(instance)

func apply_remnants(attack_instance):
	var remnants : Array[Remnant]
	if c_owner != null && c_owner.is_in_group("player"):
		var terramancer = load("res://Game Elements/Remnants/terramancer.tres")
		var aeromancer = load("res://Game Elements/Remnants/aeromancer.tres")
		var hydromancer = load("res://Game Elements/Remnants/hydromancer.tres")
		var intelligence = load("res://Game Elements/Remnants/intelligence.tres")
		if c_owner.is_purple:
			remnants = c_owner.get_tree().get_root().get_node("LayerManager").player_1_remnants
		else:
			remnants = c_owner.get_tree().get_root().get_node("LayerManager").player_2_remnants
		attack_instance.intelligence = null
		for rem in remnants:
			match rem.remnant_name:
				terramancer.remnant_name:
					if c_owner.velocity.length() <= .1:
						attack_instance.scale = attack_instance.scale * (1 + rem.variable_2_values[rem.rank-1] / 4)
						attack_instance.hit_force = attack_instance.hit_force * (1 + rem.variable_2_values[rem.rank-1] / 4)
				aeromancer.remnant_name:
					var similarity = attack_instance.direction.normalized().dot(c_owner.velocity.normalized())
					if(attack_instance.speed != 0):
						#Possibly add a min so it can't go lower than base damage? 
						#Nah thats lame
						attack_instance.damage = abs(attack_instance.damage * (((similarity * c_owner.velocity.length() * rem.variable_1_values[rem.rank-1] / 100) + attack_instance.speed) /  attack_instance.speed))
						attack_instance.speed = ((similarity * c_owner.velocity.length() * rem.variable_1_values[rem.rank-1] / 100) + attack_instance.speed)
					else:
						print(abs(attack_instance.damage * ((similarity * (.005) * c_owner.velocity.length() * rem.variable_1_values[rem.rank-1] / 100) + 1)))
						attack_instance.damage = abs(attack_instance.damage * ((similarity * (.005) * c_owner.velocity.length() * rem.variable_1_values[rem.rank-1] / 100) + 1))
						attack_instance.speed = (.5 * similarity * c_owner.velocity.length() * rem.variable_1_values[rem.rank-1] / 100)
				hydromancer.remnant_name:
					attack_instance.last_liquid = c_owner.last_liquid
					c_owner.last_liquid = Globals.Liquid.Buffer
				intelligence.remnant_name:
					attack_instance.intelligence = rem.duplicate(true)
				_:
					pass


var laser_camera_distancex = 240
var laser_camera_distancey = 128
func start_special(special_direction : Vector2, node_attacking : Node):
	match type:
		"Laser_Sword":
			var mesh_inst = load("res://Game Elements/Attacks/sword_special.tscn").instantiate()
			node_attacking.LayerManager.room_instance.add_child(mesh_inst)

			special_nodes.append(mesh_inst)
			

			var locations : Array[Vector2] = get_locations(node_attacking, special_direction)
			mesh_inst.draw_path(PackedVector2Array(locations))
		"Railgun":
			#Spawn Line2D
			pass
			
		"Crowbar":
			print("Start Crowbar")
			var setup = load("res://Game Elements/Attacks/crowbar_special/setup.tscn").instantiate()
			setup.tilemaplayer = node_attacking.LayerManager.room_instance.get_node("Ground")
			setup.available_tiles = node_attacking.LayerManager.placable_cells
			setup.global_position = node_attacking.global_position+special_direction*48
			node_attacking.LayerManager.room_instance.add_child(setup)

			special_nodes.append(setup)
		_ :
			pass

var laser_max_distance = 128 
var laser_min_distance = 16 
var laser_enemy_max = 7
var laser_angle =cos(PI/3)
func get_locations(start_node : Node,inital_direction : Vector2) -> Array[Vector2]: 
	
	
	var camera_position = start_node.LayerManager.camera.global_position
	var all_enemies = start_node.get_tree().get_nodes_in_group("enemy").filter(
		func(e) -> bool:
		return (abs(e.global_position.x-camera_position.x) < laser_camera_distancex 
			and abs(e.global_position.y-camera_position.y) < laser_camera_distancey 
			and e.hitable)
		)
	
	var best_chain: Array[Vector2] = [] # Stack stores: node, chain_length (index in chain), direction 
	var stack: Array = [] # Single mutable chain array reused across all frames 
	stack.push_back({ 	"node": start_node, 
						"direction": inital_direction,
						"chain": [start_node.global_position] as Array[Vector2]
						}) 
	while stack.size() > 0: 
		var frame = stack.pop_back() 
		var current_node: Node = frame["node"]
		var direction: Vector2 = frame["direction"]
		var chain: Array[Vector2] = frame["chain"]
		if chain.size() > best_chain.size(): 
			best_chain = chain.duplicate() # only duplicate when saving best 
		for enemy in all_enemies: 
			if enemy.global_position in chain:
				continue  # already visited in this path
			var offset = enemy.global_position - current_node.global_position 
			var offset_sq = offset.length_squared()
			if offset_sq > laser_max_distance * laser_max_distance or offset_sq < laser_min_distance * laser_min_distance: 
				continue 
			var offset_norm = offset.normalized() 
			# Instead of normalized vector + angle_to:
			var cos_angle = direction.dot(offset) / sqrt(offset_sq)  # direction is normalized
			if cos_angle < laser_angle:
				continue # Push next frame onto stack 
			# Create a new chain for this path
			var new_chain = chain.duplicate()
			new_chain.append(enemy.global_position)
			if new_chain.size() >= laser_enemy_max:
				return new_chain
			stack.push_back({
				"node": enemy,
				"direction": offset_norm,
				"chain": new_chain
			})

	return best_chain
	
func special_tick(special_direction : Vector2, node_attacking : Node):
	match type:
			"Laser_Sword":
				var locations : Array[Vector2] = get_locations(node_attacking, special_direction)
				special_nodes[0].draw_path(PackedVector2Array(locations))
			"Railgun":
				node_attacking.take_damage(1, null,Vector2(0,-1))
				var fire = preload("res://Game Elements/Particles/fire_damage.tscn").instantiate()
				fire.position = node_attacking.position
				node_attacking.LayerManager.room_instance.add_child(fire)
				pass
			"Crowbar":
				if special_nodes.size()> 1:
					var throw = preload("res://Game Elements/Particles/throw_particles.tscn").instantiate()
					var ray = cast_ray(node_attacking.global_position, special_direction, 1600,node_attacking)
					throw.global_position = node_attacking.global_position
					if ray:
						var position = (clamp((ray.position-node_attacking.global_position).length(),0,160)*special_direction)+node_attacking.global_position
						throw.global_position = position -special_direction *32
					node_attacking.LayerManager.room_instance.add_child(throw)
					if !is_instance_valid(special_nodes[1]):
						special_nodes.remove_at(1)
				if special_nodes.size()<=1:
					special_nodes[0].global_position = node_attacking.global_position+special_direction*48
			_:
				pass
	
	
func use_special(time_elapsed : float, is_released : bool, special_direction : Vector2, special_position : Vector2, node_attacking : Node) -> Array:
	var Effects : Array[Effect] = []
	if current_special_hits < special_hits:
		return Effects
	if !special_started:
		start_special(special_direction ,  node_attacking)
		special_started = true
	if(!is_released):
		match type:
			"Mace":
				pass
			"Crossbow":
				if(special_time_elapsed == 0.0):
					special_start_damage = damage
				if(special_time_elapsed <= 3.0):
					damage += (special_start_damage / 2) * time_elapsed
				var effect = load("res://Game Elements/Effects/max_charge.tres").duplicate(true)
				effect.cooldown = 20*time_elapsed
				effect.value1 = 0.15
				effect.gained(c_owner)
				Effects.append(effect)
				if(special_time_elapsed >= 2.0):
					effect = load("res://Game Elements/Effects/slow_down.tres").duplicate(true)
					effect.cooldown = 1*time_elapsed
					effect.value1 = 0.0
					effect.gained(c_owner)
					Effects.append(effect)
			"Railgun":
				if(special_time_elapsed <= 1.0):
					var effect = load("res://Game Elements/Effects/rail_charge.tres").duplicate(true)
					effect.cooldown = 20*time_elapsed
					effect.value1 = 0.04
					effect.gained(c_owner)
					Effects.append(effect)
				else:
					var check_forward
					if special_nodes.size() < 1:
						node_attacking.create_tween().tween_property(node_attacking.weapon_node.get_node("Sprite2D"),"modulate",Color(1.0, 0.0, 0.0, 1.0),1.0)
						var inst = load("res://Game Elements/Attacks/railgun_laser.tscn").instantiate()
						special_nodes.append(inst)
						inst.global_position = node_attacking.global_position + inst.size/-2.0 + special_direction*spawn_distance
						check_forward = cast_ray(node_attacking.global_position, special_direction, 1600,node_attacking)
						node_attacking.LayerManager.room_instance.add_child(inst)
						inst.fire_laser(node_attacking.global_position+special_direction*spawn_distance,check_forward.position,node_attacking)
					
					special_nodes[0].global_position = node_attacking.global_position + special_nodes[0].size/-2.0 + special_direction*spawn_distance
					check_forward = cast_ray(node_attacking.global_position, special_direction, 1600,node_attacking)
					special_nodes[0].update_points(node_attacking.global_position+special_direction*spawn_distance,check_forward.position)
					
					var effect = load("res://Game Elements/Effects/tether.tres").duplicate(true)
					effect.cooldown = 20*time_elapsed
					effect.value1 = 0.02
					effect.gained(c_owner)
					Effects.append(effect)
			_:
				pass
	else:
		if special_on_release:
			end_special(special_direction , special_position , node_attacking)
		else:
			special_cleanup()
		return Effects
		
	match type:
		"Laser_Sword":
			if floor(special_time_elapsed*8) !=special_time_period_elapsed:
				special_time_period_elapsed = floor(special_time_elapsed*8)
				special_tick(special_direction, node_attacking)
		"Railgun":
			if(special_time_elapsed >= 6.0 and special_time_elapsed < 12.0):
				if floor(special_time_elapsed*.5) !=special_time_period_elapsed:
					special_time_period_elapsed = floor(special_time_elapsed*.5)
					special_tick(special_direction, node_attacking)
			elif(special_time_elapsed >= 12.0 and special_time_elapsed < 16.0):
				if floor(special_time_elapsed) !=special_time_period_elapsed:
					special_time_period_elapsed = floor(special_time_elapsed)
					special_tick(special_direction, node_attacking)
			elif(special_time_elapsed >= 16.0):
				if floor(special_time_elapsed*2) !=special_time_period_elapsed:
					special_time_period_elapsed = floor(special_time_elapsed*2)
					special_tick(special_direction, node_attacking)
		"Crowbar":
			if floor(special_time_elapsed*60) !=special_time_period_elapsed:
				special_time_period_elapsed = floor(special_time_elapsed*60)
				special_tick(special_direction, node_attacking)
		_:
			pass
	special_time_elapsed += time_elapsed
	return Effects

func special_cleanup():
	special_started = false
	for node in special_nodes:
		if node and is_instance_valid(node) and node.has_method("kill"):
			node.kill()
		elif node and is_instance_valid(node):
			node.queue_free()
	special_nodes = []
	special_time_elapsed = 0.0
	special_time_period_elapsed = 0
	

func use_normal_attack(special_direction : Vector2, special_position : Vector2, node_attacking : Node):
	match type:
			"Laser_Sword":
				end_special(special_direction,special_position,node_attacking)
			"Crowbar":
				if special_nodes.size()>1:
					special_nodes[0].passify(node_attacking)
					#Launch
					#Place Target
					var target = preload("res://Game Elements/Attacks/crowbar_special/target.tscn").instantiate()
					var ray = cast_ray(node_attacking.global_position, special_direction, 1600,node_attacking)
					target.global_position = node_attacking.global_position
					if ray:
						var position = (clamp((ray.position-node_attacking.global_position).length(),0,160)*special_direction)+node_attacking.global_position
						target.global_position = position -special_direction *32
					node_attacking.LayerManager.room_instance.add_child(target)
					special_nodes[1].activate(target,node_attacking)
					node_attacking.create_tween().tween_property(target,"modulate",Color(1.0,1.0,1.0,1.0),.5)
					special_nodes = []
					end_special(special_direction,special_position,node_attacking)
					
				else:
					print("Punt")
					var attack = load("res://Game Elements/Attacks/crowbar_special/crowbar_projectile.tscn").instantiate()
					attack.room_root = node_attacking.LayerManager.room_instance
					attack.mask = special_nodes[0]
					attack.global_position = special_nodes[0].global_position
					node_attacking.LayerManager.room_instance.add_child(attack)
					special_nodes.append(attack)
					
			_:
				pass

func end_special(special_direction : Vector2, special_position : Vector2, node_attacking : Node):
		special_started = false
		match type:
			"Mace":
				pass
			"Laser_Sword":
				sword_special_attack(special_direction,node_attacking)
			"Crossbow":
				if(special_time_elapsed >= 5.0):
					damage += (special_start_damage / 2)
				if(special_time_elapsed >= 1.0):
					
					node_attacking.player_special_reset()
					spawn_attack(special_direction,special_position, node_attacking,"charged_particles")
					current_special_hits = 0
					damage = special_start_damage
					if node_attacking.weapons[0] == self:
						node_attacking.emit_signal("special_changed",false,0.0)
					else:
						node_attacking.emit_signal("special_changed",true,0.0)
			"Railgun":
				node_attacking.create_tween().tween_property(node_attacking.weapon_node.get_node("Sprite2D"),"modulate",Color(1.0, 1.0, 1.0, 1.0),1.0)
				if(special_time_elapsed > 1.0):
					current_special_hits = 0
			"Crowbar":
				current_special_hits = 0
				if node_attacking.weapons[0] == self:
					node_attacking.emit_signal("special_changed",false,0.0)
				else:
					node_attacking.emit_signal("special_changed",true,0.0)
			_:
				pass
		special_cleanup()

func cast_ray(origin: Vector2, direction: Vector2, distance: float, player_node : Node) -> Dictionary:
	var space = player_node.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(origin - direction, origin + direction * distance)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 1 << 0
	return space.intersect_ray(query)

func sword_special_attack(special_direction : Vector2,node_attacking : Node):
	current_special_hits = 0
	special_cleanup()
	var locations : Array[Vector2] = get_locations(node_attacking, special_direction)
	if locations.size() < 2:
		return # nothing to spawn

	var image_distance = 8.0 # distance between afterimages, adjust as needed
	var prev_pos = locations[0]

	# Spawn initial afterimage
	Spawner.spawn_after_image(
		node_attacking,
		node_attacking.LayerManager,
		Color(0.608, 1.0, 0.463, 1.0),Color(0.608, 1.0, 0.463, 1.0),
		0, 1.0, 1, 1,
		true,
		prev_pos
	)
	var count = 0
	node_attacking.move_speed *= 4.0
	for i in range(1, locations.size()):
		node_attacking.input_direction = (locations[i - 1] -locations[i]).normalized()
		spawn_attack(special_direction,locations[i], node_attacking,"",1,true)
		var start_pos = locations[i - 1]
		var end_pos = locations[i]
		var segment_vec = end_pos - start_pos
		var segment_length = segment_vec.length()
		var direction = segment_vec.normalized()
		var traveled = 0.0
		var spawn_pos = start_pos
		Spawner.spawn_after_image(
				node_attacking,
				node_attacking.LayerManager,
				Color(0.608, 1.0, 0.463, 1.0), Color(0.608, 1.0, 0.463, 1.0),
				0, 1.0, 1,1,
				true,
				spawn_pos
			)
		while traveled + image_distance <= segment_length:
			count = (count+1)% 4
			traveled += image_distance
			spawn_pos = start_pos + direction * traveled
			Spawner.spawn_after_image(
				node_attacking,
				node_attacking.LayerManager,
				Color(0.608, 1.0, 0.463, 1.0), Color(0.608, 1.0, 0.463, 1.0),
				0, 1.0, 1,1,
				true,
				spawn_pos
			)
			if count == 2:
				node_attacking.global_position = spawn_pos
				# Wait for the next frame before continuing
				await node_attacking.get_tree().process_frame
				current_special_hits = 0
		if i == locations.size()-1:
			node_attacking.global_position = spawn_pos
	node_attacking.move_speed /= 4.0
	current_special_hits = 0
	if node_attacking.weapons[0] == self:
		node_attacking.emit_signal("special_changed",false,0.0)
	else:
		node_attacking.emit_signal("special_changed",true,0.0)
