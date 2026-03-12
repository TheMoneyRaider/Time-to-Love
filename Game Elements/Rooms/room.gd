class_name Room
extends Resource

@export var scene_location : String

@export var num_liquid : int = 0
@export var liquid_types : Array[Globals.Liquid] = []
@export var liquid_chances : Array[float] = []

@export var num_fillings : int = 0
@export var fillings_terrain_set : Array[int] = []
@export var fillings_terrain_id : Array[int] = []
@export var fillings_terrain_threshold : Array[float] = []

var noise := FastNoiseLite.new()
@export var noise_seed : int = randi()
@export var noise_type : int = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
@export var noise_frequency : float = .1

@export var num_trap : int = 0
@export var trap_chances : Array[float] = []
@export var trap_types : Array[Globals.Trap] = []

@export var num_pathways : int = 4
@export var pathway_direction : Array[Globals.Direction] = [Globals.Direction.Up,Globals.Direction.Down,Globals.Direction.Left,Globals.Direction.Right]

@export var num_enemy_goal : int = 10

@export var roomtype : Globals.RoomType = Globals.RoomType.Combat
@export var roomvariant : Globals.RoomVariant = Globals.RoomVariant.SciFiFactory

@export var enemy_pool : Array[String] = []
@export var enemy_chances : Array[float] = []

@export var wave_segment : float = .1
@export var letter_goal : int = 2
