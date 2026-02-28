
extends MultiMeshInstance2D
@export var conflict_cells: Array[Vector2i] = []



@export var terrain_set_id: int = 0
@export var terrain_id: int = 0
@export var instances_per_tile : int = 25
# Cells to avoid placing meshes on

const VIEW_ANGLE_DEG := 26.4
var view_compression := cos(deg_to_rad(VIEW_ANGLE_DEG))


func initalize(conflict_cells_in : Array):
	print("Generate_grass")
	conflict_cells=conflict_cells_in
	generate()
	

func generate():
	var tilemap := get_parent() as TileMapLayer
	if tilemap == null:
		push_error("Parent must be TileMapLayer")
		return

	var valid_cells: Array[Vector2i] = []

	# --- Collect valid terrain cells ---
	for cell in tilemap.get_used_cells():
		if conflict_cells.has(cell):
			continue

		var cell_data := tilemap.get_cell_tile_data(cell)
		if cell_data == null:
			continue

		if cell_data.get_terrain_set() == terrain_set_id and cell_data.get_terrain() == terrain_id:
			valid_cells.append(cell)

	# --- Setup MultiMesh ---
	var total_instances := valid_cells.size() * instances_per_tile
	multimesh.instance_count = total_instances

	var i := 0

	for cell in valid_cells:
		var tile_center := tilemap.map_to_local(cell)

		for n in instances_per_tile:

			# Random position inside tile (normalized -0.5 to 0.5)
			var local_offset := Vector2(
				randf_range(-0.5, 0.5),
				randf_range(-0.5/view_compression, 0.5/view_compression)
			)

			# Compress Y distribution for camera tilt
			local_offset.y *= view_compression

			# Convert to pixel space
			local_offset *= Vector2(16,16)

			var final_pos := tile_center + local_offset



			var instance_transform := Transform2D(0, final_pos)

			multimesh.set_instance_transform_2d(i, instance_transform)
			i += 1
