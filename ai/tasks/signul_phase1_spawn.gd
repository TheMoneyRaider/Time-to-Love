extends BTAction


var enemies = ["res://Game Elements/Characters/laser_enemy.tscn","res://Game Elements/Characters/robot.tscn",]
var enemy_count_linear = [4,8]
var enemy_count_rand = [4,8]


func get_enemy_count()-> int:
	var count = 0
	for enemy in agent.get_tree().get_nodes_in_group("enemy"):
		if "is_boss" in enemy and !enemy.is_boss:
			count+=1
	return count
func get_laser_count()-> int:
	var count = 0
	for enemy in agent.get_tree().get_nodes_in_group("enemy"):
		if "is_boss" in enemy and !enemy.is_boss and enemy.enemy_type=="laser_e":
			count+=1
	return count



func _tick(_delta: float) -> Status:
	print("wave_trigger")
	if  get_enemy_count() < 8:
		var enemy_id = clamp(randi()%3,0,1)
		if get_laser_count() > 4:
			enemy_id = 1
		var e_count = enemy_count_linear[enemy_id] + int(enemy_count_rand[enemy_id] * randf())
		print(e_count)
		agent.boss_signal("spawn_enemies",e_count,enemies[enemy_id])
	return SUCCESS
