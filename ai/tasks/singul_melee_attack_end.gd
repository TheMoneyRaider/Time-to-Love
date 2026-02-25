extends BTAction

var num_attacks = 5
var attack_spread : float = 80
var split_attacks = true
var random_spread = true
var spawn_distance = 0


func _tick(_delta: float) -> Status:
	
	agent.get_node("Segments").modulate =Color(1.0, 1.0, 1.0, 1.0)
	var board = agent.get_node("BTPlayer").blackboard
	var is_purple = board.get_var("player_idx") as bool
	var track_position = agent.get_parent().player1.global_position if is_purple else agent.get_parent().player2.global_position
	var direction = (track_position - agent.global_position).normalized()
	request_attacks(direction,agent.global_position)
	return SUCCESS

func request_attacks(direction : Vector2, char_position : Vector2):
	
	var attack_direction
	if(!split_attacks):
		attack_direction = direction.rotated(deg_to_rad((-attack_spread / 2) + randf_range(0,attack_spread)))
	else:
		attack_direction = direction.rotated(deg_to_rad(-attack_spread / 2))
		if(random_spread):
			attack_direction = attack_direction.rotated(deg_to_rad(randf_range(-attack_spread / (4 * num_attacks), attack_spread / (4 * num_attacks))))
	if(num_attacks > 1):
		for i in range(num_attacks):
			var attack_position = attack_direction * spawn_distance + char_position
			spawn_attack(attack_direction,attack_position)
			if(!split_attacks):
				attack_direction = direction.rotated(deg_to_rad((-attack_spread / 2) + randf_range(0,attack_spread)))
			else:
				attack_direction = attack_direction.rotated(deg_to_rad(attack_spread / (num_attacks-1)))
				if(random_spread):
					attack_direction = attack_direction.rotated(deg_to_rad(randf_range(-attack_spread / (2*num_attacks), attack_spread / (2*num_attacks))))
			

func spawn_attack(attack_direction : Vector2, attack_position : Vector2):
	var instance = load("res://Game Elements/Bosses/scifi/signul_melee.tscn").instantiate()
	instance.direction = attack_direction
	instance.global_position = attack_position
	instance.c_owner = agent
	agent.get_parent().add_child(instance)
