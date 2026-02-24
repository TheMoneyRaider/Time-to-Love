extends Node2D

@onready var text := $Label

# --- Movement variables ---
var velocity := Vector2.ZERO
var rot_velocity := 0.0
var mov_scale := .75
var grounded := false

# --- Internal ---
var time_passed := 0.0
var freeze_time := 0.0
var lifetime := 0.0
var first_color : Color
@export var gravity := 300.0

func _ready() -> void:
	grounded = false

func _process(delta: float) -> void:
	time_passed += delta
	freeze_time += delta
	if freeze_time < 0.2:
		return
	# --- In air: apply gravity ---
	velocity.y += gravity * delta * mov_scale
	position += velocity * delta * mov_scale
	rotation+=rot_velocity * delta * mov_scale
	if time_passed*2.0 > lifetime:
		var color : Color = text.get_theme_color("font_color")
		color.a = lerp(first_color.a,0.0,(time_passed-lifetime/2.0)/(lifetime/2.0))
		text.add_theme_color_override("font_color", color)
	if lifetime <= time_passed:
		queue_free()
	
	
func set_values(c_owner : Node = null, attack : Node = null, attack_owner : Node = null, value : int = 7, direction : Vector2 = Vector2.UP,size : int = 64, override_color : Color = Color(0.267, 0.394, 0.394, 1.0)) -> void:
	
	print("Damage: "+str(value)+" C Owner: "+str(c_owner)+" attack: "+str(attack)+" attack_owner: "+str(attack_owner))
	
	var orig_len = 100
	#Position based on attack and damage owner collision shapes
	if attack:
		position = attack.position
	else:
		position = c_owner.position
	if c_owner and attack:
		var new_pos = intersection_center(c_owner,attack)
		if new_pos != Vector2.ZERO:
			position= new_pos
	
			
			
	if attack and "attack_type" in attack and attack.attack_type=="laser":
		var sparks = preload("res://Game Elements/Particles/sparks_enemy.tscn").instantiate()
		if attack.c_owner and attack.c_owner.is_in_group("player"):
			sparks.range_choice = 1
		get_parent().add_child(sparks)
		sparks.global_position = global_position
	if attack and "attack_type" in attack and attack.attack_type=="crowbar_melee":
		var crow = preload("res://Game Elements/Particles/crowbar_hit.tscn").instantiate()
		get_parent().add_child(crow)
		crow.global_position = global_position
		crow.rotation = attack.direction.angle()+PI/2 +deg_to_rad(randf_range(-40,40))
		
	
	var color = Color(0.564, 0.0, 0.061, 1.0)
	if attack_owner:
		if attack_owner.is_in_group("player"):
			if attack_owner.is_purple:
				color = Color(0.769, 0.003, 1.0, 1.0)
			else:
				color = Color(0.842, 0.348, 0.0, 1.0)
	if !c_owner:
		color = Color(0.5, 0.5, 0.5, 1.0)
		orig_len = 20
	if override_color != Color(0.267, 0.394, 0.394, 1.0):
		color=override_color
			
	# Initial big toss
	direction = Vector2.UP #OVERRIDE DIRECTION
	var base_dir = direction.normalized()
	var max_angle = deg_to_rad(40.0)
	var angle_offset = randf_range(-max_angle, max_angle)
	var deviated_dir = base_dir.rotated(angle_offset)

	var random_scale = lerp(1.0, randf_range(0.5, 2.5), 0.4)
	var final_len = orig_len * random_scale

	velocity = Vector2(deviated_dir.x * final_len,
					   deviated_dir.y * final_len - 60)
	grounded = false
	var rot_angle = deg_to_rad(20.0)
	rot_velocity = randf_range(-rot_angle, rot_angle)
	#Add Color Variation
	if attack_owner:
		if !c_owner:
			var hue_change = .1
			var rand_val = randf_range(-hue_change,hue_change)
			color = Color(color.r+rand_val,color.g+rand_val,color.b+rand_val,color.a)
		else:
			var hue_change = .2
			color = Color(color.r+randf_range(-hue_change,hue_change),color.g+randf_range(-hue_change,hue_change),color.b+randf_range(-hue_change,hue_change),color.a)
		
			
	text.add_theme_font_size_override("font_size", size)
	text.add_theme_color_override("font_color", color)
	text.text = str(value)
	first_color = color
	lifetime = 1.5
	self.scale = Vector2(.125,.125)




