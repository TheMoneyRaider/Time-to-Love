class_name Spawner

###CONSTANTS
static var cell_world_size := 16.0

static var player_penalty_weight := 1.0
static var player_threshold := 4.0 * 16.0
static var enemy_penalty_weight := 0.75
static var enemy_threshold := 4.0 * 16.0
static var edge_penalty_weight := 0.25
static var edge_threshold := 2.0 * 16.0

static var _player_threshold_sq := player_threshold * player_threshold
static var _enemy_threshold_sq := enemy_threshold * enemy_threshold
static var _edge_threshold_sq := edge_threshold * edge_threshold

###CACHES
static var _enemy_extents_cache := {}      # scene_path -> Vector2
static var _enemy_scene_cache := {}        # scene_path -> PackedScene
static var player_penalty_field := {}
static var edge_penalty_field := {}
static var enemy_penalty_field := {}

###PUBLIC API
static func spawn_enemies(
	players: Array[Node],
	scene: Node,
	available_cells: Array[Vector2i],
	room_data: Room,
	layer_manager: Node,
	is_wave: bool
) -> void:
	if room_data.num_enemy_goal <= 0:
		return

	#Convert to hash set for O(1) lookup
	var cell_set := {}
	for c in available_cells:
		cell_set[c] = true

	var edges := _get_edges(cell_set)

	var rechoose_enemy := not is_wave or room_data.wave_segment < randf()
	# === PRECOMPUTE STATIC FIELDS ===
	player_penalty_field = _build_player_field(cell_set, players)
	edge_penalty_field = _build_edge_field(cell_set, edges)

	enemy_penalty_field.clear()

	var chosen_positions: Array[Vector2i] = []

	var enemy_path := choose_enemy(room_data)
	var enemy_scene := _get_enemy_scene(enemy_path)
	var cells_needed := _cells_needed(_get_enemy_half_extents(enemy_path))

	for _i in room_data.num_enemy_goal:
		var best := _choose_best_cell(
			cell_set,
			cells_needed
		)

		if best == Vector2i(-999,-999):
			push_warning("No valid cell left to place enemy")
			return

		cell_set.erase(best)
		chosen_positions.append(best)
		_spawn_enemy(best, scene, enemy_scene, layer_manager)

		if rechoose_enemy:
			enemy_path = choose_enemy(room_data)
			enemy_scene = _get_enemy_scene(enemy_path)
			cells_needed = _cells_needed(_get_enemy_half_extents(enemy_path))
		_apply_enemy_influence(best)

###ENEMY SELECTION
static func choose_enemy(room_data: Room) -> String:
	var total := 0.0
	for w in room_data.enemy_chances:
		total += w

	var roll := randf() * total
	var acc := 0.0

	for i in room_data.enemy_chances.size():
		acc += room_data.enemy_chances[i]
		if acc >= roll:
			return room_data.enemy_pool[i]

	return room_data.enemy_pool[0]

###CELL SELECTION
static func _choose_best_cell(
	cell_set: Dictionary,
	cells_needed: Vector2i
) -> Vector2i:
	var total_weight := 0.0
	var chosen: Vector2i = Vector2(-999,-999)

	for cell in cell_set.keys():
		if not _can_fit(cell, cells_needed, cell_set):
			continue

		var score := 1.0
		score -= player_penalty_field.get(cell, 0.0)
		score -= edge_penalty_field.get(cell, 0.0)
		score -= enemy_penalty_field.get(cell, 0.0)
		score = clamp(score, 0.0, 1.0)

		if score <= 0.0:
			continue

		total_weight += score
		if randf() * total_weight < score:
			chosen = cell

	return chosen

static func _build_player_field(cell_set: Dictionary, players: Array[Node]) -> Dictionary:
	var field := {}
	var thresh_sq := player_threshold * player_threshold

	for cell in cell_set.keys():
		var world_pos :Vector2 = cell * cell_world_size
		var penalty := 0.0

		for p in players:
			var d2 := world_pos.distance_squared_to(p.global_position)
			if d2 < thresh_sq:
				penalty += player_penalty_weight * (1.0 - d2 / thresh_sq)

		field[cell] = clamp(penalty, 0.0, 1.0)

	return field

static func _build_edge_field(cell_set: Dictionary, edges: Array[Vector2i]) -> Dictionary:
	var field := {}
	var thresh_sq := edge_threshold * edge_threshold

	for cell in cell_set.keys():
		var world_pos :Vector2 = cell * cell_world_size
		var penalty := 0.0

		for e in edges:
			var d2 := world_pos.distance_squared_to(e * cell_world_size)
			if d2 < thresh_sq:
				penalty += edge_penalty_weight * (1.0 - d2 / thresh_sq)

		field[cell] = clamp(penalty, 0.0, 1.0)

	return field

