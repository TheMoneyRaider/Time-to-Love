extends BTAction

func _tick(_delta: float) -> Status:
	if (agent.velocity.length() >= 5):
		return SUCCESS
	else:
		return FAILURE
