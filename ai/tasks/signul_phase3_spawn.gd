extends BTAction


var enemy_str = "res://Game Elements/Characters/binary_bot.tscn"

func get_enemy_count()-> int:
	var count = 0
	for enemy in agent.get_tree().get_nodes_in_group("enemy"):
		if "is_boss" in enemy and !enemy.is_boss:
			count+=1
	return count



func _tick(_delta: float) -> Status:
	print("wave_trigger")
	if  get_enemy_count() < 8:
		var e_count = 4 + int(4 * randf())
		agent.boss_signal("spawn_enemies",e_count,enemy_str)
	return SUCCESS
