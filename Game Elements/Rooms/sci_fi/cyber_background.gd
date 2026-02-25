extends ColorRect

@export var num_strings : int = 100
@export var spacing_y: float = 20  # minimum vertical spacing to avoid overlap

var used_y_positions: Array = []

func _ready() -> void:
	for i in range(num_strings):
		make_new_string_ready()
		

func _process(_delta: float) -> void:
	for child in get_children():
		# Recycle when offscreen
		if child.position.x > size.x + 50:
			child.position.x = -50
	
	
func make_new_string():
	var instance = load("res://Game Elements/Rooms/sci_fi/binary_string.tscn").instantiate()
	instance.position = Vector2(-50, get_random_y())
	add_child(instance)
	used_y_positions.append(instance.position.y)
	
func make_new_string_ready():
	var instance = load("res://Game Elements/Rooms/sci_fi/binary_string.tscn").instantiate()
	instance.position = Vector2(randf_range(-size.x, size.x), get_random_y())
	add_child(instance)
	used_y_positions.append(instance.position.y)

# Pick a random Y that doesn’t overlap existing strings
func get_random_y() -> float:
	var max_attempts = 50
	for attempt in range(max_attempts):
		var y = randf_range(0, size.y)
		var overlapping = false
		for used_y in used_y_positions:
			if abs(y - used_y) < spacing_y:
				overlapping = true
				break
		if not overlapping:
			return y
	# If too many attempts, just pick random
	return randf_range(0, size.y)
