class_name Pathfinding 
extends Node

var astar = AStar2D.new()
var grid_bounds: Rect2i
var walkable_set: Dictionary = {}
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
	walkable_set.clear()
	
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
			walkable_set[cell] = true
			var id = pos_to_id(cell)
			var weight = 1
			if trap_dict.has(cell):
				weight = 100
			if is_near_wall(cell, blocked_dict):
				weight = 3.0
			astar.add_point(id, Vector2(cell.x * cell_size, cell.y * cell_size), weight)

	
	# find neighboring walkable cells
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	
	# adds walkable neighbor cells to astar, mapping the bounding box
	for cell in walkable_cells:
		var id = pos_to_id(cell)
		for dir in directions: 
			var neighbor = cell + dir
			if walkable_set.has(neighbor):
				var neighbor_id = pos_to_id(neighbor)
				if not astar.are_points_connected(id, neighbor_id): 
					astar.connect_points(id,neighbor_id)
					
	# derive path from world pos to world pos 
	

func is_near_wall(cell: Vector2i,blocked_dict : Dictionary) -> bool:
	var check_dirs = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)  # Diagonals too
	]			
	for dir in check_dirs:
		if blocked_dict.has(cell + dir):
			return true 
	return false

func world_to_cell_clamped(world_pos: Vector2) -> Vector2i:
	var cell = Vector2i(floor(world_pos.x / cell_size), floor(world_pos.y / cell_size))
	# If the exact cell isn't walkable, search nearby walkable cells
	if walkable_set.has(cell):
		return cell
	var search_dirs = [
		Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)
	]
	for dir in search_dirs:
		var neighbor = cell + dir
		if walkable_set.has(neighbor):
			return neighbor
	return cell  # fallback

func find_path(from_world: Vector2, to_world: Vector2) -> Array:
	var from_cell = world_to_cell_clamped(from_world)
	var to_cell = world_to_cell_clamped(to_world)
	if not walkable_set.has(from_cell) or not walkable_set.has(to_cell):
		return []
	return astar.get_point_path(pos_to_id(from_cell), pos_to_id(to_cell))
	
	
func smooth_path(path: Array, ) -> Array: 
	if path.size() <= 1:
		return path

	var smooth: Array = [path[0]]
	var i := 0

	while i < path.size() - 1:
		# Walk forward from i as far as we can still see in a straight line
		var farthest := i + 1
		while farthest + 1 < path.size() and can_walk_straight(path[i], path[farthest + 1]):
			farthest += 1
		smooth.append(path[farthest])
		i = farthest

	return smooth

func can_walk_straight(from: Vector2, to: Vector2) -> bool:
	var from_cell = Vector2i(floor(from.x / cell_size), floor(from.y / cell_size))
	var to_cell = Vector2i(floor(to.x / cell_size), floor(to.y / cell_size))
	
	# Bresenham walk — no intermediate Array allocation
	var x  : int = from_cell.x;  var y  : int = from_cell.y
	var tx : int = to_cell.x;    var ty : int = to_cell.y
	var dx := absi(tx - x); var dy := absi(ty - y)
	var sx := 1 if x < tx else -1
	var sy := 1 if y < ty else -1
	var err := dx - dy

	var prev_x := x
	var prev_y := y

	while true:
		if not walkable_set.has(Vector2i(x, y)):   # O(1)
			return false

		# Diagonal corner-cutting check (no extra array)
		var step_x := x - prev_x
		var step_y := y - prev_y
		if step_x != 0 and step_y != 0:
			if not walkable_set.has(Vector2i(prev_x + step_x, prev_y)) \
			or not walkable_set.has(Vector2i(prev_x, prev_y + step_y)):
				return false

		if x == tx and y == ty:
			break

		prev_x = x;  prev_y = y
		var e2 := 2 * err
		if e2 > -dy:
			err -= dy;  x += sx
		if e2 < dx:
			err += dx;  y += sy

	return true
