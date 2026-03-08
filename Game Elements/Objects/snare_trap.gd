extends Area2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var hitbox: CollisionShape2D = $CollisionShape2D

var active: bool = false
var running: bool = false
var tracked_bodies: Array = []

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func activate():
	anim.play("Extend")
	active = true
	for body in tracked_bodies:
		if _crafter_chance(body):
			var do_effect = true
			for effect in body.effects:
				if effect.type == "speed":
					do_effect = false
			if do_effect:
				var new_effect = load("res://Game Elements/Effects/speed.tres").duplicate(true)
				new_effect.cooldown = .2
				new_effect.value1 = -.8
				new_effect.gained(body)
				body.effects.append(new_effect)
	while !tracked_bodies.is_empty():
		await get_tree().create_timer(.21).timeout
		activate()
	anim.play("Retract")
	active = false
	await anim.animation_finished

func _on_body_entered(body):
	if body.has_method("take_damage"):
		tracked_bodies.append(body)
	if !active:
		if !running and body.has_method("take_damage"):
			activate()
			return
	elif body.has_method("take_damage"):
		if _crafter_chance(body):
			var effect = load("res://Game Elements/Effects/speed.tres").duplicate(true)
			effect.cooldown = 1
			effect.value1 = -.8
			effect.gained(body)
			body.effects.append(effect)

func _on_body_exited(body):
	if body in tracked_bodies:
		tracked_bodies.erase(body)
		
func _crafter_chance(node_to_damage : Node) -> bool:
	if !node_to_damage.is_in_group("player"):
		return true
	randomize()
	var remnants : Array[Remnant]
	if node_to_damage.is_purple:
		remnants = get_tree().get_root().get_node("LayerManager").player_1_remnants
	else:
		remnants = get_tree().get_root().get_node("LayerManager").player_2_remnants
	var crafter = load("res://Game Elements/Remnants/crafter.tres")
	for rem in remnants:
		if rem.remnant_name == crafter.remnant_name:
			if rem.variable_1_values[rem.rank-1] > randf()*100:
				var particle =  load("res://Game Elements/Particles/crafter_particles.tscn").instantiate()
				particle.position = self.position
				get_parent().add_child(particle)
				return false
			
	return true
