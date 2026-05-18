extends Node

###Z ORDERS
#0-9 background enviornmental elements(flooring,etc)
#10-19 background dynamic elements(grass, floor attacks)
#20-29 Player area(player is 20, most enemies are 20)
#30-39 Filling and portals
#40-49 UI Elements
####

var layer_ai := [
	0,	#Rooms cleared 					0
	0,	#Combat rooms cleared			1
	0,	#Time spent in last room		2
	0,	#Time spent in game				3
	0,	#Time spent in combat			4
	0,	#Damage dealt					5
	0,	#Attacks made					6
	0,	#Enemies defeated				7
	0,	#Shops visited					8
	0,	#Liquid rooms visited			9
	0,	#Trap rooms visited				10
	0,	#Damage taken					11
	0,	#Currency collected				12
	0,	#Rooms since shop room 			13
	0,	#This timeline Rooms cleared 	14
	0	#This timeline Combat rooms cleared 15
	]
#the root node of each room MUST BE NAMED Root
@onready var current_progress = 0.0 #TEST 3.0
var medieval_rooms : Array[Room] = [preload("res://Game Elements/Rooms/resources/cave1.tres"),
								preload("res://Game Elements/Rooms/resources/cave2.tres"),
								preload("res://Game Elements/Rooms/resources/cave3.tres"),
								preload("res://Game Elements/Rooms/resources/cave4.tres"),
								preload("res://Game Elements/Rooms/resources/outside1.tres"),
								preload("res://Game Elements/Rooms/resources/outside2.tres"),
								preload("res://Game Elements/Rooms/resources/outside3.tres"),
								preload("res://Game Elements/Rooms/resources/outside4.tres"),
								preload("res://Game Elements/Rooms/resources/outside5.tres")]
var medieval_shops : Array[Room] = [preload("res://Game Elements/Rooms/resources/shop_cave.tres"),
								preload("res://Game Elements/Rooms/resources/shop_outside.tres")]

var western_rooms : Array[Room] = [preload("res://Game Elements/Rooms/resources/canyon3.tres"),
								preload("res://Game Elements/Rooms/resources/canyon4.tres"),
								preload("res://Game Elements/Rooms/resources/canyon5.tres"),
								preload("res://Game Elements/Rooms/resources/canyon6.tres")]
var western_shops : Array[Room] = [preload("res://Game Elements/Rooms/resources/shop_town.tres")]

var sci_fi_rooms : Array[Room] = [preload("res://Game Elements/Rooms/resources/factory1.tres"),
								preload("res://Game Elements/Rooms/resources/factory2.tres"),
								preload("res://Game Elements/Rooms/resources/factory3.tres"),
								preload("res://Game Elements/Rooms/resources/factory4.tres"),
								preload("res://Game Elements/Rooms/resources/cyberspace1.tres"),
								preload("res://Game Elements/Rooms/resources/cyberspace2.tres"),
								preload("res://Game Elements/Rooms/resources/cyberspace3.tres"),
								preload("res://Game Elements/Rooms/resources/cyberspace4.tres"),
								preload("res://Game Elements/Rooms/resources/cyberspace5.tres"),
								preload("res://Game Elements/Rooms/resources/cyberspace6.tres")]
var sci_fi_shops : Array[Room] = [preload("res://Game Elements/Rooms/resources/shop_cyberspace.tres"),
								preload("res://Game Elements/Rooms/resources/shop_factory.tres")]
								
var starting_rooms : Array[Room] = [preload("res://Game Elements/Rooms/resources/1.tres"),
									preload("res://Game Elements/Rooms/resources/2.tres"),
									preload("res://Game Elements/Rooms/resources/3.tres")]
 #preload("res://Game Elements/Rooms/resources/testing_room.tres")


var bosses : Array[Room] = [preload("res://Game Elements/Rooms/resources/medieval_boss.tres"),
						preload("res://Game Elements/Rooms/resources/western_boss.tres"),
						preload("res://Game Elements/Rooms/resources/scifi_boss.tres"),
						preload("res://Game Elements/Rooms/resources/limbo_boss.tres")
						]

var cached_scenes : Dictionary = {}

var replacement_enemies : Array[PackedScene] = [
		load("res://Game Elements/Characters/tentacle1.tscn"),
		load("res://Game Elements/Characters/tentacle2.tscn"),
		load("res://Game Elements/Characters/tentacle3.tscn"),
	]
var normal_rooms : Array = []
var shop_rooms : Array = []
var tempvar : bool = true
func get_room(room : Room):
	if tempvar:
		tempvar = false
		return bosses[1]
	var index = int(current_progress) if room.roomtype != Globals.RoomType.Boss else int(current_progress+1.0)
	if index >= 3:
		index = randi() % 3
	#shop_override
	var T = 0.15
	var P = 0.05

	var base = T + (T - float(layer_ai[8]) / max(layer_ai[0],1))
	var prob = base + P * layer_ai[13]
	var shop_override = clamp(prob, 0.0, .75)
	if shop_override > randf() and layer_ai[0] > 3 and room.roomtype != Globals.RoomType.Shop and current_progress < 3.0 and room.roomtype != Globals.RoomType.Boss:
		var shop_index = clamp(int(randf()*shop_rooms[index].size()),0,shop_rooms[index].size()-1)
		layer_ai[8] += 1
		return shop_rooms[index][shop_index]
	#Removed a  +.01, don't know why that was needed.
	if get_boss_chance() > randf() and room.roomtype != Globals.RoomType.Boss:
		return bosses[index]

	var normal_index = clamp(int(randf()*normal_rooms[index].size()),0,normal_rooms[index].size()-1)
	if normal_rooms[index][normal_index]==room:
		return get_room(room)
	return normal_rooms[index][normal_index]
	

