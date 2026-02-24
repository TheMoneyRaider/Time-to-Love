extends BTAction

@export var target_position_var := "target_pos"
@export var min_distance := 48.0
@export var random_extra_distance := 32.0
@export var cell_size := 16

var _layer_manager: Node
var _placable_cell_set := {}

func _ready():
	_layer_manager = agent.get_tree().get_root().get_node("LayerManager")

	# Convert to hash set once
	for c in _layer_manager.placable_cells:
		_placable_cell_set[c] = true

func _tick(_delta: float) -> Status:
	var base_pos: Vector2 = agent.global_position
	var base_cell := Vector2i(base_pos / cell_size)

	var chosen_pos := base_pos

	for _i in 20:
		var x := randf_range(-random_extra_distance, random_extra_distance)
		var y := randf_range(-random_extra_distance, random_extra_distance)

		x += sign(x) * min_distance
		y += sign(y) * min_distance

		var cell_offset := Vector2i(
			round(x / cell_size),
			round(y / cell_size)
		)

		var target_cell := base_cell + cell_offset

		if _placable_cell_set.has(target_cell):
			chosen_pos = target_cell * cell_size
			break

	blackboard.set_var(target_position_var, chosen_pos)
	return SUCCESS
