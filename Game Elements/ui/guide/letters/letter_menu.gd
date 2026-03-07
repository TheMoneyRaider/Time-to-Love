extends CanvasLayer

var mouse_mode = null
var active = false
@onready var container : Control = $Control/MarginContainer/Letters

var letter_pool: Array[Letter] = []
var letter_buttons: Array[Button]
var fragment_visuals : Array[TextureRect] = []
var LayerManager : Node
func _ready():
	_load_all_letters()
	$Control/MarginContainer/Viewer.visible = false
	
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
	container.size = Vector2(1880,960)
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
		var center = Vector2(0.0,0.0)
		var local_points = []
		for p in frag_poly:
			local_points.append(p - Vector2(min_x, min_y))

		btn.scale_polygon(local_points, .9)
		
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
		fragment_visuals.append(text)

		btn.connect("focus_entered", Callable(self, "_on_fragment_hover").bind(count))
		btn.connect("focus_exited", Callable(self, "_on_fragment_unhover").bind(count))
		btn.connect("fragment_hovered", Callable(self, "_on_fragment_hover").bind(count))
		btn.connect("fragment_unhovered", Callable(self, "_on_fragment_unhover").bind(count))
		btn.connect("pressed", Callable(self, "_on_letter_pressed").bind(count))
		container.add_child(btn)
		letter_buttons.append(btn)
		

		count += 1
var button_cooldown : float = 0.0
func _process(delta: float) -> void:
	button_cooldown = max(0.0,button_cooldown-delta)


func _on_fragment_unhover(idx:int):
	if fragment_visuals.size() >idx-1:
		var mat = fragment_visuals[idx].material
		mat.set_shader_parameter("highlight",0)
	
func _on_fragment_hover(idx:int):
	if fragment_visuals.size() >idx-1:
		var mat = fragment_visuals[idx].material
		for child in fragment_visuals:
			child.material.set_shader_parameter("highlight",0)
		mat.set_shader_parameter("highlight", 1)


var letter_active : bool = false

func view_letter(idx : int):
	button_cooldown=.25
	letter_active = true

	var viewer = $Control/MarginContainer/Viewer
	viewer.visible = true

	var button = viewer.get_node("TextureButton") as TextureButton
	var text = viewer.get_node("RichTextLabel") as RichTextLabel

	var tex = letter_pool[idx].letter_format.per_letter_art as Texture2D
	if tex == null:
		push_error("Texture null")
		return

	button.texture_normal = tex
	await get_tree().process_frame

	# Resize button to keep aspect ratio
	button.size = Vector2(viewer.size.y * tex.get_width()/tex.get_height(), viewer.size.y)
	button.position.x = viewer.size.x/2 - button.size.x/2
	button.pivot_offset = button.size/2.0

	# Set text
	text.text = letter_pool[idx].description
	text.position = Vector2(0,0)
	text.size = viewer.size

	# Special per-letter tweaks
	match letter_pool[idx].letter_format.name:
		"Stone":
			text.position = Vector2(550,100)
			text.size.x = 800
		"Paper":
			text.position = Vector2(660,80)
			text.size.x = 640
			text.text = "[color=#363535][font_size=24]" + text.text
		"ModernNewspaper":
			text.position = Vector2(550,350)
			text.size.x = 780
			text.text = "[color=#7e7e7e]" + text.text
		"1980sNewspaper":
			text.position = Vector2(550,350)
			text.size.x = 780
			text.text = "[color=#979081]" + text.text
		"OldNewspaper":
			text.position = Vector2(550,350)
			text.size.x = 780
			text.text = "[color=#82796c]" + text.text
		"Holographic":
			text.position = Vector2(750,40)
			text.size.x = 340
			text.text = "[color=#b9f9fa][font_size=20]" + text.text


	# -----------------------
	# Animation
	# -----------------------

	var source_button = letter_buttons[idx]

	# center of clicked button (global)
	var start_center = source_button.global_position + source_button.size / 2

	# convert to viewer parent space
	var viewer_parent = viewer.get_parent()
	var start_local = viewer_parent.get_global_transform().affine_inverse() * start_center

	# final position
	var final_pos = viewer.position

	# set pivot so viewer scales from its center
	viewer.pivot_offset = viewer.size / 2

	# start state
	viewer.position = start_local - viewer.size/2
	viewer.scale = Vector2(0.2, 0.2)
	viewer.modulate.a = 0.0

	# animate
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(viewer, "position", final_pos, 0.35)
	tween.parallel().tween_property(viewer, "scale", Vector2.ONE, 0.35)
	tween.parallel().tween_property(viewer, "modulate:a", 1.0, 0.25)
	
func close_letter():
	button_cooldown=.25
	letter_active = false
	var viewer = $Control/MarginContainer/Viewer
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(viewer, "scale", Vector2.ZERO, .25)
	tween.parallel().tween_property(viewer, "modulate:a", 0.0, .25)
	pass




func _on_letter_pressed(index: int):
	if button_cooldown!=0.0:
		return
	print("Letter pressed: %d" % index)
	if letter_active:
		close_letter()
		return
	else:
		view_letter(index)
			
			

func _on_texture_button_pressed() -> void:
	close_letter()
	

func queue_free_children(n :Node):
	for c in n.get_children():
		c.queue_free()

func activate():
	active = true
	show()
	populate_letters()
	$Control/Return.grab_focus()



func _on_return_pressed():
	letter_buttons.clear()
	fragment_visuals.clear()
	queue_free_children(container)
	active = false
	hide()
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
