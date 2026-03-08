extends BTAction

@export var player_position_var: String = "target_pos"
@export var player_positions: String = "player_positions"
@export var player_idx: String = "player_idx"
@export var player_healths: String = "player_healths"

func _tick(_delta: float) -> Status:
	# Find the player in the scene

	var players = agent.get_tree().get_nodes_in_group("player")
	
	if not players:
		push_error("No players found in 'player' group")
		return FAILURE
	
	var positions_array = []
	var player_health_array = []

	
	for player in players: 
		positions_array.append(player.global_position)
		player_health_array.append(player.current_health)
		
	blackboard.set_var(player_positions, positions_array)
	blackboard.set_var(player_healths, player_health_array)
	if blackboard.get_var("state") == "agro":
		var player_agressing = blackboard.get_var(player_idx)
		blackboard.set_var(player_position_var, positions_array[player_agressing])
	
	return SUCCESS
