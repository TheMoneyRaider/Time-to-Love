extends BTAction

func _tick(_delta: float) -> Status:
#	
	var attack_status = get_blackboard().get_var("attack_status")
	if attack_status == "DONE":

		print("attack/ MELEE / STARTING")
		get_blackboard().set_var("attack_mode","NONE")
		get_blackboard().set_var("attack_status","STARTING")
		return SUCCESS
	return FAILURE
