extends BTAction

var enemies = ["res://Game Elements/Bosses/medieval/boss_skeleton.tscn"]
var enemy_count_dist = [6,12]


func _tick(_delta: float) -> Status:
	var p_index = blackboard.get_var("player_idx")
	var players = agent.get_tree().get_nodes_in_group("player")
	var current_player_pos: Vector2 = players[p_index].global_position if players else Vector2.ZERO
	var e_count = 6
	agent.lich_signal("spawn_enemies",e_count,enemies[0],current_player_pos,64)
	
	return SUCCESS
