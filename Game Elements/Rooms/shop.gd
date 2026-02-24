extends Node2D

var shop_open = false
var moving_tentacles : Array[Node] = []
var opening_stage : int = 0
var curr_pos = Vector2.ZERO
var ten_reward_num
var time_passed = 0.0

func _ready() -> void:
	for node in get_node("Tentacles").get_children():
		if node.is_in_group("tentacle"):
			node.set_hole($Cracks.global_position+Vector2(8,32))
		if node.is_in_group("holds_reward"):
			node.shrink(.88)
	$Cracks.enabled = false
			
func _process(delta: float) -> void:
	if time_passed >= 2.0:
		$Cracks.enabled = true
	if curr_pos != position:
		curr_pos= position
		get_node("Items").material.set_shader_parameter("node_offset",position)
		for node in get_node("Tentacles").get_children():
			if node.is_in_group("tentacle"):
				node.get_node("SubViewportContainer").material.set_shader_parameter("node_offset",position)
	for node in moving_tentacles:
		if node.reward:
			node.reward.global_position = node.target.global_position
	if $Cracks.enabled == false:
		time_passed+=delta

func check_rewards(player_node : Node) -> bool:
	var layer_manager = get_tree().get_root().get_node("LayerManager")
	for item in $Items.get_children():
		if player_node in item.tracked_bodies:
			if item.cost <= layer_manager.timefabric_collected:
				layer_manager.timefabric_collected-=item.cost
				#for node in moving_tentacles:
					#if node.reward and node.reward == item:
						#node.shrink(.8,false)
				match item.get_meta("reward_type"):
					"remnant":
						layer_manager._open_remnant_popup()
						item.queue_free()
						return true
					"remnantupgrade":
						layer_manager._open_upgrade_popup()
						item.queue_free()
						return true
					"healthupgrade":
						if layer_manager.is_multiplayer:
							layer_manager.player2.change_health(5,5)
						layer_manager.player1.change_health(5,5)
						var particle =  load("res://Game Elements/Particles/heal_particles.tscn").instantiate()
						particle.global_position = item.global_position
						layer_manager.room_instance.add_child(particle)
						item.queue_free()
						return true
					"health":
						if layer_manager.is_multiplayer:
							layer_manager.player2.change_health(5)
						layer_manager.player1.change_health(5)
						var particle =  load("res://Game Elements/Particles/heal_particles.tscn").instantiate()
						particle.global_position = item.global_position
						layer_manager.room_instance.add_child(particle)
						item.queue_free()
						return true
	return false

func open_shop(offered_items : int = 4) -> void:
	ten_reward_num = get_tree().get_root().get_node("LayerManager").reward_num.duplicate()
	if shop_open:
		return
	shop_open = true

	var tentacle_list: Array[Node] = []

	for node in get_node("Tentacles").get_children():
		if node.is_in_group("tentacle") and node.is_in_group("holds_reward"):
			tentacle_list.append(node)

	tentacle_list.shuffle()
	moving_tentacles = tentacle_list.slice(0, min(offered_items, tentacle_list.size()))
	var hole_bottom : Vector2 = $ItemLocation.global_position

	for tentacle in moving_tentacles:
		_animate_tentacle_target(tentacle, hole_bottom)

func _animate_tentacle_target(tentacle: Node, hole_bottom: Vector2) -> void:
	var target: Node2D = tentacle.target
	if target == null:
		return

	var start_pos := target.global_position
	var end_pos : Vector2 = $Cracks.global_position+Vector2(8,32) + (target.origin - ($Cracks.global_position+Vector2(8,32))) * (1/.8)

	var control := Vector2(hole_bottom.x,start_pos.y-160)

	var in_duration := 3
	var out_duration := 5
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	# Forward
	tween.tween_method(
		func(t):
			target.global_position = quadratic_bezier(start_pos, control, hole_bottom, t),
		0.0,
		1.0,
		in_duration
	)
	tween.tween_callback(
	func():
		_on_tentacle_reached_hole(tentacle)
	)
	# Reverse
	tween.tween_method(
		func(t):
			target.global_position = quadratic_bezier(end_pos, control, hole_bottom, t),
		1.0,
		0.0,
		out_duration
	)
	await tween.finished
	for node in moving_tentacles:
		if node.reward:
			node.reward.enabled = true
			if len(node.reward.tracked_bodies) != 0:
				node.reward.prompt1.visible = true

func _on_tentacle_reached_hole(tentacle: Node) -> void:
	var layer_manager = get_tree().get_root().get_node("LayerManager")
	tentacle.shrink(1/.8)
	var reward_type = null
	var reward =null
	while reward_type == null:
		var reward_value = layer_manager.calculate_reward(ten_reward_num)
		match reward_value:
			0:
				reward_type = Globals.Reward.Remnant
				ten_reward_num[reward_value] = ten_reward_num[reward_value]/2.0
			2:
				if layer_manager._upgradable_remnants():
					reward_type = Globals.Reward.RemnantUpgrade
					ten_reward_num[reward_value] = ten_reward_num[reward_value]/2.0
			3:
				reward_type = Globals.Reward.HealthUpgrade
				ten_reward_num[reward_value] = ten_reward_num[reward_value]/2.0
			4:
				reward_type = Globals.Reward.Health
				if layer_manager.is_multiplayer:
					if layer_manager.player1.current_health == layer_manager.player1.max_health and layer_manager.player2.current_health == layer_manager.player2.max_health:
						reward_type = null	
				elif layer_manager.player1.current_health == layer_manager.player1.max_health:
					reward_type = null
				if reward_type!= null:
					ten_reward_num[reward_value] = ten_reward_num[reward_value]/2.0
	match reward_type:
		Globals.Reward.Remnant:
			reward = load("res://Game Elements/Objects/remnant_orb.tscn").instantiate()
			reward.set_meta("reward_type", "remnant")
		Globals.Reward.RemnantUpgrade:
			reward = load("res://Game Elements/Objects/upgrade_orb.tscn").instantiate()
			reward.set_meta("reward_type", "remnantupgrade")
		Globals.Reward.HealthUpgrade:
			reward = load("res://Game Elements/Objects/health_upgrade.tscn").instantiate()
			reward.set_meta("reward_type", "healthupgrade")
		Globals.Reward.Health:
			reward = load("res://Game Elements/Objects/health.tscn").instantiate()
			reward.set_meta("reward_type", "health")
	
	get_node("Items").add_child(reward)
	tentacle.reward = reward
	reward.enabled = false
	reward.z_index = 0
	reward.y_sort_enabled = false
	reward.global_position = $ItemLocation.global_position
	
	var feet = reward.get_node_or_null("Feet")
	if feet !=null:
		feet.queue_free()
	reward.set_cost(200)

func quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var q0 := p0.lerp(p1, t)
	var q1 := p1.lerp(p2, t)
	return q0.lerp(q1, t)
