class_name Pathfinding 
extends Node

var astar = AStar2D.new()
var grid_bounds: Rect2i
var walkable_cells: Array[Vector2i] = []
var cell_size: int = 16


#The pathfinding system 
#1. Takes all the cells from the "Ground" layer
#2. Removes any that overlap with `blocked_cells`
#3. Builds an A* grid from the remaining walkable cells
#4. Connects neighboring walkable cells

# reset function for changing rooms
func clear():
	astar.clear() # remove all points and connections from Astar
	walkable_cells.clear() # empty the walkable tiles list 
	
# Astar uses ID numbers rather than vectors to track points
func pos_to_id(pos: Vector2i) -> int: 
	var local_x = pos.x - grid_bounds.position.x
	var local_y = pos.y - grid_bounds.position.y
	return local_x + local_y * grid_bounds.size.x
	
# converts the id back into grid position 
func id_to_pos(id: int) -> Vector2i:
	var local_x = id % grid_bounds.size.x
	var local_y = id / grid_bounds.size.x
	return Vector2i(local_x + grid_bounds.position.x, local_y + grid_bounds.position.y)

# orgonises all the data from the layer_manager, 
func setup_from_room(ground_layer: TileMapLayer, blocked_cells: Array, trap_cells: Array, liquid_cells: Array):
	clear()
	
	# no used cells, return, nothing to do
	var used_cells = ground_layer.get_used_cells()
	if used_cells.is_empty():
		return
	
	# create a bounding box for all of the cells possible, used for id-ing them later 
	var min_x = used_cells[0].x
	var max_x = used_cells[0].x
	var min_y = used_cells[0].y
	var max_y = used_cells[0].y
	
	for cell in used_cells:
		min_x = min(min_x, cell.x)
		max_x = max(max_x, cell.x)
		min_y = min(min_y, cell.y)
		max_y = max(max_y, cell.y)
	
	grid_bounds = Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y +  1)
	
	var blocked_dict = {}
	for cell in blocked_cells: 
		blocked_dict[cell] = true 
	
	var trap_dict = {}
	for cell in trap_cells:
		trap_dict[cell] = true
	
	for cell in used_cells:
		if not blocked_dict.has(cell):
			walkable_cells.append(cell)
			var id = pos_to_id(cell)
			
			var weight = 0
			if trap_dict.has(cell):
				weight = 100
			
			astar.add_point(id, Vector2(cell.x * cell_size, cell.y * cell_size), weight)
			
	var is_near_wall = func(cell: Vector2i) -> bool:
		var check_dirs = [
			Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)  # Diagonals too
		]
		for dir in check_dirs:
			if blocked_dict.has(cell + dir):
				return true 
		return false
	
	# find neighboring walkable cells
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	
	# adds walkable neighbor cells to astar, mapping the bounding box
	for cell in walkable_cells:
		var id = pos_to_id(cell)
	
		for dir in directions: 
			var neighbor = cell + dir
			if neighbor in walkable_cells: 
				var neighbor_id = pos_to_id(neighbor)
				if not astar.are_points_connected(id, neighbor_id): 
					var weight = 1.0
					
					if is_near_wall.call(cell) or is_near_wall.call(neighbor):
						weight = 3.0
					astar.connect_points(id,neighbor_id)
					astar.set_point_weight_scale(id, weight)
					
	# derive path from world pos to world pos 


func world_to_cell_clamped(world_pos: Vector2) -> Vector2i:
	var cell = Vector2i(floor(world_pos.x / cell_size), floor(world_pos.y / cell_size))
	# If the exact cell isn't walkable, search nearby walkable cells
	if cell in walkable_cells:
		return cell
	var search_dirs = [
		Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)
	]
	for dir in search_dirs:
		var neighbor = cell + dir
		if neighbor in walkable_cells:
			return neighbor
	return cell  # fallback

func find_path(from_world: Vector2, to_world: Vector2) -> Array:
	var from_cell = world_to_cell_clamped(from_world)
	var to_cell = world_to_cell_clamped(to_world)

	if not from_cell in walkable_cells or not to_cell in walkable_cells:
		return []

	var from_id = pos_to_id(from_cell)
	var to_id = pos_to_id(to_cell)
	return astar.get_point_path(from_id, to_id)
	
	
func smooth_path(path: Array, ) -> Array: 
	var smooth = [path[0]]
	var i = 0 
	
	# try skipping intermediate points
	while i < path.size() - 1: 
		var current = path[i]
		var next_node = i + 1
		
		while next_node < path.size(): 
			var target = path[next_node]
			
			if can_walk_straight(current, target): 
				next_node += 1
			else: 
				break
				
		var next_point = path[next_node - 1]
		if next_point != current:
			smooth.append(next_point)
			
		i = next_node - 1
			
	if smooth[smooth.size() - 1] != path[path.size() - 1]: 
		smooth.append(path[path.size() - 1])
	
	return smooth
	
	
	# Bresenham's algorithm
func get_line_cells(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	
	var dx = abs(to.x - from.x)
	var dy = abs(to.y - from.y)
	var sx = 1 if from.x < to.x else -1
	var sy = 1 if from.y < to.y else -1
	var err = dx - dy
	
	var current = from
	
	while true:
		cells.append(current)
		
		if current == to:
			break
		
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			current.x += sx
		if e2 < dx:
			err += dx
			current.y += sy
	
	return cells
	
func can_walk_straight(from: Vector2, to: Vector2) -> bool:
	var from_cell = Vector2i(floor(from.x / cell_size), floor(from.y / cell_size))
	var to_cell = Vector2i(floor(to.x / cell_size), floor(to.y / cell_size))
	
	# Use Bresenham's line algorithm to check all cells along the line
	var cells_on_line = get_line_cells(from_cell, to_cell)
	
	# Check if all cells on the line are walkable
	for cell in cells_on_line:
		if not cell in walkable_cells:
			return false
	
	# ADDITIONAL CHECK: Make sure we're not cutting corners diagonally through walls
	# Check the cells adjacent to the line
	for i in range(len(cells_on_line) - 1):
		var current = cells_on_line[i]
		var next = cells_on_line[i + 1]
		
		# If moving diagonally, check both adjacent cells
		var dx = next.x - current.x
		var dy = next.y - current.y
		
		if dx != 0 and dy != 0:  # Diagonal move
			# Check the two cells that form the corner
			var corner1 = Vector2i(current.x + dx, current.y)
			var corner2 = Vector2i(current.x, current.y + dy)
			
			# Both corners must be walkable to allow diagonal movement
			if not (corner1 in walkable_cells and corner2 in walkable_cells):
				return false
	
	return true