func _ready() -> void:
	normal_rooms = [medieval_rooms,western_rooms,sci_fi_rooms]
	shop_rooms = [medieval_shops,western_shops,sci_fi_shops]
	for array in normal_rooms:
		for room_data_item in array:
			if not cached_scenes.has(room_data_item.scene_location):
				var packed = ResourceLoader.load(room_data_item.scene_location, "PackedScene")
				cached_scenes[room_data_item.scene_location] = packed
	for array in shop_rooms:
		for room_data_item in array:
			if not cached_scenes.has(room_data_item.scene_location):
				var packed = ResourceLoader.load(room_data_item.scene_location, "PackedScene")
				cached_scenes[room_data_item.scene_location] = packed
	for room_data_item in bosses:
		if not cached_scenes.has(room_data_item.scene_location):
			var packed = ResourceLoader.load(room_data_item.scene_location, "PackedScene")
			cached_scenes[room_data_item.scene_location] = packed

func update_ai_array(generated_room : Node2D, generated_room_data : Room, LayerManager : Node) -> void:
	if generated_room_data in starting_rooms:
		LayerManager.time_passed = 0.0
		layer_ai = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
		return
	#Rooms cleared
	layer_ai[0] += 1
	layer_ai[13] += 1
	layer_ai[14] += 1
	#Combat rooms cleared
	if generated_room_data.roomtype == Globals.RoomType.Combat or generated_room_data.roomtype == Globals.RoomType.Boss:
		RoomManager.layer_ai[1] += 1
		RoomManager.layer_ai[15] += 1
	#Last room time
	layer_ai[2] = LayerManager.time_passed - layer_ai[3]
	#Total time
	layer_ai[3] = LayerManager.time_passed
	if generated_room_data.roomtype == Globals.RoomType.Shop:
		layer_ai[8] += 1
		layer_ai[13] = 0
	if generated_room_data.num_liquid > 0:
		var liquid_num = 0
		var liquid_type : String
		while liquid_num < generated_room_data.num_liquid:
			liquid_num+=1
			liquid_type= LayerManager._get_liquid_string(generated_room_data.liquid_types[liquid_num-1])
			if LayerManager.if_node_exists(liquid_type+str(liquid_num),generated_room):
				layer_ai[9] += 1   #Liquid room
				break
	if generated_room_data.num_trap > 0:
		var trap_num = 0
		while trap_num < generated_room_data.num_trap:
			trap_num+=1
			if LayerManager.if_node_exists("Trap"+str(trap_num),generated_room):
				layer_ai[10] += 1   #Trap room
				break
	
	current_progress = floor(current_progress)+1-exp(-0.25*layer_ai[0])
	if generated_room_data.roomtype == Globals.RoomType.Boss:
		current_progress = floor(current_progress)+1.0
		layer_ai[14] =0
		layer_ai[15] =0
	#current_progress = max(3.0,current_progress)#TEST

func get_boss_chance() -> float:
	if layer_ai[14] + int(current_progress) >= 8:
		return 1.0
	return 1.0 / (1 + exp(-.8 * ((current_progress + layer_ai[14] - 5)))) if layer_ai[14] >= 5 else 0.0
	#return pow((layer_ai[0]-10),2)/200 if current_progress-int(current_progress) > .85 else 0.0
	#WE NEED THIS TO BE QUICKER
	
var cur_prog = 0.0
var new_prog = 0.0
func make_room_limbo(room_reference : Node, z_val : int, layermanager : Node,set_values : bool = true):
	if set_values:
		cur_prog = current_progress - floor(current_progress)
		new_prog = 1-exp(-0.1386*(layer_ai[0]+1))
		cur_prog = _cubic_bezier_ease(.74,.23,.88,.43,cur_prog)
		new_prog = _cubic_bezier_ease(.74,.23,.88,.43,new_prog)
		
	for child in room_reference.get_children():
		make_room_limbo(child, z_val +child.z_index if "z_index" in child else z_val,layermanager, false)
		if child.name =="GrassAddon":
			layermanager.camera.get_node("GrassTexture").material.set_shader_parameter("z_order",z_val)
			print("grass: "+str(z_val))
			var tween = child.create_tween()
			tween.tween_method(
				func(value: float): layermanager.camera.get_node("GrassTexture").material.set_shader_parameter("progress", value),
				cur_prog,  # from
				new_prog,  # to
				25.0   # duration in seconds
			)
		if child is TileMapLayer and child.material != null:
			print(child.name +" "+str(z_val +child.z_index))
			child.material.set_shader_parameter("z_order",z_val +child.z_index)
			var tween = child.create_tween()
			tween.tween_method(
				func(value: float): child.material.set_shader_parameter("progress", value),
				cur_prog,  # from
				new_prog,  # to
				25.0   # duration in seconds
			)
	
func _cubic_bezier_ease(x1: float, y1: float, x2: float, y2: float, t: float) -> float:
	var sample = t
	for i in range(8):
		var x = _bezier_coord(x1, x2, sample)
		var dx = _bezier_coord_derivative(x1, x2, sample)
		if abs(dx) < 0.0001: break
		sample -= (x - t) / dx
	return _bezier_coord(y1, y2, sample)

func _bezier_coord(p1: float, p2: float, t: float) -> float:
	return 3.0 * p1 * t * (1.0 - t) * (1.0 - t) \
		 + 3.0 * p2 * t * t * (1.0 - t) \
		 + t * t * t

func _bezier_coord_derivative(p1: float, p2: float, t: float) -> float:
	return 3.0 * p1 * (1.0 - t) * (1.0 - 2.0 * t) \
		 + 3.0 * p2 * t * (2.0 - 3.0 * t) \
		 + 3.0 * t * t
