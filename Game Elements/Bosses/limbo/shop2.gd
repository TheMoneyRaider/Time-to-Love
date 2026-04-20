extends Node2D

var curr_pos = Vector2.ZERO
var time_passed = 0.0

func _ready() -> void:
	var offset = $Cracks.global_position+Vector2(8,32)
	print(offset)
	for node in get_node("Tentacles").get_children():
		if node.is_in_group("tentacle"):
			node.set_hole(offset)
		if node.is_in_group("holds_reward"):
			node.shrink(.88)
	$Cracks.enabled = false
			
func _process(delta: float) -> void:
	if time_passed >= 2.0:
		$Cracks.enabled = true
	if curr_pos != position:
		curr_pos= position
		for node in get_node("Tentacles").get_children():
			if node.is_in_group("tentacle"):
				node.get_node("SubViewportContainer").material.set_shader_parameter("node_offset",position)
	if $Cracks.enabled == false:
		time_passed+=delta