func shape_to_polygon(in_shape: Shape2D, in_transform : Transform2D) -> PackedVector2Array:
	var poly := PackedVector2Array()
	if in_shape is CircleShape2D:
		var r = in_shape.radius
		var steps = 24
		for i in range(steps):
			var angle = TAU * float(i) / steps
			var local = Vector2(cos(angle), sin(angle)) * r
			poly.append(in_transform * local)
	elif in_shape is RectangleShape2D:
		var e = in_shape.extents
		var pts = [
			Vector2(-e.x, -e.y),
			Vector2( e.x, -e.y),
			Vector2( e.x,  e.y),
			Vector2(-e.x,  e.y),
		]
		for p in pts:
			poly.append(in_transform * p)
	elif in_shape is CapsuleShape2D:
		var r = in_shape.radius
		var h = in_shape.height / 2.0
		var steps = 12
		var pts := []

		# top semicircle
		for i in range(steps):
			var a = PI * float(i) / (steps - 1)
			pts.append(Vector2( cos(a)*r, -h + sin(a)*r ))

		# bottom semicircle
		for i in range(steps):
			var a = PI * float(i) / (steps - 1)
			pts.append(Vector2(-cos(a)*r, h + sin(a)*r))

		for p in pts:
			poly.append(in_transform * p)
	elif in_shape is ConvexPolygonShape2D:
		for p in in_shape.points:
			poly.append(in_transform * p)
	elif in_shape is ConcavePolygonShape2D:
		# uses triangles
		for p in in_shape.get_arrays()[Mesh.ARRAY_VERTEX]:
			poly.append(in_transform * p)

	return poly

func get_area_polygons(area: Node) -> Array:
	var result := []

	for child in area.get_children():
		if child is CollisionShape2D:
			var in_shape = child.shape
			var in_transform = child.global_transform
			var poly = shape_to_polygon(in_shape,in_transform)
			if poly.size() >= 3:
				result.append(poly)

		if child is CollisionPolygon2D:
			# Already a polygon, just transform to global
			var poly := PackedVector2Array()
			for p in child.polygon:
				poly.append(child.to_global(p))

			result.append(poly)

	return result

func intersection_polygon(polys_a: Array, polys_b: Array) -> PackedVector2Array:
	var intersections := []

	for a in polys_a:
		for b in polys_b:
			var res = Geometry2D.clip_polygons(a, b)
			if res.size() > 0:
				intersections.append_array(res)

	if intersections.size() == 0:
		return PackedVector2Array()  # no overlap

	# Merge if multiple pieces — usually result[0] is fine
	return intersections[0]

func polygon_centroid(poly: PackedVector2Array) -> Vector2:
	var centroid = Vector2.ZERO
	var signed_area = 0.0
	var n = poly.size()
	if n < 3:
		return poly[0] if n > 0 else Vector2.ZERO  # fallback

	for i in range(n):
		var p0 = poly[i]
		var p1 = poly[(i + 1) % n]
		var a = p0.x * p1.y - p1.x * p0.y
		signed_area += a
		centroid += (p0 + p1) * a

	signed_area *= 0.5
	if signed_area == 0:
		return poly[0]  # degenerate polygon fallback

	centroid /= (6.0 * signed_area)
	return centroid

func intersection_center(area_a: Node, area_b: Node) -> Vector2:
	var polys_a = get_area_polygons(area_a)
	var polys_b = get_area_polygons(area_b)
	
	var inter = intersection_polygon(polys_a, polys_b)
	
	if inter.size() == 0:
		return Vector2.ZERO
	return polygon_centroid(inter)
