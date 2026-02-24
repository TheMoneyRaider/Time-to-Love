extends BTAction

@export var min_time: float = 1.0
@export var max_time: float = 3.0

func _tick(delta: float) -> Status:
	randomize()
	get_parent().get_parent().duration = randf_range(min_time, max_time)
	return SUCCESS
