extends Resource
class_name Effect

@export var cooldown: float = 1.0
@export var type: String = "Error"
var life : float = 0.0
var value1: float = 0.0
var original_cooldown : float
var failed = false
var saved_nodes: Array[Node] = []
var saved_reference : Node
func tick(delta: float, node_to_change: Node):
	match type:
		"bleed":
			#print(str(floor((cooldown-delta)*2.0)) +"    "+str(floor(cooldown*2.0)))
			if floor((cooldown-delta)*2.0)!= floor(cooldown*2.0) and floor(original_cooldown*2.0) != floor(cooldown*2.0):
				node_to_change.take_damage(value1,saved_reference)
				var particle = load("res://Game Elements/Particles/bleed_particles.tscn").instantiate()
				particle.position = node_to_change.position
				node_to_change.get_parent().add_child(particle)
	if cooldown > 0:
		cooldown -= delta
	if cooldown <= 0 and !failed:
		cooldown = 0
		lost(node_to_change)
					

func _get_or_spawn_particle(scene_path: String, node_to_change: Node, particle_index : int = -1) -> Node:
	# Return existing particle if already spawned
	
	if particle_index >=0 and node_to_change.effect_stacks[particle_index] > 0 and is_instance_valid(node_to_change.effect_particles[particle_index]):
		node_to_change.effect_stacks[particle_index] += 1
		node_to_change.effect_particles[particle_index].position = node_to_change.position
		return node_to_change.effect_particles[particle_index]
	# Otherwise spawn once and save it
	var particle = load(scene_path).instantiate()
	particle.position = node_to_change.position
	node_to_change.get_parent().add_child(particle)
	node_to_change.effect_particles[particle_index] = particle
	node_to_change.effect_stacks[particle_index] += 1
	return particle

func _update_particle_intensity(particle: Node, intensity: float) -> void:
	# Scale amount and speed to reflect stack count visually
	if particle.has_method("set") and particle is GPUParticles2D or particle is GPUParticles3D:
		particle.amount = int(clamp(particle.amount * intensity, 1, 500))
		if particle.process_material:
			var mat = particle.process_material
			if mat is ParticleProcessMaterial:
				mat.initial_velocity_min *= intensity
				mat.initial_velocity_max *= intensity

func gained(node_to_change: Node):
	var intensity
	original_cooldown = cooldown
	
	match type:
		"winter":
			intensity = 1.0 + (node_to_change.effect_stacks[0] - 1) * 0.4
			node_to_change.move_speed = ((100 - value1) / 100 * node_to_change.move_speed)
			var p = _get_or_spawn_particle("res://Game Elements/Particles/winter_particles.tscn", node_to_change,0)
			_update_particle_intensity(p, intensity)
		"slow":
			intensity = 1.0 + (node_to_change.effect_stacks[1] - 1) * 0.4
			node_to_change.move_speed = ((1 - value1) * node_to_change.move_speed)
			var p = _get_or_spawn_particle("res://Game Elements/Particles/water_particles.tscn", node_to_change,1)
			_update_particle_intensity(p, intensity)
		"charged":
			intensity = 1.0 + (node_to_change.effect_stacks[2] - 1) * 0.4
			node_to_change.move_speed = ((1 - value1) * node_to_change.move_speed)
			var p = _get_or_spawn_particle("res://Game Elements/Particles/charged_particles.tscn", node_to_change,2)
			_update_particle_intensity(p, intensity)
		"rail_charge":
			node_to_change.move_speed = ((1 - value1) * node_to_change.move_speed)
		"tether":
			node_to_change.move_speed = ((1 - value1) * node_to_change.move_speed)
		"speed":
			node_to_change.move_speed = ((1 + value1) * node_to_change.move_speed)
		"stun":
			# Stun only needs one particle, already uses saved_nodes
			if saved_nodes.size() == 0:
				var particle = load("res://Game Elements/Particles/stun_particles.tscn").instantiate()
				particle.position = node_to_change.position
				saved_nodes.append(particle)
				node_to_change.get_parent().add_child(particle)
			if node_to_change.is_in_group("enemy"): node_to_change.stunned = true
			var play = node_to_change.get_node_or_null("BTPlayer")
			if play:
				if !play.active:
					failed = true
					return
				play.active = false
		"forcefield":
			if node_to_change.is_in_group("player"):
				if !node_to_change.forcefield_active:
					node_to_change.show_forcefield(.25)
		"burn":
			# Burn is one-shot on lost(), just needs one particle
			if saved_nodes.size() == 0:
				var particle = load("res://Game Elements/Particles/burn_particles.tscn").instantiate()
				particle.lifetime = cooldown
				node_to_change.add_child(particle)
				saved_nodes.append(particle)
		"damage":
			node_to_change.damage_multiplier *= (100.0 +value1) / 100.0

func lost(node_to_change: Node):
	match type:
		"winter":
			node_to_change.effect_stacks[0] -= 1
			node_to_change.move_speed = node_to_change.move_speed * 100 / (100 - value1)
		"slow":
			node_to_change.effect_stacks[1] -= 1
			node_to_change.move_speed = node_to_change.move_speed * 1 / (1 - value1)
		"tether":
			node_to_change.move_speed = node_to_change.move_speed * 1 / (1 - value1)
		"charged":
			node_to_change.effect_stacks[2] -= 1
			node_to_change.move_speed = node_to_change.move_speed * 1 / (1 - value1)
		"burn":
			if node_to_change.has_method("take_damage"):
				node_to_change.take_damage(value1, null)
		"speed":
			node_to_change.move_speed = node_to_change.move_speed * 1 / (1 + value1)
		"stun":
			if node_to_change.is_in_group("enemy"): node_to_change.stunned = false
			var play = node_to_change.get_node_or_null("BTPlayer")
			if play:
				play.active = true
		"forcefield":
			if node_to_change.is_in_group("player"):
				if node_to_change.forcefield_active:
					var has_more = 0
					for effect in node_to_change.effects:
						if effect.type == "forcefield":
							has_more += 1
					if has_more <= 1:
						node_to_change.hide_forcefield(.25)
		"rail_charge":
			node_to_change.move_speed = node_to_change.move_speed * 1 / (1 - value1)
		"damage":
			node_to_change.damage_multiplier /= (100.0 +value1) / 100.0
	
	for part_idx in range(9):
		if(node_to_change.effect_stacks[part_idx] <= 0 and is_instance_valid(node_to_change.effect_particles[part_idx])):
			if !node_to_change.effect_particles[part_idx].is_queued_for_deletion():
				if node_to_change.effect_particles[part_idx].has_method("kill"):
					node_to_change.effect_particles[part_idx].kill()
				else:
					node_to_change.effect_particles[part_idx].queue_free()
	for node in saved_nodes:
		if node and !node.is_queued_for_deletion():
			if node.has_method("kill"):
				node.kill()
			else:
				node.queue_free()
	saved_nodes.clear()
