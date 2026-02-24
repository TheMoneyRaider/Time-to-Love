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
	anim.play("activate")
	await anim.animation_finished
	active = true
	for body in tracked_bodies:
		if _crafter_chance(body):
			body.take_damage(3, null, Vector2(0,-1), self)
	while !tracked_bodies.is_empty():
		await get_tree().process_frame
	anim.play("deactivate")
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
			body.take_damage(3, null,Vector2(0,-1),self)

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
