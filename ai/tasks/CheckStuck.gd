extends BTAction

func _tick(delta: float):
	if(agent.position.distance_to(agent.last_pos) <= 20):
		agent.time_stuck += delta
		if(agent.time_stuck >= 3):
			return FAILURE
	else:
		agent.time_stuck = 0
		agent.last_pos = agent.position
	return SUCCESS
