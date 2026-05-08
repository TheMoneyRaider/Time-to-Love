extends BTAction


func _tick(_delta : float) -> Status:
	if agent.parent_node.island_attack_num <= 0:
		return FAILURE
	if agent.current_health / agent.max_health < agent.parent_node.island_attack_num / 6.0:
		agent.parent_node.island_attack()
		return SUCCESS
	return FAILURE
