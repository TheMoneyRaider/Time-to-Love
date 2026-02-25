extends BTAction



func _tick(_delta: float) -> Status:
#	
	agent.get_parent().scifi_binary_attack()
	return SUCCESS