static func _apply_enemy_influence(center: Vector2i):
	var radius := int(ceil(enemy_threshold / cell_world_size))
	var thresh_sq := enemy_threshold * enemy_threshold

	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var cell := center + Vector2i(x, y)
			var d2 := (cell * cell_world_size).distance_squared_to(center * cell_world_size)

			if d2 >= thresh_sq:
				continue

			var penalty := enemy_penalty_weight * (1.0 - d2 / thresh_sq)
			enemy_penalty_field[cell] = clamp(
				enemy_penalty_field.get(cell, 0.0) + penalty,
				0.0,
				1.0
			)


####SCORING
static func _score_cell(
	cell: Vector2i,
	chosen_positions: Array[Vector2i],
	players: Array[Node],
	edges: Array[Vector2i]
) -> float:
	var world_pos := cell * cell_world_size
	var score := 1.0

	for p in players:
		var d2 := world_pos.distance_squared_to(p.global_position)
		if d2 < _player_threshold_sq:
			score -= player_penalty_weight * (1.0 - d2 / _player_threshold_sq)

	for c in chosen_positions:
		var d2 := world_pos.distance_squared_to(c * cell_world_size)
		if d2 < _enemy_threshold_sq:
			score -= enemy_penalty_weight * (1.0 - d2 / _enemy_threshold_sq)

	for e in edges:
		var d2 := world_pos.distance_squared_to(e * cell_world_size)
		if d2 < _edge_threshold_sq:
			score -= edge_penalty_weight * (1.0 - d2 / _edge_threshold_sq)

	return clamp(score, 0.0, 1.0)

####FIT / EDGE LOGIC
static func _can_fit(cell: Vector2i, needed: Vector2i, cell_set: Dictionary) -> bool:
	for x in range(-needed.x, needed.x + 1):
		for y in range(-needed.y, needed.y + 1):
			if not cell_set.has(cell + Vector2i(x, y)):
				return false
	return true

static func _get_edges(cell_set: Dictionary) -> Array[Vector2i]:
	var edges: Array[Vector2i] = []
	for cell in cell_set.keys():
		for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var n : Vector2i= cell + d
			if not cell_set.has(n):
				edges.append(n)
	return edges

####ENEMY SIZE CACHE
static func _get_enemy_scene(path: String) -> PackedScene:
	if not _enemy_scene_cache.has(path):
		_enemy_scene_cache[path] = load(path)
	return _enemy_scene_cache[path]

static func _get_enemy_half_extents(path: String) -> Vector2:
	if _enemy_extents_cache.has(path):
		return _enemy_extents_cache[path]

	var scene := _get_enemy_scene(path)
	var inst := scene.instantiate()
	var shape_node := inst.get_node_or_null("CollisionShape2D")

	if shape_node == null:
		inst.queue_free()
		push_error("Enemy has no CollisionShape2D")
		return Vector2.ZERO

	var shape : Shape2D = shape_node.shape
	var extents := Vector2.ZERO

	if shape is RectangleShape2D:
		extents = shape.extents
	elif shape is CapsuleShape2D:
		extents = Vector2(shape.radius, shape.height * 0.5)
	elif shape is CircleShape2D:
		extents = Vector2.ONE * shape.radius

	inst.queue_free()
	_enemy_extents_cache[path] = extents
	return extents

static func _cells_needed(half_extents: Vector2) -> Vector2i:
	return Vector2i(
		ceil(half_extents.x / cell_world_size),
		ceil(half_extents.y / cell_world_size)
	)

###SPAWNING
static func _spawn_enemy(cell: Vector2i, scene: Node, enemy: PackedScene, layer_manager: Node) -> void:
	var inst := enemy.instantiate()
	inst.global_position = cell * cell_world_size
	scene.add_child(inst)
	inst.enemy_took_damage.connect(layer_manager._on_enemy_take_damage)
	
static func spawn_after_image(entity : Node, layer_manager : Node, start_color : Color = Color(1,1,1,1), end_color : Color = Color(1,1,1,1),start_color_strength : float = 1.0, end_color_strength : float = 1.0, lifetime : float = 2.0, start_alpha : float  = 1, mono : bool = false, position_override : Vector2 = Vector2(-999,-999)):
	
	# Instance the after image
	var after_image = load("res://Game Elements/Objects/after_image.tscn").instantiate()

	# Match position and rotation
	if position_override != Vector2(-999,-999):
		after_image.global_position = position_override
	else:
		after_image.global_position = entity.global_position
	after_image.global_rotation = entity.global_rotation
	after_image.scale = entity.scale

	# Copy the texture and frame if using Sprite2D
	if entity.has_node("Sprite2D"):
		var sprite = entity.get_node("Sprite2D")
		after_image.texture = sprite.texture
		after_image.region_rect = sprite.region_rect
		after_image.hframes = sprite.hframes
		after_image.vframes = sprite.vframes
		after_image.flip_h = sprite.flip_h
		after_image.flip_v = sprite.flip_v
		after_image.frame = sprite.frame
	

	after_image.start_color = start_color
	after_image.mono = mono
	after_image.start_color_strength = start_color_strength
	after_image.end_color = end_color
	after_image.end_color_strength = end_color_strength
	after_image.lifetime = lifetime
	after_image.start_alpha = start_alpha
	layer_manager.room_instance.add_child(after_image)
