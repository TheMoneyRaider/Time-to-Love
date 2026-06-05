extends Node3D

@export var terrain_set_id: int = 0
@export var terrain_id: int = 0
@export var instances_per_tile : int = 25
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

@export var target_tilemap : TileMapLayer

var scale_y = 1/ 18.5
@onready var grass_camera = $SubViewport/Camera3D

func _ready() -> void:
	$SubViewport/Floor.visible = false
var override : bool = false

func start_override(passed_position : Vector2):
	override= true
	grass_camera.position.x = passed_position.x * scale_x
	grass_camera.position.z = passed_position.y * scale_y

func _process(_delta: float) -> void:
	if not game_camera or override:
		return
	grass_camera.position.x = game_camera.position.x * scale_x
	grass_camera.position.z = game_camera.position.y * scale_y
	pass

func initalize(_conflict_cells_in : Array):
	print("init")
	LayerManager = get_tree().get_root().get_node("LayerManager")
	game_camera = LayerManager.camera
	offset_y = -16.1867697662462 #-(sqrt(pow(grass_camera.position.y/cos(PI/2+grass_camera.rotation.x),2)-pow(grass_camera.position.y,2)))
	print("Generate_grass")
	#$SubViewport/CharacterManager.offset_y = offset_y
	generate()
	var mask = build_mask(target_tilemap)
	$SubViewport/Floor.visible = true
	$SubViewport/Floor.material_override =$SubViewport/Floor.material_override.duplicate(true)
	var mat = $SubViewport/Floor.material_override
	mat.set_shader_parameter("mask_texture", mask)
	mat.set_shader_parameter("mask_scale", Vector2(scale_x, scale_y))
	mat.set_shader_parameter("mask_offset",Vector2(target_tilemap.get_used_rect().position) +
	Vector2(0, offset_y / scale_y / target_tilemap.tile_set.tile_size.y))
	mat.set_shader_parameter("mask_tex_size",Vector2(mask.get_width(), mask.get_height()))
	
	grass_display = game_camera.get_node("GrassTexture")
	grass_display.visible = true
	grass_display.texture = $SubViewport.get_texture()

func generate():
	if target_tilemap == null:
		push_error("No TileMapLayer assigned")
		return

	var valid_cells: Array[Vector2i] = []

	# --- Collect valid terrain cells ---
	for cell in target_tilemap.get_used_cells():

		var cell_data := target_tilemap.get_cell_tile_data(cell)
		if cell_data == null:
			continue

		if cell_data.get_terrain_set() == terrain_set_id and cell_data.get_terrain() == terrain_id:
			valid_cells.append(cell)

	# --- Setup MultiMesh ---
	var total_instances := valid_cells.size() * instances_per_tile
	$SubViewport/Grass.multimesh = $SubViewport/Grass.multimesh.duplicate(true)
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
		
		var cell_data := target_tilemap.get_cell_tile_data(cell)
		if cell_data == null:
			continue

		if cell_data.get_terrain_set() == terrain_set_id and cell_data.get_terrain() == terrain_id:
			var x = cell.x - used.position.x
			var y = cell.y - used.position.y
			
			img.set_pixel(x, y, Color.WHITE)
	
	return ImageTexture.create_from_image(img)
