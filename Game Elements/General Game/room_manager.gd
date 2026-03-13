extends Node

###Z ORDERS
#0-9 background enviornmental elements(flooring,etc)
#10-19 background dynamic elements(grass, floor attacks)
#20-29 Player area(player is 20, most enemies are 20)
#30-39 Filling and portals
#40-49 UI Elements
####

#the root node of each room MUST BE NAMED Root

var medieval_rooms : Array[Room] = [preload("res://Game Elements/Rooms/resources/cave1.tres"),
							preload("res://Game Elements/Rooms/resources/cave2.tres"),
							preload("res://Game Elements/Rooms/resources/cave3.tres"),
							preload("res://Game Elements/Rooms/resources/cave4.tres"),
							preload("res://Game Elements/Rooms/resources/outside1.tres"),
							preload("res://Game Elements/Rooms/resources/outside2.tres"),
							preload("res://Game Elements/Rooms/resources/outside3.tres"),
							preload("res://Game Elements/Rooms/resources/outside4.tres"),
							preload("res://Game Elements/Rooms/resources/outside5.tres")]

var western_rooms : Array[Room] = [preload("res://Game Elements/Rooms/resources/canyon1.tres"),
								preload("res://Game Elements/Rooms/resources/canyon2.tres"),
								preload("res://Game Elements/Rooms/resources/canyon3.tres"),
								preload("res://Game Elements/Rooms/resources/canyon4.tres")]

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

var testing_room : Room = preload("res://Game Elements/Rooms/resources/testing_room.tres")
var bosses : Array[Room] = [preload("res://Game Elements/Rooms/resources/scifi_boss.tres")]

var cached_scenes : Dictionary = {}

func get_room():
	return sci_fi_rooms[0]
func _ready() -> void:
	for room_data_item in medieval_rooms:
		if not cached_scenes.has(room_data_item.scene_location):
			var packed = ResourceLoader.load(room_data_item.scene_location, "PackedScene")
			cached_scenes[room_data_item.scene_location] = packed
	for room_data_item in western_rooms:
		if not cached_scenes.has(room_data_item.scene_location):
			var packed = ResourceLoader.load(room_data_item.scene_location, "PackedScene")
			cached_scenes[room_data_item.scene_location] = packed
	for room_data_item in sci_fi_rooms:
		if not cached_scenes.has(room_data_item.scene_location):
			var packed = ResourceLoader.load(room_data_item.scene_location, "PackedScene")
			cached_scenes[room_data_item.scene_location] = packed
	for room_data_item in bosses:
		if not cached_scenes.has(room_data_item.scene_location):
			var packed = ResourceLoader.load(room_data_item.scene_location, "PackedScene")
			cached_scenes[room_data_item.scene_location] = packed

#
#func choose_room() -> void:
	##Shuffle rooms and load one
	#room_instance_data = sci_fi_layer[randi() % sci_fi_layer.size()]
	#
	#room_location = load(room_instance_data.scene_location)
	#room_instance = room_location.instantiate()
	#game_root.add_child(room_instance)
