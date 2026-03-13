extends BTAction
@export var player_position_var: String = "target_pos"
@export var player_positions: String = "player_positions"
@export var player_idx: String = "player_idx"
@export var player_healths: String = "player_healths"
# determines the distance at which and enemy can detect a player

func _tick(_delta: float) -> Status:
	agent = get_agent()
	
	# get all player positions
	var positions = get_blackboard().get_var(player_positions)
	
	var healths: Array = get_blackboard().get_var(player_healths)
	
	# gets all distances squared between enemies and players 
	var distances_squared = []
	for pos in positions: 
		distances_squared.append(agent.global_position.distance_squared_to(pos))
	# double check thos distances exist
	if not distances_squared:
		return FAILURE
	
	var agro_dist = agent.agro_distance
	# looks for either enemy, and checks if they are in range, sends that position if they are
	for i in range(distances_squared.size()): 
		var pos = positions[i]
		if healths[i] <= 0:
			continue

		if agent.global_position.distance_squared_to(pos) > agro_dist * agro_dist:
			continue

		var direction = (pos - agent.global_position).normalized()
		var ray = cast_ray(agent.global_position, direction, agro_dist, agent)

		# ray is empty -> nothing blocking, can see player
		# ray.collider is player -> can see player
		if not ray.has("collider") or ray.collider.is_in_group("player"):
			blackboard.set_var(player_position_var, pos)
			blackboard.set_var(player_idx, i)
			blackboard.set_var("state", "agro")
			return SUCCESS
	
	return SUCCESS
func cast_ray(origin: Vector2, direction: Vector2, distance: float, player_node : Node) -> Dictionary:
	var space = player_node.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(origin, origin + direction * distance)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = (1 << 0) | (1 << 1)
	return space.intersect_ray(query)
