extends BTAction
@export var player_position_var: String = "target_pos"
@export var player_positions: String = "player_positions"
@export var player_idx: String = "player_idx"
# determines the distance at which and enemy can detect a player

func _tick(_delta: float) -> Status:
	var p_index = blackboard.get_var(player_idx)
	var players = agent.get_tree().get_nodes_in_group("player")
	var current_player_pos: Vector2 = players[p_index].global_position if players else Vector2.ZERO
	if current_player_pos.distance_to(agent.global_position) > 12:
		agent.move(current_player_pos, _delta)
	
	return SUCCESS
