extends BTAction
@export var player_position_var: String = "target_pos"
@export var player_positions: String = "player_positions"
@export var player_idx: String = "player_idx"
# determines the distance at which and enemy can detect a player
@export var in_range: int = 90
@export var out_range: int = 180
var step_interval: float = 0.4

var bigt_step = [
	preload("res://Game Elements/sfx/enemies/bigt/bigt_steps/bigt_walk1.ogg"),
	preload("res://Game Elements/sfx/enemies/bigt/bigt_steps/bigt_walk2.ogg"),
	preload("res://Game Elements/sfx/enemies/bigt/bigt_steps/bigt_walk3.ogg"),
	preload("res://Game Elements/sfx/enemies/bigt/bigt_steps/bigt_walk4.ogg"),
	preload("res://Game Elements/sfx/enemies/bigt/bigt_steps/bigt_walk5.ogg"),
	preload("res://Game Elements/sfx/enemies/bigt/bigt_steps/bigt_walk6.ogg"),
	preload("res://Game Elements/sfx/enemies/bigt/bigt_steps/bigt_walk7.ogg"),
]

func _tick(_delta: float) -> Status:
	var p_index = blackboard.get_var(player_idx)
	var players = agent.get_tree().get_nodes_in_group("player")
	var current_player_pos: Vector2 = players[p_index].global_position if players else Vector2.ZERO
	var moving = false
	if current_player_pos.distance_to(agent.global_position) < in_range:
		agent.move(blackboard.get_var(player_position_var), _delta)
		moving = true
	if current_player_pos.distance_to(agent.global_position) > out_range:
		agent.move(current_player_pos, _delta)
		moving = true
	
	if moving and agent.enemy_type == "large_reptile":
		var timer = blackboard.get_var("bigt_step_timer") if blackboard.has_var("bigt_step_timer") else 0.0
		timer -= _delta
		if timer <= 0.0:
			print("playing step sound")
			SFXManager.play(bigt_step[randi() % bigt_step.size()], 20, "SFX", agent.global_position)
			timer = step_interval
		blackboard.set_var("bigt_step_timer", timer)
	
	return SUCCESS
