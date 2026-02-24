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
		if distances_squared[i] <= agro_dist * agro_dist and healths[i] > 0:
			blackboard.set_var(player_position_var, positions[i])
			blackboard.set_var(player_idx, i)
			blackboard.set_var("state", "agro")
			
			return SUCCESS
			# pdate which index value the enemies should be acce`ssing
	
	return SUCCESS
