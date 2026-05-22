# FootprintPool.gd
# Attach this script to a Node2D child of your Player node.
# It manages a fixed pool of footprint Sprite2D nodes — no allocations at runtime.
#
# SETUP:
#   1. Add a Node2D child to your Player, name it "FootprintPool"
#   2. Attach this script to it
#   3. Assign a small footprint texture to `footprint_texture` in the Inspector
#   4. Call spawn_footprint() from your Player script each time a foot lands
 
class_name FootprintPool
extends Node2D
 
## How many footprints can exist simultaneously.
## 40 is plenty for a single player; raise for multiple NPCs.
@export var pool_size: int = 40
 
## Your footprint sprite texture (e.g. a 4x6 pixel boot shape).
@export var footprint_texture: Texture2D = load("res://art/footprint.png")
 
## How many seconds before a footprint fully fades out.
@export var fade_duration: float = 2.0
 
## Tint color — change per surface (sandy = Color(0.8,0.6,0.3), mud = Color(0.3,0.2,0.1))
@export var footprint_color: Color = Color(0.2, 0.2, 0.2, 0.659)
 
# Internal pool state
var _pool: Array[Sprite2D] = []
var _timers: Array[float] = []   # remaining lifetime per slot
var _head: int = 0               # next slot to overwrite (ring buffer)

var LayerManager : Node = null
 
func _ready() -> void:
	LayerManager = get_tree().get_root().get_node("LayerManager")
	_build_pool()
 
 
func _build_pool() -> void:
	for i in pool_size:
		var s := Sprite2D.new()
		s.texture = footprint_texture
		s.modulate = Color(footprint_color.r, footprint_color.g,
							footprint_color.b, 0.0)   # start invisible
		# Footprints live in world space, so reparent to the scene root
		# so they don't move when the player moves.
		LayerManager.game_root.add_child(s)
		s.z_index = 18
		s.z_as_relative = false
		s.scale = Vector2(.75,.75)
		_pool.append(s)
		_timers.append(0.0)
 
 
## Call this from your Player script when a foot touches the ground.
##
##   world_pos  – exact world position of the footprint
##   direction  – player's current velocity.normalized() or facing angle
##   is_left    – true = left foot, false = right foot
func spawn_footprint(world_pos: Vector2, direction: Vector2, is_left: bool) -> void:
	var slot: int = _head
	_head = (_head + 1) % pool_size
 
	var s: Sprite2D = _pool[slot]
	_timers[slot] = fade_duration
 
	# Offset slightly sideways so left/right prints don't stack
	var perp := Vector2(-direction.y, direction.x)   # perpendicular
	var side_offset: float = 2.0 * (-1.0 if is_left else 1.0)
	s.global_position = world_pos + perp * side_offset +Vector2(0,5) #Foot offset
 
	# Rotate to match movement direction
	s.rotation = direction.angle()+PI/2
 
	# Flip horizontally for left vs right foot
	s.flip_h = is_left
 
	# Snap to pixel grid (critical for pixel art)
	s.global_position = s.global_position.round()
 
	# Full opacity on spawn
	s.modulate = footprint_color
 
 
func _process(delta: float) -> void:
	for i in pool_size:
		if _timers[i] <= 0.0:
			continue
		_timers[i] -= delta
		var alpha: float
		if _timers[i] <= 0.0:
			alpha = 0.0
			_timers[i] = 0.0
		else:
			# Ease-out fade: stays visible longer, then quickly disappears
			var t: float = _timers[i] / fade_duration
			alpha = t * t * footprint_color.a
		var c := _pool[i].modulate
		c.a = alpha
		_pool[i].modulate = c
