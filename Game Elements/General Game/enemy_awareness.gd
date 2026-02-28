extends Node2D

@export var camera: Camera2D
@export var enemies: Array[Node]
@export var glow_scene: PackedScene
@export var max_glows := 100

var glow_pool := []
var active_glows := []

func _ready():
	# Initialize pool	
	for i in range(max_glows):
		var glow = glow_scene.instantiate() as Sprite2D
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
		var glow = glow_scene.instantiate() as Sprite2D
		glow.visible = false
		add_child(glow)
		glow_pool.append(glow)

	for i in range(enemies.size()):
		if !enemies[i]:
			glow_pool[i].visible = false
			continue
			
		world_pos = enemies[i].global_position
		var glow = glow_pool[i] as Sprite2D

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
		glow.modulate = lerp(Color(0.713, 0.001, 0.76, 1.0),Color(0.8, 0.407, 0.0, 1.0),t_color)
		glow.modulate.a = t
		glow.visible = true

	# Hide any unused glows
	for i in range(enemies.size(), glow_pool.size()):
		glow_pool[i].visible = false


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
