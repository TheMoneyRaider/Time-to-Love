extends Area2D

var direction = Vector2.RIGHT
@export var speed = 60.0
#How fast the attack is moving
@export var damage = 1.0
#How much damage the attack will do
@export var lifespan = 1.0
#How long attack lasts in seconds before despawning
@export var hit_force = 0.0
#How much speed it adds to deflected objects
@export var knockback_force = 100.0
#How much it knocksback enemies
@export var start_lag = 0.0
#How much time after pressing attack does the attack start in seconds
@export var cooldown = .5
#How many enemies the attack will pierce through (-2 for inf)
@export var pierce = 0.0
#If the attack can hit walls
@export var wall_collision = true
#If the attack damages walls
@export var wall_damage = false
var hit_nodes = {}
#The attack type
@export var attack_type : String = ""
@export var deflectable : bool = false
@export var deflects : bool = false
@export var i_frames : int = 20
@export var c_owner: Node = null
@export var repeat_hits : bool = false
@export var creates_indicators : bool = true
@export var spawn_particle : PackedScene = null
@export var animation : String = ""
var combod : bool = false
var is_purple : bool = false

var hack1 : Remnant = null
var hack2 : Remnant = null

var frozen := true
var intelligence : Remnant = null

var LayerManager : Node = null

var special_nodes : Array[Node] = []

#Special Variables
var life = 0.0
var last_liquid : Globals.Liquid = Globals.Liquid.Buffer

#Multiplies the Speed, Damage, Lifespan adn Hit_Force of attack by given values
func mult(speed_mult, damage_mult = 1, lifespan_mult = 1, hit_force_mult = 1):
	self.speed = self.speed * speed_mult
	self.damage = self.damage * damage_mult
	self.lifespan = self.lifespan * lifespan_mult
	self.hit_force = self.hit_force * hit_force_mult 

func set_values(attack_speed = self.attack_speed, attack_damage = self.damage, attack_lifespan = self.lifespan, attack_hit_force = self.hit_force):
	self.speed = attack_speed
	self.damage = attack_damage
	self.lifespan = attack_lifespan
	self.hit_force = attack_hit_force

func ready_hacks():
	var hack = load("res://Game Elements/Remnants/hack.tres")
	for rem in LayerManager.player_1_remnants:
		if rem.remnant_name == hack.remnant_name:
			hack1=rem.duplicate(true)
			break
	for rem in LayerManager.player_2_remnants:
		if rem.remnant_name == hack.remnant_name:
			hack2=rem.duplicate(true)
			break
			

func _ready():
	LayerManager = get_tree().get_root().get_node("LayerManager")
	ready_hacks()
	frozen = true
	if start_lag > 0.0:
		await get_tree().create_timer(start_lag).timeout
	frozen = false
	if spawn_particle:
		var inst = spawn_particle.instantiate()
		inst.global_position = global_position
		if attack_type!="crowbar_explosion":
			inst.rotation = direction.angle()
		get_parent().add_child(inst)
	if animation!= "" and $AnimationPlayer:
		$AnimationPlayer.play(animation)
	if attack_type == "death mark":
		if c_owner.is_purple:
			$Sprite2D.texture = preload("res://art/Sprout Lands - Sprites - Basic pack/Characters/dead_purple.png")
		else:
			$Sprite2D.texture = preload("res://art/Sprout Lands - Sprites - Basic pack/Characters/dead_orange.png")
	rotation = direction.angle() + PI/2
	if attack_type == "explosion":
		rotation = 0
	if attack_type == "slug":
		special_nodes.append(load("res://Game Elements/Attacks/slug_seperate.tscn").instantiate())
		special_nodes[-1].global_position = global_position
		special_nodes[-1].global_rotation = global_rotation
		get_parent().add_child(special_nodes[-1])
		special_nodes[-1].setup(self)
	



func change_direction():
	if debug_draw_detection:
		_debug_rays.clear()
	var enemies = {}
	
	var dist_scale = intelligence.variable_2_values[intelligence.rank-1]
	var max_angle = intelligence.variable_3_values[intelligence.rank-1]
	var turn_strength = intelligence.variable_4_values[intelligence.rank-1]

	var forward = direction.normalized()

	# Collect valid enemies
	for enemy in get_parent().get_children():
		if !enemy.is_in_group("enemy"):
			continue
		var to_enemy = enemy.global_position - global_position
		var dist = to_enemy.length() / dist_scale / 16.0
		if dist > 1:
			continue
		var angle = abs(rad_to_deg(forward.angle_to(to_enemy)))
		if angle <= max_angle:
			# lower score = better
			var score = dist + angle/max_angle
			var ray = cast_ray(global_position, to_enemy.normalized(), 1600, self)
			if dist * dist_scale <= (ray.position -global_position).length() / 16.0:
				enemies[enemy] = score
				if debug_draw_detection:
					_debug_rays.append({
						"from": global_position,
						"to": enemy.global_position,
						"hit": true,
						"score": score
					})
			elif debug_draw_detection:
				_debug_rays.append({
					"from": global_position,
					"to": ray.position,
					"hit": false,
					"score": 0.0
				})
				

	if debug_draw_detection:
		queue_redraw()
	if enemies.is_empty():
		return
	#Pick best enemy
	var best_enemy = null
	var best_score = INF

	for enemy in enemies:
		if enemies[enemy] < best_score:
			best_score = enemies[enemy]
			best_enemy = enemy
	# Steer velocity smoothly
	if best_enemy:
		var to_enemy = (best_enemy.global_position - global_position).normalized()
		var angle = abs(rad_to_deg(forward.angle_to(to_enemy)))
		var angle_ratio = clamp(turn_strength/ float(angle),0.0,1.0)
		direction = lerp(direction, to_enemy, angle_ratio)
		rotation = direction.angle() + PI/2

