extends Area2D

@export var prompt1: Node2D

var original_global_position := Vector2.ZERO
var tracked_bodies: Array = []

const ATTRACT_RADIUS := 32.0
const ATTRACT_STRENGTH := 10.0
const RETURN_THRESHOLD := 5.0
const RETURN_SPEED := 20.0
const MAX_OFFSET := Vector2(8.0, 8.0)


func _ready() -> void:
	original_global_position = global_position
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	_update_shader_offset()

	var closest := _get_closest_player_position()
	var dist_from_origin := original_global_position.distance_to(closest)
	var dist_from_original := global_position.distance_to(original_global_position)

	if dist_from_origin < ATTRACT_RADIUS and dist_from_original < ATTRACT_RADIUS - 2.0:
		var to_player := (global_position - closest).normalized() * delta
		global_position -= Vector2(to_player.x, abs(to_player.y)) * ATTRACT_STRENGTH
	elif dist_from_original > RETURN_THRESHOLD:
		global_position -= (global_position - original_global_position).normalized() * delta * RETURN_SPEED

	global_position = global_position.clamp(
		original_global_position - MAX_OFFSET,
		original_global_position + MAX_OFFSET
	)


func activate() -> void:
	Globals.has_gotten_tutorial =true
	get_tree().get_root().get_node("LayerManager")._enable_pathways()


# -- Private ------------------------------------------------------------------

func _update_shader_offset() -> void:
	var parent_pos : Vector2= get_parent().position
	if parent_pos != $Vision.material.get_shader_parameter("node_offset"):
		$Vision.material.set_shader_parameter("node_offset", parent_pos)


func _get_closest_player_position() -> Vector2:
	var layer_manager := get_tree().get_root().get_node("LayerManager")
	var players: Array[Vector2] = []

	if Globals.is_multiplayer:
		players.append(layer_manager.player2.global_position)
	else:
		players.append(layer_manager.player1.global_position)

	var closest := Vector2(INF, INF)
	for player in players:
		if global_position.distance_to(player) < global_position.distance_to(closest):
			closest = player
	return closest


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	tracked_bodies.append(body)
	prompt1.visible = true
	_set_display(tracked_bodies[0])


func _on_body_exited(body: Node) -> void:
	tracked_bodies.erase(body)
	if tracked_bodies.is_empty():
		prompt1.visible = false
	else:
		_set_display(tracked_bodies[0])


func _set_display(body: Node) -> void:
	var glyph_key : String= "activate_" + body.input_device
	var device_type := GlyphManager.get_device_type(body.input_device)
	var sym := GlyphManager.get_glyph(device_type, glyph_key)
	prompt1.get_child(0).bbcode_text = "Learn: " + sym
