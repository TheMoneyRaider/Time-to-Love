extends BTAction

func _tick(_delta: float) -> Status:
#	
	var attack_status = get_blackboard().get_var("attack_status")
	if attack_status == " DONE":
		get_blackboard().set_var("attack_mode","MELEE")
		get_blackboard().set_var("attack_status"," STARTING")
		return SUCCESS
	if attack_status == " RUNNING":
		return RUNNING
	return FAILURE
