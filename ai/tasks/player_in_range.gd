extends BTAction

@export var player_position_var: String = "target_pos"
@export var hit_range: int = 32

func _tick(_delta: float) -> Status:
#	
	
	

	
	var players = agent.get_tree().get_nodes_in_group("player")
	var positions_array = []
	for player in players: 
		positions_array.append(player.global_position)

	var player_agressing = blackboard.get_var("player_idx")
	if player_agressing == null or !positions_array[player_agressing]:
		return FAILURE
	if positions_array[player_agressing].distance_to(agent.global_position) <= hit_range:
		return SUCCESS
	return FAILURE
