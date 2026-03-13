extends Resource
class_name Effect

# Exposed fields for editor
@export var cooldown: float = 1.0
@export var type: String = "Error"
var value1: float = 0.0
var failed = false
var saved_nodes : Array[Node] = []



func tick(delta : float, node_to_change : Node):
	if cooldown > 0:
		cooldown-=delta
	if cooldown <= 0 and !failed:
		cooldown=0
		lost(node_to_change)
	
func gained(node_to_change : Node):
	match type:
		"winter":
			node_to_change.move_speed = ((100-value1)/100 * node_to_change.move_speed)
			var particle =  load("res://Game Elements/Particles/winter_particles.tscn").instantiate()
			particle.position = node_to_change.position
			node_to_change.get_parent().add_child(particle)
		"slow":
			node_to_change.move_speed = ((1-value1) * node_to_change.move_speed)
			var particle =  load("res://Game Elements/Particles/water_particles.tscn").instantiate()
			particle.position = node_to_change.position
			node_to_change.get_parent().add_child(particle)
		"tether":
			node_to_change.move_speed = ((1-value1) * node_to_change.move_speed)
		"charged":
			node_to_change.move_speed = ((1-value1) * node_to_change.move_speed)
			var particle =  load("res://Game Elements/Particles/charged_particles.tscn").instantiate()
			particle.position = node_to_change.position
			node_to_change.get_parent().add_child(particle)
		"speed":
			node_to_change.move_speed = ((1+value1) * node_to_change.move_speed)
		"stun":
			var particle =  load("res://Game Elements/Particles/stun_particles.tscn").instantiate()
			particle.position = node_to_change.position
			saved_nodes.append(particle)
			node_to_change.get_parent().add_child(particle)
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
		"rail_charge":
			node_to_change.move_speed = ((1-value1) * node_to_change.move_speed)
			var particle =  load("res://Game Elements/Particles/railgun_charge_particles.tscn").instantiate()
			particle.position = node_to_change.position
			node_to_change.get_parent().add_child(particle)
		"burn":
			var particle =  load("res://Game Elements/particles/burn_particles.tscn").instantiate()
			particle.lifetime = cooldown
			node_to_change.add_child(particle)
					
			

func lost(node_to_change : Node):
	match type:
		"winter":
			node_to_change.move_speed = node_to_change.move_speed * 100 / (100-value1)
		"slow":
			node_to_change.move_speed = node_to_change.move_speed * 1 / (1-value1)
		"tether":
			node_to_change.move_speed = node_to_change.move_speed * 1 / (1-value1)
		"charged":
			node_to_change.move_speed = node_to_change.move_speed * 1 / (1-value1)
		"burn":
			if(node_to_change.has_method("take_damage")):
				node_to_change.take_damage(value1, null)
		"speed":
			node_to_change.move_speed = node_to_change.move_speed * 1 / (1+value1)
		"stun":
			var play = node_to_change.get_node_or_null("BTPlayer")
			if play:
				play.active = true
		"forcefield":
			if node_to_change.is_in_group("player"):
				if node_to_change.forcefield_active:
					var has_more = 0
					for effect in node_to_change.effects:
						if effect.type=="forcefield":
							has_more +=1
					if has_more <= 1:
						node_to_change.hide_forcefield(.25)
		"rail_charge":
			node_to_change.move_speed = node_to_change.move_speed * 1 / (1-value1)
	
	for node in saved_nodes:
		if node and !node.is_queued_for_deletion():
			if node.has_method("kill"):
				node.kill()
			else:
				node.queue_free()
