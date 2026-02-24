extends RigidBody2D

var start_pos: Vector2
var rewind_pos: Vector2
var rewind_rot: float
var velocity: Vector2
var rot_vel: float
var breaking: bool = false
var rewinding: bool = false
var rewind_time: float = 0.0
var rewind_duration: float = 1.5
var assigned_buttons : Array[Button] = []

func begin_break(frag_data: Array, tex: Texture2D, ui_pos : Vector2):
	#Compute fragment's top-left corner (min bounds)
	var min_p = frag_data[0]
	for p in frag_data:
		min_p.x = min(min_p.x, p.x)
		min_p.y = min(min_p.y, p.y)

	#Convert polygon vertices into local space
	var local_points = []
	for p in frag_data:
		local_points.append(p - min_p)

	freeze = true
	#Position this Node2D in world space (must add UI_Group offset)
	position = ui_pos + min_p
	start_pos = position
	freeze = false

	# Polygon2D
	var poly_node = get_node("Polygon2D")
	poly_node.texture = tex
	poly_node.polygon = local_points
	poly_node.uv = frag_data

	#highlight_nodes.clear()
	#Motion
	breaking = true
	rewinding = false
	

func redo_break():
	rewind_time= 0.0
	rewind_duration= 1.5
	freeze = true
	velocity=Vector2.ZERO
	#Position this Node2D in world space
	freeze = false
	

	#Motion
	breaking = true
	rewinding = false

func begin_rewind(duration := 1.5):
	rewinding = true
	breaking = false
	rewind_duration = duration
	rewind_time = 0.0
	rewind_pos = position
	rewind_rot = rotation
	freeze = true


func apply_force_frag(pos_in : Vector2, ar : int = 100):
	if position.distance_to(pos_in) < ar:
		var move =Vector2(20/clamp((position-pos_in).x,10,200),20/clamp((position-pos_in).y,10,200))
		if (position-pos_in).x <= 0.0:
			move.x *= -1
		if (position-pos_in).y <= 0.0:
			move.y *= -1
		velocity+= move


func set_display_texture(tex : CompressedTexture2D):
	get_node("Polygon2D").texture = tex
	

func _physics_process(delta):
	if breaking:
		linear_velocity = velocity
	elif rewinding:
		rewind_time += delta
		var t = clamp(rewind_time / rewind_duration, 0, 1)
		t = t * t * (3 - 2*t)  # smoothstep
		position = rewind_pos.lerp(start_pos, t)
		rotation = lerp(rewind_rot, 0.0, t)
		if t >= 1.0:
			redo_break()
	if linear_velocity.length() > 20:
		get_parent().get_parent()._begin_explosion_cooldown()
			
func add_interactive_area(frag_poly: Array, assigned_b : Array):
	var poly_node = get_node("Polygon2D")
	var collision = get_node("CollisionPolygon2D")
	var img = poly_node.texture.get_image()
	
	# Compute bounding box of fragment in texture space
	var min_x = frag_poly[0].x
	var max_x = frag_poly[0].x
	var min_y = frag_poly[0].y
	var max_y = frag_poly[0].y
	for p in frag_poly:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)
	
	var points: Array[Vector2i] = []
	var step = 1  # every 1 pixels
	for y in range(int(min_y), int(max_y)+1, step):
		for x in range(int(min_x), int(max_x)+1, step):
			if x > 0 and x < img.get_size().x and y > 0 and y < img.get_size().y and img.get_pixel(x, y).a > 0.0:
				points.append(Vector2i(x, y))
	if points.size()<=40:
		queue_free()
		return
	
	collision.polygon = poly_node.polygon
	if assigned_b!=[]:
		get_node("Area2D/CollisionPolygon2D").polygon = poly_node.polygon
		add_to_group("ui_fragments")  # allow easy access to all button fragments
		get_node("Area2D").connect("input_event", Callable(self, "_on_fragment_input"))

	assigned_buttons = assigned_b

func _on_fragment_input(_viewport, event, _shape_idx):
	# Get global mouse position
	var mouse_global = event.global_position
	var fragment_displacement = position - start_pos
	var mouse_original_space = mouse_global - fragment_displacement

	if event is InputEventMouseButton and event.pressed:
		# Iterate over buttons
		for button in assigned_buttons:
			if button.get_global_rect().has_point(mouse_original_space):
				get_parent().get_parent().button_pressed(button)
				return
	if event is InputEventMouseMotion:
		# Iterate over buttons
		for button in assigned_buttons:
			if button.get_global_rect().has_point(mouse_original_space):
				get_parent().get_parent().mouse_over(button)
				return
