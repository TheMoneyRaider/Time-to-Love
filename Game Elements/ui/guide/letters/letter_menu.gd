extends CanvasLayer

var mouse_mode = null
var active = false
@onready var container : Control = $Control/MarginContainer/Letters

var current_focus_index := -2  # -1 means return focused
@export var joystick_deadzone := 0.5  # adjust for your joystick sensitivity
var last_input_dir := 0  # prevent repeated triggers
var last_input_dirv := 0  # prevent repeated triggers
var letter_pool: Array[Letter] = []

var LayerManager : Node
func _ready():
	_load_all_letters()
	LayerManager = get_tree().get_root().get_node("LayerManager")
	hide()

func _load_all_letters() -> void:
	#var dir = DirAccess.open("res://Game Elements/Remnants/")
	var dir = ResourceLoader.list_directory("res://Game Elements/ui/guide/letters/")
	if dir == null:
		push_error("Letters folder not found: res://Game Elements/ui/guide/letters/")
		return
	for file in dir:
		if file.ends_with(".tres"):
			var res = ResourceLoader.load("res://Game Elements/ui/guide/letters/" + file)
			if res:
				letter_pool.append(res)



func populate_letters():
	var letter_count = letter_pool.size()
	if letter_count == 0:
		return

	# compute grid close to sqrt(N)
	var grid_x = ceil(sqrt(letter_count))
	var grid_y = ceil(float(letter_count) / grid_x)
	await get_tree().process_frame

	var fragments_data = generate_jittered_grid_fragments(container.size, grid_x, grid_y)

	var count := 0
	for frag_poly in fragments_data:
		if count >= letter_count:
			break

		var letter_format = letter_pool[count].letter_format

		# Compute bounding box of the polygon
		var min_x = frag_poly[0].x
		var max_x = frag_poly[0].x
		var min_y = frag_poly[0].y
		var max_y = frag_poly[0].y
		for p in frag_poly:
			min_x = min(min_x, p.x)
			max_x = max(max_x, p.x)
			min_y = min(min_y, p.y)
			max_y = max(max_y, p.y)
		var bbox_size = Vector2(max_x - min_x, max_y - min_y)

		# Create a button inside that bounding box
		var btn := preload("res://Game Elements/ui/guide/letter_fragment.tscn").instantiate()
		btn.position = Vector2(min_x, min_y)
		btn.size = bbox_size
		btn.name = "LetterButton_%d" % count

		var uv_points = []
		for p in frag_poly:
			uv_points.append(p / container.size)
		var center = Vector2(0.0,0.0);
		btn.polygon_points = uv_points  # uv_points normalized 0..1 inside button
		
		var text := TextureRect.new()
		text.texture = letter_format.main_art
		text.position = Vector2.ZERO
		text.size = container.size
		text.stretch_mode = TextureRect.STRETCH_SCALE
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for p in frag_poly:
			center += p
		center = center / float(frag_poly.size()) / container.size
		var mat  = ShaderMaterial.new()
		mat.shader = preload("res://Game Elements/ui/guide/letter.gdshader")
		mat.set_shader_parameter("point_count", uv_points.size())
		mat.set_shader_parameter("points", uv_points)
		mat.set_shader_parameter("center_point", center)
		mat.set_shader_parameter("image_size", container.size)
		text.size = container.get_size()
		text.material = mat
		container.add_child(text)

		btn.connect("pressed", Callable(self, "_on_letter_pressed").bind(count))
		container.add_child(btn)
		

		count += 1

func _on_letter_pressed(index: int):
	print("Letter pressed: %d" % index)
	# You can do whatever with the letter here


func queue_free_children(n :Node):
	for c in n.get_children():
		c.queue_free()

func activate():
	active = true
	show()
	populate_letters()
	$Control/Return.grab_focus()
var wep_snapped = false



func _on_return_pressed():
	queue_free_children(container)
	active = false
	hide()
	current_focus_index = -2
	$Control/Return.grab_focus()
	get_parent().get_node("PauseMenu").activate()
	
	

func generate_jittered_grid_fragments(size_tex: Vector2, grid_x: int, grid_y: int, jitter: float = 0.0) -> Array:
	jitter =  min(size_tex.x/grid_x/2.0,size_tex.y/grid_y/2.0)
	var fragments = []
	var cell_w = size_tex.x / grid_x
	var cell_h = size_tex.y / grid_y
	var points = []
	for x in range(grid_x + 1):
		points.append([])
		for y in range(grid_y + 1):
			points[x].append(Vector2.ZERO)
	var stop = false
	for y in range(grid_y+1):
		for x in range(grid_x+1):
			var px = x * cell_w
			var py = y * cell_h
			for vec in [Vector2(0,0),Vector2(0,size_tex.y),Vector2(size_tex.x,0),Vector2(size_tex.x,size_tex.y)]:
				if Vector2(px,py)==vec:
					points[x][y]= Vector2(px,py)
					stop = true
					break
			if stop:
				stop = false
			elif px == size_tex.x or px == 0:
				points[x][y] = Vector2(
					px,
					jitter_point(py, jitter, 0, size_tex.y)
				)
			elif py == size_tex.y or py == 0:
				points[x][y] = Vector2(
					jitter_point(px, jitter, 0, size_tex.x),
					py
				)
			else:
				points[x][y] = Vector2(
					jitter_point(px, jitter, 0, size_tex.x),
					jitter_point(py, jitter, 0, size_tex.y)
				)
	for y in range(grid_y):
		for x in range(grid_x):
			# Convex hull to ensure valid polygon
			var poly = [points[x][y],points[x+1][y],points[x+1][y+1],points[x][y+1]]
			# Remove last point if it equals the first
			if poly.size() > 1 and poly[0] == poly[poly.size() - 1]:
				poly.remove_at(poly.size() - 1)
			fragments.append(poly)
	return fragments
	
func jitter_point(p: float, jitter: float, min_val: float, max_val: float) -> float:
	return clamp(p + randf_range(-jitter, jitter), min_val, max_val)
