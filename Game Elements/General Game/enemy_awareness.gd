extends Node2D

@export var camera: Camera2D
@export var enemies: Array[Node]
@export var glow_scene: PackedScene
@export var max_glows := 100
var version = 0

var glow_pool := []
var active_glows := []
var version_changed : bool = false

func set_array(array : Array, version_in : int):
	enemies =array
	if version != version_in:
		version_changed = true
	version = version_in


func _ready():
	# Initialize pool	
	for i in range(max_glows):
		var glow = glow_scene.instantiate()
		glow.visible = false
		add_child(glow)
		glow_pool.append(glow)

func get_camera_rect() -> Rect2:
	var view_size = get_viewport_rect().size / camera.zoom
	var half = view_size * 0.5

	return Rect2(
		camera.global_position - half,
		view_size
	)
func _process(_d):
	var rect = get_camera_rect()
	var edge_world
	var world_pos
	# Ensure we have enough glows
	while glow_pool.size() < enemies.size():
		var glow = glow_scene.instantiate()
		glow.visible = false
		add_child(glow)
		glow_pool.append(glow)

	for i in range(enemies.size()):
		if !enemies[i]:
			glow_pool[i].visible = false
			continue
			
		world_pos = enemies[i].global_position
		var glow = glow_pool[i]

		# Position & fade
		
		edge_world = clamp_to_edge_world(world_pos, rect)
	
		glow.position = (edge_world - rect.position) * camera.zoom

		var in_fade_dist = 48.0
		var out_fade_dist = 1600.0
		var t = 1.0
		var d = distance_to_rect_edge(world_pos, rect)
		if rect.has_point(world_pos):
			t = 1.0 - clamp(d / in_fade_dist, 0.0, 1.0)
		else:
			t = 1.0 - clamp(d / out_fade_dist, 0.0, 1.0)

		glow.scale = Vector2(1.0,1.0) * lerp(0.0, .3, t)  # radius scaling
		# screen_pos is already in screen coordinates
		var screen_width = rect.size.x
		var t_color = clamp((glow.global_position.x -camera.global_position.x+screen_width/2.0) / (screen_width * camera.zoom.x), 0.0, 1.0)
		
		glow.modulate.a = t
		glow.visible = true
		match version:
			0:
				glow.get_node("GlowCircle").modulate = lerp(Color(0.713, 0.001, 0.76, 1.0),Color(0.8, 0.407, 0.0, 1.0),t_color)
				if version_changed:
					glow.get_node("GlowCircle").visible = true
					glow.get_node("PathwayIcon1").visible = false
					glow.get_node("PathwayIcon2").visible = false
			1:
				glow.scale *= 2.0
				if version_changed:
					glow.get_node("GlowCircle").visible = false
					var reward = enemies[i].get_node("Image")
					var icon1 = glow.get_node("PathwayIcon1")
					var icon2 = glow.get_node("PathwayIcon2")
					icon1.visible = true
					icon2.visible = true
					icon1.texture = reward.texture
					icon2.texture = reward.texture
					icon1.hframes = reward.hframes
					icon2.hframes = reward.hframes
					icon1.vframes = reward.vframes
					icon2.vframes = reward.vframes
					if(icon1.material != null):
						icon1.material.set_shader_parameter("split", false)
					if(icon2.material != null):
						icon2.material.set_shader_parameter("split", false)
			2:
				glow.scale *= 2.0
				if version_changed:
					glow.get_node("GlowCircle").visible = false
					var pathway = enemies[i]
					var icon1 = glow.get_node("PathwayIcon1")
					var icon2 = glow.get_node("PathwayIcon2")
					icon1.visible = true
					icon2.visible = true

					icon1.texture = pathway.reward1_texture
					icon1.frame = pathway.reward1_frame
					icon1.hframes = pathway.reward1_hframes
					icon1.vframes = pathway.reward1_vframes
					icon1.material = pathway.reward1_material
					icon1.visible = pathway.reward1_texture != null

					icon2.texture = pathway.reward2_texture
					icon2.frame = pathway.reward2_frame
					icon2.hframes = pathway.reward2_hframes
					icon2.vframes = pathway.reward2_vframes
					icon2.material = pathway.reward2_material
					icon2.visible = pathway.reward2_texture != null and pathway.is_wave
					if pathway.is_wave:
						icon1.material = pathway.reward1_material.duplicate()
						icon2.material = pathway.reward2_material.duplicate()
						icon1.material.set_shader_parameter("split", true)
						icon2.material.set_shader_parameter("split", true)
						icon1.material.set_shader_parameter("upper_left", true)
						icon2.material.set_shader_parameter("upper_left", false)

	# Hide any unused glows
	for i in range(enemies.size(), glow_pool.size()):
		glow_pool[i].visible = false
	version_changed = false


func distance_to_rect_edge(p: Vector2, rect: Rect2) -> float:
	var left   = p.x - rect.position.x
	var right  = rect.end.x - p.x
	var top    = p.y - rect.position.y
	var bottom = rect.end.y - p.y

	return min(left, right, top, bottom)

func clamp_to_edge_world(p: Vector2, rect: Rect2) -> Vector2:# Shrink rect by margin
	var clamped = Vector2(
		clamp(p.x, rect.position.x, rect.end.x),
		clamp(p.y, rect.position.y, rect.end.y)
	)

	# If already outside, the clamp already put it on the edge
	if !rect.has_point(p):
		return clamped

	# Inside → snap to nearest edge
	var left   = p.x - rect.position.x
	var right  = rect.end.x - p.x
	var top    = p.y - rect.position.y
	var bottom = rect.end.y - p.y

	var m = min(left, right, top, bottom)

	if m == left:
		clamped.x = rect.position.x
	elif m == right:
		clamped.x = rect.end.x
	elif m == top:
		clamped.y = rect.position.y
	else:
		clamped.y = rect.end.y

	return clamped
