extends Control

var current_health = 10
var max_health = 10
@export var is_purple : bool

@export var width_scale := 100
@export var exponent := 0.247
@export var flipped : bool = false

@onready var progress_bar = $ProgressBar
@onready var back = $Background
@onready var fore = $Foreground
@onready var label = $Label
@onready var pieces = $Pieces
@export var health_chunk_scene : PackedScene


func _get_chunk_points(start_health: int, end_health: int) -> PackedVector2Array:
	var total_width = width_scale * pow(max_health, exponent)
	var height_half = progress_bar.size.y / 2
	var start_pos = progress_bar.position
	
	var start_ratio = float(start_health) / max_health
	var end_ratio = float(end_health) / max_health
	
	var start_x = total_width * start_ratio
	var end_x = total_width * end_ratio
	
	var p1: Vector2
	var p2: Vector2
	
	if not flipped:
		p1 = start_pos + Vector2(start_x, height_half)
		p2 = start_pos + Vector2(end_x, height_half)
	else:
		p1 = start_pos + Vector2(total_width - start_x, height_half)
		p2 = start_pos + Vector2(total_width - end_x, height_half)
	
	var points := PackedVector2Array()
	points.append(p1)
	points.append(p2)
	return points

func _spawn_health_chunk(old_health: int, new_health: int):
	if not health_chunk_scene:
		return
	
	var chunk = health_chunk_scene.instantiate()
	
	var points = _get_chunk_points(
		min(old_health, new_health),
		max(old_health, new_health)
	)
	
	chunk.position = Vector2.ZERO  # important
	pieces.add_child(chunk)
	
	chunk.setup(
		points,
		fore.width,
		fore.default_color,
		new_health > old_health,
		flipped
	)
	return chunk

func _ready() -> void:
	update_text()
	set_color()
	if flipped:
		flip()


func set_max_health(health_value : int):
	max_health = health_value
	progress_bar.max_value = max_health
	var width =  width_scale * pow(health_value, exponent)
	progress_bar.custom_minimum_size.x = width
	update_text()
	update_lines()


func set_current_health(health_value : int):
	if health_value == current_health:
		return
	
	var old_health = current_health
	current_health = health_value
	
	update_text()
	var chunk = _spawn_health_chunk(old_health, current_health)
	if old_health < current_health:
		while chunk!=null and is_instance_valid(chunk):
			await get_tree().process_frame
	update_lines()


func update_lines():
	var total_width = width_scale * pow(max_health, exponent)
	var filled_width = total_width * clamp(float(current_health)/max_health,0.0,1.0)

	var start_pos = progress_bar.position
	var height_half = progress_bar.size.y / 2
	var point1: Vector2
	var point2: Vector2
	var point3: Vector2

	if not flipped:
		point1 = start_pos + Vector2(0, height_half)
		point2 = point1 + Vector2(total_width, 0)
		point3 = point1 + Vector2(filled_width, 0)
	else:
		point1 = start_pos + Vector2(total_width, height_half)
		point2 = point1 - Vector2(total_width, 0)
		point3 = point1 - Vector2(filled_width, 0)

	back.clear_points()
	back.add_point(point1)
	back.add_point(point2)

	fore.clear_points()
	fore.add_point(point1)
	fore.add_point(point3)
	


func update_text():
	label.text = str(current_health) + "/" + str(max_health) + " HP"
	

func flip():
	progress_bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN
	# Get the current indices of the nodes
	var index_a = progress_bar.get_index()
	var index_b = label.get_index()

	# Move each node to the other's index position
	# The 'move_child' function handles the reordering automatically
	move_child(progress_bar, index_b)
	move_child(label, index_a)
	await get_tree().process_frame
	update_lines()

#If you give it true it makes it purple, if you give false it makes it orange
func set_color(default_color : bool = is_purple):
	is_purple = default_color
	var font_color = Color(0.627, 0.125, 0.941, 1.0)
	if is_purple:
		$Background.default_color = Color(0.38, 0.031, 0.588, 1.0)
		$Foreground.default_color =Color(0.686, 0.298, 0.98, 1.0)
	else:
		$Background.default_color = Color(0.58, 0.367, 0.0, 1.0)
		$Foreground.default_color = Color(1.0, 0.722, 0.367, 1.0)
		font_color = Color(1.0, 0.647, 0.0, 1.0)
	self.theme.set_color("font_color","Label",font_color)
