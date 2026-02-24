extends Area2D


func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	$AnimationPlayer.play("fire")
	$AnimationPlayer.seek(randf()*2.0, true)

func _process(_delta: float) -> void:
	if !$CollisionShape2D.disabled:
		for child in get_tree().get_root().get_node("LayerManager").room_instance.get_children():
			if child.is_in_group("timefabric"):
				if child.position.distance_to(position) < 10:
					child.queue_free()
					


func _on_body_entered(body):
	if body.has_method("take_damage") and _crafter_chance(body):
		body.take_damage(3, null,Vector2(0,-1),self)
		var fire = preload("res://Game Elements/Particles/fire_damage.tscn").instantiate()
		fire.position = body.position
		get_parent().add_child(fire)

		
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