func cast_ray(origin: Vector2, in_direction: Vector2, distance: float, player_node : Node) -> Dictionary:
	var space = player_node.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(origin - in_direction, origin + in_direction * distance)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 1 << 0
	return space.intersect_ray(query)

var _debug_rays : Array = []   # [{from, to, hit, score}]
@export var debug_draw_detection := false
func _draw() -> void:
	if !debug_draw_detection:
		return

	for r in _debug_rays:
		var from_local = to_local(r.from)
		var to_local_pos = to_local(r.to)

		var color = Color.RED if !r.hit else Color.GREEN
		color.a = 1.0-(r.score / 2.0)

		draw_line(from_local, to_local_pos, color, 2.0)
		draw_circle(to_local_pos, 3.0, color)
	

func _process(delta):
	if attack_type == "ls_melee":
		global_position = c_owner.global_position
	if intelligence and speed > 0 and attack_type != "slug":
		change_direction()
	if frozen:
		return
	if attack_type == "laser":
		if has_method("get_overlapping_bodies"):
			for body in get_overlapping_bodies():
				intersection(body)
	if attack_type != "slug":
		position += direction * speed * delta
	life+=delta
	if attack_type == "smash":
		get_node("CollisionShape2D").shape.radius = lerp(8,16,life/lifespan)
	if life < lifespan:
		return
	if attack_type == "death mark":
		c_owner.die(true,true)
	for node in special_nodes:
		node.queue_free()
	queue_free()
	
func apply_damage(body : Node, n_owner : Node, damage_dealt : int, a_direction: Vector2) -> int:
	#Computer Hack Remnant
	var hack_chance1 = 0.0 if !hack1 else hack1.variable_1_values[hack1.rank-1]/100.0
	var hack_chance2 = 0.0 if !hack2 else hack2.variable_1_values[hack2.rank-1]/100.0
	if hack_chance1 > randf():
		n_owner = LayerManager.player1
	if hack_chance2 > randf():
		n_owner = LayerManager.player1
		if Globals.is_multiplayer:
			n_owner = LayerManager.player2
	if body == n_owner:
		return 0
	if n_owner.is_in_group("player") and body.is_in_group("player"):
		return 0
	if !n_owner.is_in_group("player") and !body.is_in_group("player"):
		return 0
	if body.has_method("take_damage"):
		body.take_damage(damage_dealt,n_owner,a_direction,self, i_frames,creates_indicators)
		return 1
	if wall_damage:
		get_tree().get_root().get_node("LayerManager")._damage_indicator(0, n_owner,a_direction, self,null)
	return -1
	

func intersection(body):
	if c_owner == null:
		return
	if body.get("c_owner") != null and !is_instance_valid(body.c_owner):
		return
	if attack_type == "laser" and life < .5:
		return
	if attack_type == "death mark":
		if body != c_owner and body.is_in_group("player"):
			c_owner.die(false)
		return
	
	if(!hit_nodes.has(body)):
		match apply_damage(body,c_owner,damage,direction):
			1:
				pierce -= 1
				if attack_type!= "laser" and attack_type!= "binary_melee":
					hit_nodes[body] = null
			0:
				pass
			-1:
				pierce -= 1
				if(wall_collision):
					queue_free()
	if pierce == -1:
		queue_free()


func _on_body_entered(body):
	if body.is_in_group("player") and attack_type == "slug" and body == c_owner:
		c_owner.cooldowns[is_purple as int]=max(c_owner.cooldowns[is_purple as int]-3,0.0)
		special_nodes[-1].queue_free()
		queue_free()
		return
	intersection(body)

func deflect(hit_direction, hit_speed, deflection_area):
	if attack_type=="laser":
		get_tree().get_root().get_node("LayerManager")._damage_indicator(c_owner.max_health, deflection_area.c_owner,hit_direction, deflection_area,c_owner.get_node("Segment1"))
		get_tree().get_root().get_node("LayerManager")._damage_indicator(c_owner.max_health, deflection_area.c_owner,hit_direction, deflection_area,c_owner.get_node("Segment2"))
		var bt_player = c_owner.get_node("BTPlayer")
		var board = bt_player.blackboard
		if board:
			board.set_var("kill_laser", true)
			board.set_var("kill_damage", c_owner.max_health)
			board.set_var("kill_direction", hit_direction)
		return
	direction = hit_direction
	rotation = direction.angle() + PI/2
	damage = round(damage * ((hit_speed + speed) / speed))
	speed = speed + hit_speed
	
		

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("attack") and area.deflectable == true and deflects and is_instance_valid(area.c_owner):
		if area.attack_type =="laser":
			if area.life > .5:
				return
			area.c_owner.take_damage(self.damage,c_owner,direction,self,creates_indicators)
		if area.attack_type =="binary_melee":
			print("DEFLECT")
			area.c_owner.get_node("Core")._deflect_melee_attack()
			area.c_owner.take_damage(self.damage,c_owner,direction,self,creates_indicators)
			area.c_owner.take_damage(self.damage,c_owner,direction,self,creates_indicators)
			return
		area.deflect(direction, hit_force,self)
		area.c_owner = c_owner
		area.is_purple = is_purple
		area.hit_nodes = {}
		for area_intr in area.get_overlapping_areas():
			area._on_body_entered(area_intr)
	if area.is_in_group("enemy") or area.is_in_group("player"):
		intersection(area)


func _on_body_exited(body: Node2D) -> void:
	if repeat_hits:
		hit_nodes.erase(body)
