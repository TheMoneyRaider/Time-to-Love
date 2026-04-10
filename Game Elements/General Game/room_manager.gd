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
	0	#Rooms since shop room 			13
	]
#the root node of each room MUST BE NAMED Root
@onready var current_progress = 0.0
var medieval_rooms : Array[Room] = [preload("res://Game Elements/Rooms/resources/cave1.tres"),
								preload("res://Game Elements/Rooms/resources/cave2.tres"),
								preload("res://Game Elements/Rooms/resources/cave3.tres"),
								preload("res://Game Elements/Rooms/resources/cave4.tres"),
								preload("res://Game Elements/Rooms/resources/outside1.tres"),
								preload("res://Game Elements/Rooms/resources/outside2.tres"),
								preload("res://Game Elements/Rooms/resources/outside3.tres"),
								preload("res://Game Elements/Rooms/resources/outside4.tres"),
								preload("res://Game Elements/Rooms/resources/outside5.tres")]
var medieval_shops : Array[Room] = [preload("res://Game Elements/Rooms/resources/shop_cyberspace.tres"),
								preload("res://Game Elements/Rooms/resources/shop_factory.tres")]

var western_rooms : Array[Room] = [preload("res://Game Elements/Rooms/resources/canyon1.tres"),
								preload("res://Game Elements/Rooms/resources/canyon2.tres"),
								preload("res://Game Elements/Rooms/resources/canyon3.tres")]
var western_shops : Array[Room] = [preload("res://Game Elements/Rooms/resources/shop_cyberspace.tres"),
								preload("res://Game Elements/Rooms/resources/shop_factory.tres")]

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
								
var testing_room : Room = preload("res://Game Elements/Rooms/resources/testing_room.tres")
#preload("res://Game Elements/Rooms/resources/testing_room.tres")
var bosses : Array[Room] = [preload("res://Game Elements/Rooms/resources/medieval_boss.tres"),
	preload("res://Game Elements/Rooms/resources/scifi_boss.tres"),
						preload("res://Game Elements/Rooms/resources/scifi_boss.tres"),
						preload("res://Game Elements/Rooms/resources/scifi_boss.tres")
						]

var cached_scenes : Dictionary = {}


var normal_rooms : Array = []
var shop_rooms : Array = []

func get_room(room : Room):
	var index = int(current_progress) if room.roomtype != Globals.RoomType.Boss else int(current_progress+1.0)
	#shop_override
	var T = 0.15
	var P = 0.05

	var base = T + (T - float(layer_ai[8]) / max(layer_ai[0],1))
	var prob = base + P * layer_ai[13]
	var shop_override = clamp(prob, 0.0, 1.0)
	if shop_override > randf() and layer_ai[0] > 3 and room.roomtype != Globals.RoomType.Shop:
		var shop_index = clamp(int(randf()*shop_rooms[index].size()),0,shop_rooms[index].size()-1)
		return shop_rooms[index][shop_index]
	if get_boss_chance() > randf()+.01:
		return bosses[index]

	var normal_index = clamp(int(randf()*normal_rooms[index].size()),0,normal_rooms[index].size()-1)
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

#func choose_room() -> void:
	##Shuffle rooms and load one
	#room_instance_data = sci_fi_layer[randi() % sci_fi_layer.size()]
	#
	#room_location = load(room_instance_data.scene_location)
	#room_instance = room_location.instantiate()
	#game_root.add_child(room_instance)
	
	

func update_ai_array(generated_room : Node2D, generated_room_data : Room, LayerManager : Node) -> void:
	if generated_room_data==testing_room:
		LayerManager.time_passed = 0.0
		layer_ai = [0,0,0,0,0,0,0,0,0,0,0,0,0,0]
		return
	#Rooms cleared
	layer_ai[0] += 1
	#Combat rooms cleared
	if generated_room_data.roomtype == Globals.RoomType.Combat or generated_room_data.roomtype == Globals.RoomType.Boss:
		RoomManager.layer_ai[1] += 1
	#Last room time
	layer_ai[2] = LayerManager.time_passed - layer_ai[3]
	#Total time
	layer_ai[3] = LayerManager.time_passed
	if generated_room_data.roomtype == Globals.RoomType.Shop:
		layer_ai[8] += 1
		layer_ai[13] = 0
	else:
		layer_ai[13] += 1
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
	
	current_progress = 1-exp(-0.1386*layer_ai[0])
	if generated_room_data.roomtype == Globals.RoomType.Boss:
		current_progress = floor(current_progress)+1.0

func get_boss_chance() -> float:
	return pow((layer_ai[0]-10),2)/200 if current_progress-int(current_progress) > .85 else 0.0
	#WE NEED THIS TO BE QUICKER
	
	
