extends Node2D

@export var tilemaplayer: TileMapLayer
@export var available_tiles: Array[Vector2i]
@export var available_tiles_dictionary: Dictionary

@export var noise_scale: float = 0.08
@export var threshold: float = 0.65
@export var pixel_size: int = 4   # quantization size
@export var radius: float = 48.0


@onready var sprite = $Sprite2D

var noise := FastNoiseLite.new()
var outline_points: PackedVector2Array = []
@export var width: int = 64
@export var height: int = 64
var image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
var last_position :Vector2
var time = 0.0
var mask_texture : Texture2D
func _ready():
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = randi()
	noise.frequency = noise_scale

	for i in range(available_tiles.size()):
		available_tiles_dictionary[available_tiles[i]] = true
	generate_outline()

@export var pulse_speed := 3.0  # how fast it pulses
@export var pulse_min := 0.3    # minimum alpha
@export var pulse_max := 1.0    # maximum alpha
var passified = false
var time_period = 0
var total_time = 0
var player_owner : Node
var hit_range = 32
func _process(delta: float) -> void:
	if passified:
		total_time+=delta
		if floor(total_time*.5)>time_period:
			time_period=floor(total_time*.5)
			for enemy in get_tree().get_nodes_in_group("enemy"):
				if enemy.global_position.distance_squared_to(global_position) < hit_range:
					enemy.take_damage(3,player_owner,Vector2(0,-1), null)
					
			for player in get_tree().get_nodes_in_group("player"):
				if player.global_position.distance_squared_to(global_position) < hit_range:
					player.take_damage(3,player_owner,Vector2(0,-1), null)
	else:
		time+=delta
		sprite.modulate.a = sin(time)
		# Smooth sinusoidal pulse from min to max
		var t = (sin(time * pulse_speed) + 1.0) / 2.0  # normalize 0..1
		sprite.modulate.a = lerp(pulse_min, pulse_max, t)
		if last_position!= global_position:
			global_position = floor(global_position)
			last_position=global_position
			generate_outline()

func generate_outline(edge_only : bool = true):
	var center = Vector2(width / 2.0, height / 2.0)
	var max_dist = radius  # how large the guaranteed blob area is
	# First, compute all noise+radial values into a temporary array
	var values = []
	for x in width:
		values.append([])
		for y in height:
			var world_pos = Vector2(x, y) + global_position
			var tile_pos = Vector2i(floor(world_pos.x / 16.0), floor(world_pos.y / 16.0))-Vector2i(width/32.0,height/32.0)
			# Skip if tile is not in available_tiles
			if !available_tiles_dictionary.has(tile_pos):
				values[x].append(0.0)
				continue
				
			var n = noise.get_noise_2d(world_pos.x / 16.0, world_pos.y / 16.0)
			n = (n + 1.0) * 0.5  # -1..1 → 0..1
			
			
			# ---- radial mask (strong in middle, fades outward) ----
			var dist = center.distance_to(Vector2(x, y))
			var radial = clamp(.5 - (dist / max_dist), -.5, .5) * threshold/.5
			# Boost center to guarantee blob
			n = clamp(n+radial,0.0,1.0)
			
			values[x].append(n)
	
	for x in width:
		for y in height:
			var val = values[x][y]
			if val < threshold:
				image.set_pixel(x, y, Color(0,0,0,0))
				continue
				
			var is_edge = false
			# Check all 8 neighbors
			for dx in [-1,0,1]:
				for dy in [-1,0,1]:
					if dx == 0 and dy == 0:
						continue  # skip self
					var nx = x + dx
					var ny = y + dy
					if nx < 0 or ny < 0 or nx >= width or ny >= height:
						continue
					if values[nx][ny] < threshold:
						is_edge = true
						break
				if is_edge:
					break

			if is_edge:
				image.set_pixel(x, y, Color(1,1,1,1))
			else:
				if edge_only:
					image.set_pixel(x, y, Color(0,0,0,0))
				else:
					image.set_pixel(x, y, Color(0,0,0,1))
	if !edge_only:
		mask_texture= ImageTexture.create_from_image(image)
	sprite.texture = ImageTexture.create_from_image(image)
	
func passify(player : Node):
	player_owner = player
	passified = true
	print("Passified!")
	sprite.material = sprite.material.duplicate(true)
	sprite.material.set_shader_parameter("enabled",true)

func get_whole_image() -> Texture2D:
	generate_outline(false)
	return mask_texture
