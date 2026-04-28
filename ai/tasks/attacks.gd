extends BTAction

@export var attack_index: int = 0

func _tick(_delta: float) -> Status: 
	
	var p_index = blackboard.get_var("player_idx")
	var players = agent.get_tree().get_nodes_in_group("player")
	var current_player_pos: Vector2 = players[p_index].global_position if players else Vector2.ZERO
	
	agent.handle_attack(current_player_pos,attack_index)
	agent.time_stuck = 0
	
	return SUCCESS
