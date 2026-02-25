extends BTAction



func _tick(_delta: float) -> Status:
	var tween  = agent.create_tween()
	tween.tween_property(agent.get_node("Segments"),"modulate",Color(0.0, 0.625, 0.208, 1.0),1.5)
	
	var inst = load("res://Game elements/Particles/singul_melee_charge_particles.tscn").instantiate()
	inst.global_position = agent.global_position
	agent.get_parent().add_child(inst)
	return SUCCESS
