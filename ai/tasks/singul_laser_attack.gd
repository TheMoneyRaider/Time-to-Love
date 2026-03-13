extends BTAction

@export var num_lasers = 16
var ray_distances = []
var laser_attack_dist = 600.0
var laser_impact_time = 0.0
var laser_wave_width = 1024
var laser_speed = 2*laser_attack_dist/5


func _tick(_delta: float) -> Status:
#	
	agent.get_parent().scifi_laser_attack(num_lasers)
	return SUCCESS
