extends BTAction

@export var player_position_var: String = "target_pos"
@export var player_positions: String = "player_positions"
@export var player_idx: String = "player_idx"
@export var player_healths: String = "player_healths"

func _tick(_delta : float) -> Status:
	var players = agent.get_tree().get_nodes_in_group("player")
	
	if not players:
		push_error("No players found in 'player' group")
		return FAILURE
	
	var positions_array = []
	var player_health_array = []
	
	for player in players: 
		var direction = player.global_position - agent.global_position
		direction = direction.normalized() * -1
		var ray = cast_ray(player.global_position, direction, 50, player)
		if(ray == { }):
			ray["position"] = player.global_position + (direction * 50)
		else:
			ray.position  = ray.position - direction * 20
		positions_array.append(ray.position)
		player_health_array.append(player.current_health)
	
	blackboard.set_var("target_type",1)
	blackboard.set_var(player_positions, positions_array)
	blackboard.set_var(player_healths, player_health_array)
	if blackboard.get_var("state") == "agro":
		var player_agressing = blackboard.get_var(player_idx)
		blackboard.set_var(player_position_var, positions_array[player_agressing])
	
	return SUCCESS
		
		#blackboard.get_var(player_positions, positions_array)

func cast_ray(origin: Vector2, direction: Vector2, distance: float, player_node : Node) -> Dictionary:
	var space = player_node.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(origin - direction, origin + direction * distance)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 1 << 0
	return space.intersect_ray(query)
