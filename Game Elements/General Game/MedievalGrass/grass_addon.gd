extends Node3D
@export var conflict_cells: Array[Vector2i] = []

@export var terrain_set_id: int = 0
@export var terrain_id: int = 0
@export var instances_per_tile : int = 25
var target_tilemap : TileMapLayer
# Cells to avoid placing meshes on
var LayerManager : Node
var game_camera : Node
var camera_offset : float
var grass_display : Node
var scale_x = 1/ 45.0
var offset_x = 2.57
var offset_y : float
var floor_offset_x = -.889
var floor_offset_y = -3.05
var grass_offset_x = 0
var grass_offset_y = 0

var scale_y = 1/ 18.5
@onready var grass_camera = $SubViewport/Camera3D

func _process(_delta: float) -> void:
	#$SubViewport/Characters/Small.position.x = LayerManager.player1.position.x * scale_x+offset_x
	#$SubViewport/Characters/Small.position.z = LayerManager.player1.position.y * scale_y+offset_y
	
	
	if not game_camera:
		return
	grass_camera.position.x = game_camera.position.x * scale_x
	grass_camera.position.z = game_camera.position.y * scale_y
	pass

func initalize(conflict_cells_in : Array, tilemaplayer : TileMapLayer):
	LayerManager = get_tree().get_root().get_node("LayerManager")
	game_camera = LayerManager.camera
	grass_display = game_camera.get_node("GrassTexture")
	grass_display.visible = true
	grass_display.texture = $SubViewport.get_texture()
	offset_y = -(sqrt(pow(grass_camera.position.y/cos(PI/2+grass_camera.rotation.x),2)-pow(grass_camera.position.y,2)))
	print(camera_offset)
	print("Generate_grass")
	$SubViewport/CharacterManager.offset_y = offset_y
	conflict_cells = conflict_cells_in
	target_tilemap = tilemaplayer
	generate()
	var mask = build_mask(target_tilemap)
	$SubViewport/Floor.material_override = $SubViewport/Floor.material_override.duplicate()
	$SubViewport/Floor.material_override.set_shader_parameter("mask_texture",mask)
	#mask.get_image().save_png("res://ui_captures/test.png")
	var used_rect = target_tilemap.get_used_rect()
	var tile_size = target_tilemap.tile_set.tile_size
	var width_pixels  = used_rect.size.x * tile_size.x
	var height_pixels = used_rect.size.y * tile_size.y
	$SubViewport/Floor.mesh.size = Vector2(width_pixels* scale_x, height_pixels* scale_y)
	$SubViewport/Floor.position.x=floor_offset_x
	$SubViewport/Floor.position.z=offset_y+floor_offset_y

func generate():
	if target_tilemap == null:
		push_error("No TileMapLayer assigned")
		return

	var valid_cells: Array[Vector2i] = []

	# --- Collect valid terrain cells ---
	for cell in target_tilemap.get_used_cells():
		if conflict_cells.has(cell):
			continue

		var cell_data := target_tilemap.get_cell_tile_data(cell)
		if cell_data == null:
			continue

		if cell_data.get_terrain_set() == terrain_set_id and cell_data.get_terrain() == terrain_id:
			valid_cells.append(cell)

	# --- Setup MultiMesh ---
	var total_instances := valid_cells.size() * instances_per_tile
	$SubViewport/Grass.multimesh.instance_count = total_instances
	var tile_size = target_tilemap.tile_set.tile_size

	var i := 0

	for cell in valid_cells:
		var tile_center_2d := target_tilemap.map_to_local(cell)

		for n in instances_per_tile:

			# Random offset inside tile + Convert to 3D space
			var final_pos := Vector3(
				(tile_center_2d.x + randf_range(-tile_size.x * 0.5, tile_size.x * 0.5)) * scale_x,
				0.0,
				(tile_center_2d.y + randf_range(-tile_size.y * 0.5, tile_size.y * 0.5)) * scale_y
			)

			final_pos.x += grass_offset_x
			final_pos.z += offset_y+grass_offset_y
			var transform_inst := Transform3D(Basis.IDENTITY,final_pos)

			$SubViewport/Grass.multimesh.set_instance_transform(i, transform_inst)
			i += 1

func build_mask(tilemap: TileMapLayer) -> ImageTexture:
	var used = tilemap.get_used_rect()
	var width = used.size.x
	var height = used.size.y
	
	var img = Image.create(width, height, false, Image.FORMAT_L8)
	img.fill(Color.BLACK)
	
	for cell in tilemap.get_used_cells():
		if conflict_cells.has(cell):
			continue
		
		var x = cell.x - used.position.x
		var y = cell.y - used.position.y
		img.set_pixel(x, y, Color.WHITE)
	
	var tex = ImageTexture.create_from_image(img)
	return tex
