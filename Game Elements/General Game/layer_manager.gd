extends Node2D
const room = preload("res://Game Elements/Rooms/room.gd")
const room_data = preload("res://Game Elements/Rooms/room_data.gd")
@onready var timefabric = preload("res://Game Elements/Objects/time_fabric.tscn")
@onready var room_d = room_data.new()
@onready var sci_fi_layer : Array[Room] = room_d.sci_fi_rooms
@onready var sci_fi_layer_shops : Array[Room] = room_d.sci_fi_shops
@onready var bosses : Array[Room] = room_d.boss_rooms
@onready var testing_room : Room = room_d.testing_room
@onready var reward_num : Array = [1.0,1.0,1.0,1.0,1.0,1.0]
### Temp Multiplayer Fix
var player1 = null
var player2 = null
var weapon1 = "res://Game Elements/Weapons/Crowbar.tres"
var weapon2 = "res://Game Elements/Weapons/Railgun.tres"
var undiscovered_weapons = []
var possible_weapon = ""#undiscovered_weapons.pick_random()
###
@onready var room_cleared: bool = false
@onready var reward_claimed: bool = false
@onready var timefabric_masks: Array[Array]
@onready var timefabric_sizes: Array[Vector3i]
@onready var timefabric_collected: int = 0
@onready var timefabric_rewarded = 0
var camera_override : bool = false

@onready var player_1_remnants: Array[Remnant] = []
@onready var player_2_remnants: Array[Remnant] = []
var room_instance_data : Room
var generated_rooms : = {}
var generated_room_metadata : = {}
var generated_room_conflict : = {}
var generated_room_entrance : = {}
var global_conflict_cells= []
var placable_cells= []
var this_room_reward1 = Globals.Reward.HealthUpgrade
var this_room_reward2 = Globals.Reward.HealthUpgrade
var is_wave_room = false
var total_waves = 0
var current_wave = 0

#Thread Stuff
var pending_room_creations: Array = []
var terrain_update_queue: Array = []
var room_gen_thread: Thread
var thread_result: Dictionary
var thread_running := false

#A list of all the tile locations that have an additional tile on them(i.e liquids, traps, etc)
@onready var pathfinding = Pathfinding.new()

@onready var camera = $game_container/game_viewport/game_root/Camera2D
@onready var game_root = $game_container/game_viewport/game_root
@onready var hud = $Hud
@onready var pause = $PauseMenu
@onready var BossIntro = $BossIntro
@onready var awareness_display = $EnemyAwareness/AwarenessManager

#Cached scenes to speed up room loading at runtime
@onready var cached_scenes := {}
var room_location : Resource 
var room_instance
var remnant_offer_popup
var remnant_upgrade_popup
#The total time of this run
var time_passed := 0.0
var trap_cells := []
var blocked_cells := []
var liquid_cells : Array[Array]= [[],[],[],[],[],[],[],[],[],[]]
var is_multiplayer = Globals.is_multiplayer
#
var layer_ai := [
	0,#Rooms cleared
	0,#Combat rooms cleared
	0,#Time spent in last room
	0,#Time spent in game
	0,#Time spent in combat
	0,#Damage dealt
	0,#Attacks made
	0,#Enemies defeated
	0,#Shops visited
	0,#Liquid rooms visited
	0,#Trap rooms visited
	0,#Damage taken
	0,#Currency collected
	]

func _ready() -> void:
	var conflict_cells : Array[Vector2i] = []
	_setup_players()
	hud.set_players(player1,player2)
	hud.connect_signals(player1)
	hud.set_cross_position()
	
	####Remnant Testing
	
	var rem = load("res://Game Elements/Remnants/hack.tres")
	rem.rank = 4
	player_1_remnants.append(rem.duplicate(true))
	player_2_remnants.append(rem.duplicate(true))
	rem = load("res://Game Elements/Remnants/ninja.tres")
	rem.rank = 5
	player_1_remnants.append(rem.duplicate(true))
	player_2_remnants.append(rem.duplicate(true))
	rem = load("res://Game Elements/Remnants/emp.tres")
	rem.rank = 4
	player_1_remnants.append(rem.duplicate(true))
	player_2_remnants.append(rem.duplicate(true))
	rem = load("res://Game Elements/Remnants/intelligence.tres")
	rem.rank = 4
	player_1_remnants.append(rem.duplicate(true))
	player_2_remnants.append(rem.duplicate(true))
	rem = load("res://Game Elements/Remnants/adrenal_injector.tres")
	rem.rank = 4
	player_1_remnants.append(rem.duplicate(true))
	player_2_remnants.append(rem.duplicate(true))
	rem = load("res://Game Elements/Remnants/body_phaser.tres")
	rem.rank = 4
	player_1_remnants.append(rem.duplicate(true))
	player_2_remnants.append(rem.duplicate(true))
	#rem = load("res://Game Elements/Remnants/crafter.tres")
	#rem.rank = 4
	#player_1_remnants.append(rem.duplicate(true))
	#player_2_remnants.append(rem.duplicate(true))
	rem = load("res://Game Elements/Remnants/drone.tres")
	rem.rank = 4
	player_1_remnants.append(rem.duplicate(true))
	player_2_remnants.append(rem.duplicate(true))
	rem = load("res://Game Elements/Remnants/forcefield.tres")
	rem.rank = 4
	player_1_remnants.append(rem.duplicate(true))
	player_2_remnants.append(rem.duplicate(true))
	#rem = load("res://Game Elements/Remnants/hunter.tres")
	#rem.rank = 4
	#player_1_remnants.append(rem.duplicate(true))
	#player_2_remnants.append(rem.duplicate(true))
	rem = load("res://Game Elements/Remnants/investment.tres")
	rem.rank = 4
	player_1_remnants.append(rem.duplicate(true))
	player_2_remnants.append(rem.duplicate(true))
	rem = load("res://Game Elements/Remnants/kinetic_battery.tres")
	rem.rank = 4
	player_1_remnants.append(rem.duplicate(true))
	player_2_remnants.append(rem.duplicate(true))
	rem = load("res://Game Elements/Remnants/shido.tres")
	rem.rank = 4
	player_1_remnants.append(rem.duplicate(true))
	player_2_remnants.append(rem.duplicate(true))
	#rem = load("res://Game Elements/Remnants/winters_embrace.tres")
	#rem.rank = 4
	#player_1_remnants.append(rem.duplicate(true))
	#player_2_remnants.append(rem.duplicate(true))
	
	
	player1.display_combo()
	
	hud.set_remnant_icons(player_1_remnants,player_2_remnants)
	timefabric_collected = 100000
	####
	game_root.add_child(pathfinding)
	preload_rooms()
	randomize()
	room_instance_data = testing_room
	room_location = load(room_instance_data.scene_location)
	room_instance = room_location.instantiate()
	room_instance.y_sort_enabled = true
	game_root.add_child(room_instance)
	apply_shared_noise_offset(room_instance)
	choose_pathways(Globals.Direction.Up,room_instance, room_instance_data, conflict_cells)
	player1.global_position =  generated_room_entrance[room_instance.name]
	if(is_multiplayer):
		player2.global_position =  generated_room_entrance[room_instance.name] + Vector2(16,0)
		player1.global_position -= Vector2(16,0)
		player2.is_purple = false
	place_liquids(room_instance, room_instance_data,conflict_cells)
	place_traps(room_instance, room_instance_data,conflict_cells)
	global_conflict_cells = conflict_cells
	_placable_locations()
	if Globals.is_multiplayer:
		Spawner.spawn_enemies([player1,player2], room_instance, placable_cells.duplicate(),room_instance_data,self,false)
	else:
		Spawner.spawn_enemies([player1], room_instance, placable_cells.duplicate(),room_instance_data,self,false)
	
	var enemies : Array[Node]= []
	for child in room_instance.get_children():
		if child.is_in_group("enemy"):
			enemies.append(child)
	awareness_display.enemies = enemies.duplicate()
	floor_noise_sync(room_instance, room_instance_data)
	calculate_cell_arrays(room_instance, room_instance_data)
	trap_cells = room_instance.trap_cells
	blocked_cells = room_instance.blocked_cells
	liquid_cells = room_instance.liquid_cells
	create_new_rooms()
	pathfinding.setup_from_room(room_instance.get_node("Ground"), room_instance.blocked_cells, room_instance.trap_cells)
	_prepare_timefabric()

func _process(delta: float) -> void:
	
	time_passed += delta
	if !camera_override:
		if is_multiplayer:
			camera.global_position = (player1.global_position + player2.global_position) / 2 +camera.get_cam_offset(delta)
		else:
			camera.position = player1.global_position+camera.get_cam_offset(delta)
	
	# Thread check
	if thread_running and not room_gen_thread.is_alive():
		thread_result = room_gen_thread.wait_to_finish()
		room_gen_thread = null
		thread_running = false
		_on_thread_finished(thread_result)

	# Process pending room creation gradually
	if !(pending_room_creations.size() == 0):
		_create_room_step()
		
	# Process queued terrain updates (spread across frames)
	if terrain_update_queue.size() > 0:
		_process_terrain_batch()
				
	hud.set_timefabric_amount(timefabric_collected)
	hud.set_cooldowns()
	if Input.is_action_just_pressed("pause") and !camera_override and hud.get_node("../PauseMenu").pause_cooldown == 0:
		if pause.active:
			pause._on_return_pressed()
		else:
			pause.activate()
	
	if timefabric_rewarded!= 0:
		for i in range (20):
			timefabric_rewarded -=1
			_place_timefabric((randi() %timefabric_sizes.size()),
			Vector2(-8,-8)+Vector2(randf_range(-6,6),randf_range(-6,6)), 
			Vector2(room_instance.get_node("TimeFabricOrb").position), 
			Vector2(0,-1))
			if timefabric_rewarded== 0:
				room_instance.get_node("TimeFabricOrb").queue_free()
	if !room_cleared:
		for child in room_instance.get_children():
			if child.is_in_group("enemy"):
				if child.position.distance_to(player1.position) > 5000: #Haphazard fix for the disappearing enemy
					push_error("REMOVED ENEMY DUE TO BUG")
					child.queue_free()
				return
		if is_wave_room and total_waves > current_wave:
			current_wave+=1
			hud.display_notification("Wave "+str(current_wave)+" / "+str(total_waves))
			if Globals.is_multiplayer:
				Spawner.spawn_enemies([player1,player2], room_instance, placable_cells.duplicate(),room_instance_data,self,true)
			else:
				Spawner.spawn_enemies([player1], room_instance, placable_cells.duplicate(),room_instance_data,self,true)
			
			var enemies : Array[Node]= []
			for child in room_instance.get_children():
				if child.is_in_group("enemy"):
					enemies.append(child)
			awareness_display.enemies = enemies.duplicate()
			return
		if room_instance_data.roomtype == Globals.RoomType.Combat:
			layer_ai[4] += time_passed - layer_ai[3] #Add to combat time
			room_reward(this_room_reward1)
			if is_wave_room:
				room_reward(this_room_reward2)
		room_cleared= true
	else:
		if !reward_claimed:
			for node in room_instance.get_children():
				if node.is_in_group("reward"):
					return
			if this_room_reward1 == Globals.Reward.Boss:
				return
			if this_room_reward1 == Globals.Reward.Shop:
				for i in 4:
					await get_tree().process_frame
			if !reward_claimed:
				_enable_pathways()
				reward_claimed=true

func create_new_rooms() -> void:
	if thread_running:
		return
	# Free previous background rooms
	for gen_room in generated_rooms.values():
		if is_instance_valid(gen_room):
			gen_room.queue_free()
	generated_rooms.clear()
	generated_room_metadata.clear()
	generated_room_conflict.clear()

	# Start async generation thread
	thread_running = true
	room_gen_thread = Thread.new()
	room_gen_thread.start(_thread_generate_rooms.bind(bosses, room_instance_data)) #TODO change this to be based on layer ish

func update_ai_array(generated_room : Node2D, generated_room_data : Room) -> void:
	#Rooms cleared
	layer_ai[0] += 1
	#Combat rooms cleared
	if generated_room_data.roomtype == Globals.RoomType.Combat:
		layer_ai[1] += 1
	#Last room time
	layer_ai[2] = time_passed - layer_ai[3]
	#Total time
	layer_ai[3] = time_passed
	if generated_room_data.roomtype == Globals.RoomType.Shop:
		layer_ai[8] += 1
	if generated_room_data.num_liquid > 0:
		var liquid_num = 0
		var liquid_type : String
		while liquid_num < generated_room_data.num_liquid:
			liquid_num+=1
			liquid_type= _get_liquid_string(generated_room_data.liquid_types[liquid_num-1])
			if if_node_exists(liquid_type+str(liquid_num),generated_room):
				layer_ai[9] += 1   #Liquid room
				break
	if generated_room_data.num_trap > 0:
		var trap_num = 0
		while trap_num < generated_room_data.num_trap:
			trap_num+=1
			if if_node_exists("Trap"+str(trap_num),generated_room):
				layer_ai[10] += 1   #Trap room
				break
	if generated_room_data==testing_room:
		layer_ai = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
		time_passed = 0.0
	print(layer_ai)

func check_pathways(generated_room : Node2D, generated_room_data : Room, player_reference : Node, is_special_action : bool = false) -> int:
	var pathway_name= ""
	var direction_count = [0,0,0,0]
	for p_direct in generated_room_data.pathway_direction:
		direction_count[p_direct]+=1
		pathway_name = _get_pathway_name(p_direct,direction_count[p_direct])
		if not if_node_exists(pathway_name,generated_room):
			var pathway_detect = generated_room.get_node_or_null(pathway_name+"_Detect")
			if pathway_detect and !pathway_detect.used:
				for body in pathway_detect.get_node("Area2D").get_overlapping_bodies():
					if body==player_reference:
						if is_special_action:
							if pathway_detect.reward1_type == Globals.Reward.Shop:
								return 0
							_randomize_room_reward(pathway_detect)
							return -1
						is_wave_room  = pathway_detect.is_wave
						this_room_reward1 = pathway_detect.reward1_type
						this_room_reward2 = pathway_detect.reward2_type
						_move_to_pathway_room(pathway_name+"_Detect")
						if is_wave_room:
							total_waves = 2 #TODO make dynamic
							current_wave = 1
							hud.display_notification("Wave "+str(current_wave)+" / "+str(total_waves))
						print(is_special_action)
						return p_direct
	return -1

func choose_room() -> void:
	#Shuffle rooms and load one
	room_instance_data = sci_fi_layer[randi() % sci_fi_layer.size()]
	
	room_location = load(room_instance_data.scene_location)
	room_instance = room_location.instantiate()
	game_root.add_child(room_instance)

func choose_pathways(direction : int, generated_room : Node2D, generated_room_data : Room, conflict_cells : Array[Vector2i]) -> void:
	# Place required pathway(where the player(s) is entering		
	var direction_count = [0,0,0,0]
	for p_direct in generated_room_data.pathway_direction:
		direction_count[p_direct]+=1
	var pathway_name
	#Invert player direction so they come out the opposite side of a pathway
	direction = generated_room_data.invert_direction(direction)
	
	pathway_name = _get_pathway_name(direction,int(randf()*direction_count[direction])+1)
	_open_pathway(pathway_name, generated_room)
	#Save the new player spawn to an array
	generated_room_entrance[generated_room.name] = generated_room.get_node(pathway_name+"_Detect").global_position
	generated_room.get_node(pathway_name+"_Detect").used = true
	#Open a random pathway
	var dir = generated_room_data.pathway_direction[int(randf()*generated_room_data.num_pathways)]
	var offset = 0
	#END OF REMOVE
	if dir == direction:
		if direction_count[direction] > 1:
			while true:
				pathway_name = _get_pathway_name(direction,offset+1)
				if if_node_exists(pathway_name,generated_room):
					_open_pathway(pathway_name, generated_room)
					break
				offset+=1
		else:
			if direction == 3:
				_open_random_pathway_in_direction(Globals.Direction.Up,direction_count, generated_room)
			else:
				_open_random_pathway_in_direction(direction+1,direction_count, generated_room)
	else:
		#Open at least one pathway in the given direction
		_open_random_pathway_in_direction(dir, direction_count, generated_room)
	#Choose which pathways to keep      #add intelligent pathway choosing #TODO
	_open_random_pathways(generated_room, generated_room_data, conflict_cells)

func place_liquids(generated_room : Node2D, generated_room_data : Room, conflict_cells : Array[Vector2i]) -> void:
	#For each liquid check if you should place it and then check if there's room
	var cells : Array[Vector2i]
	var liquid_type : String
	var types = [0,0,0,0,0,0,0,0,0,0]
	for liquid in generated_room_data.liquid_types:
		types[liquid] +=1
		liquid_type= _get_liquid_string(liquid)
		if randf() > get_liquid_chance(generated_room_data.liquid_chances,generated_room_data.liquid_types, liquid,types[liquid]):
			generated_room.get_node(liquid_type+str(types[liquid])).queue_free()
		else:
			cells = generated_room.get_node(liquid_type+str(types[liquid])).get_used_cells()
			if(_arrays_intersect(cells, conflict_cells)):
				generated_room.get_node(liquid_type+str(types[liquid])).queue_free()
				#DEBUG
				_debug_message("Layer collision removed")
			else:
				conflict_cells.append_array(cells)

func get_liquid_chance(all_chances : Array[float], liquids: Array[Globals.Liquid], type : Globals.Liquid, index : int):
	var idx = 0
	for i in range(all_chances.size()):
		if liquids[i]== type:
			idx+=1
		if idx==index:
			return all_chances[i]
	return 0.0


func place_traps(generated_room : Node2D, generated_room_data : Room, conflict_cells : Array[Vector2i]) -> void:
	#For each trap check if you should place it and then check if there's room
	var trap_num = 0
	var cells : Array[Vector2i]
	while trap_num < generated_room_data.num_trap:
		trap_num+=1
		if randf() > generated_room_data.trap_chances[trap_num-1]:
			generated_room.get_node("Trap"+str(trap_num)).queue_free()
		else:
			cells = generated_room.get_node("Trap"+str(trap_num)).get_used_cells()
			if(_arrays_intersect(cells, conflict_cells)):
				generated_room.get_node("Trap"+str(trap_num)).queue_free()
				#DEBUG
				_debug_message("Deleted Trap")
			else:
				conflict_cells.append_array(cells)
				_debug_message("Added Trap")
				if(generated_room_data.trap_types[trap_num-1]!=Globals.Trap.Tile):
					_add_trap(generated_room, generated_room_data, trap_num)

			
func floor_noise_sync(generated_room : Node2D, generated_room_data : Room) -> void:
	#If there's no noise fillings, don't do the work
	if(generated_room_data.num_fillings==0):
		return
	var ground = generated_room.get_node("Ground")
	var noise = generated_room_data.noise
	#Initialize variables
	var thresholds = generated_room_data.fillings_terrain_threshold
	var num_fillings = generated_room_data.num_fillings
	#Create the output terrain array
	var terrains := []
	terrains.resize(num_fillings)
	for i in range(num_fillings):
		terrains[i] = []

	var cells = ground.get_used_cells()
	#Create Noise
	for cell in cells:
		var noise_val = (noise.get_noise_2d(cell.x,cell.y) + 1.0) * 0.5
		for i in range(num_fillings):
			if noise_val < thresholds[i]:
				terrains[i].append(cell)
				break
	#Connect tiles			
	for i in range(num_fillings):
		ground.set_cells_terrain_connect(terrains[i],generated_room_data.fillings_terrain_set[i],generated_room_data.fillings_terrain_id[i],true)

func floor_noise_threaded(generated_room: Node2D, generated_room_data: Room) -> void:
	if generated_room_data.num_fillings == 0:
		return

	var ground = generated_room.get_node("Ground")
	var cells = ground.get_used_cells()

	# Start thread
	var result_thread = Thread.new()
	var noise_result: Dictionary
	var thread_finished := false

	result_thread.start(
		func() -> Dictionary:
			return _compute_floor_noise_threaded(generated_room_data, cells)
	)

	# Wait for the thread to finish
	while not thread_finished:
		OS.delay_msec(1)

	noise_result = result_thread.wait_to_finish()
	result_thread = null

	# Assign terrains in batch (single TileMap API call per terrain)
	for i in range(generated_room_data.num_fillings):
		ground.set_cells_terrain_connect(
			noise_result["terrains"][i],
			generated_room_data.fillings_terrain_set[i],
			generated_room_data.fillings_terrain_id[i],
			true
	)

func calculate_cell_arrays(generated_room : Node2D, generated_room_data : Room) -> void:
	generated_room.blocked_cells += generated_room.get_node("Filling").get_used_cells()
	var types = [0,0,0,0,0,0,0,0,0,0]
	for liquid in generated_room_data.liquid_types:
		types[liquid] +=1
		if if_node_exists(_get_liquid_string(liquid)+str(types[liquid]),generated_room):
			generated_room.liquid_cells[liquid]+=(generated_room.get_node(_get_liquid_string(liquid)+str(types[liquid])).get_used_cells())
	var curr_trap = 0
	while curr_trap < generated_room_data.num_trap:
		curr_trap+=1
		if if_node_exists("Trap"+str(curr_trap),generated_room):
			generated_room.trap_cells += generated_room.get_node("Trap"+str(curr_trap)).get_used_cells()
	#Add blocked cells for an covers still existing
	var direction_count = [0,0,0,0]
	var pathway_name = ""
	for p_direct in generated_room_data.pathway_direction:
		direction_count[p_direct]+=1
		pathway_name = _get_pathway_name(p_direct,direction_count[p_direct])
		if if_node_exists(pathway_name,generated_room):
			generated_room.blocked_cells += generated_room.get_node(pathway_name).get_used_cells()
	generated_room.blocked_cells = _remove_duplicates(generated_room.blocked_cells)
	generated_room.liquid_cells[0] = _amalgamate_liquids(generated_room.liquid_cells)
func preload_rooms() -> void:
	for room_data_item in sci_fi_layer:
		if not cached_scenes.has(room_data_item.scene_location):
			var packed = ResourceLoader.load(room_data_item.scene_location, "PackedScene")
			cached_scenes[room_data_item.scene_location] = packed
	for room_data_item in bosses:
		if not cached_scenes.has(room_data_item.scene_location):
			var packed = ResourceLoader.load(room_data_item.scene_location, "PackedScene")
			cached_scenes[room_data_item.scene_location] = packed
	for room_data_item in sci_fi_layer_shops:
		if not cached_scenes.has(room_data_item.scene_location):
			var packed = ResourceLoader.load(room_data_item.scene_location, "PackedScene")
			cached_scenes[room_data_item.scene_location] = packed

func check_reward(generated_room : Node2D, _generated_room_data : Room, player_reference : Node) -> bool:
	if(if_node_exists("Shop",generated_room)):
		var vision = generated_room.get_node("Shop/VisionNPC") as Area2D
		if player_reference in vision.tracked_bodies:
			vision.activate()
			return true
	if(if_node_exists("RemnantOrb",generated_room)):
		var orb = generated_room.get_node("RemnantOrb") as Area2D
		if player_reference in orb.tracked_bodies:
			orb.queue_free()
			_open_remnant_popup()
			return true
	if(if_node_exists("TimeFabricOrb",generated_room)):
		var orb = generated_room.get_node("TimeFabricOrb") as Area2D
		if player_reference in orb.tracked_bodies:
			timefabric_rewarded = 200 #TODO change this to by dynamic(ish)
			return true
	if(if_node_exists("UpgradeOrb",generated_room)):
		var orb = generated_room.get_node("UpgradeOrb") as Area2D
		if player_reference in orb.tracked_bodies:
			orb.queue_free()
			_open_upgrade_popup()
			return true
	if(if_node_exists("HealthUpgrade",generated_room)):
		var orb = generated_room.get_node("HealthUpgrade") as Area2D
		if player_reference in orb.tracked_bodies:
			if is_multiplayer:
				player2.change_health(5,5)
			player1.change_health(5,5)
			var particle =  load("res://Game Elements/Particles/heal_particles.tscn").instantiate()
			particle.position = orb.position
			generated_room.add_child(particle)
			orb.queue_free()
			return true
	if(if_node_exists("Health",generated_room)):
		var orb = generated_room.get_node("Health") as Area2D
		if player_reference in orb.tracked_bodies:
			if is_multiplayer:
				player2.change_health(5)
			player1.change_health(5)
			var particle =  load("res://Game Elements/Particles/heal_particles.tscn").instantiate()
			particle.position = orb.position
			generated_room.add_child(particle)
			orb.queue_free()
			return true
	if(if_node_exists("NewWeapon",generated_room)):
		var orb = generated_room.get_node("NewWeapon") as Area2D
		if player_reference in orb.tracked_bodies:
			player_reference.update_weapon(orb.weapon_type)
			undiscovered_weapons.erase(possible_weapon)
			if(undiscovered_weapons.size() == 0):
				reward_num[6] = 0.0
				possible_weapon = ""
			else:
				possible_weapon = undiscovered_weapons.pick_random()
			hud.set_cooldown_icons()
			orb.queue_free()
			return true
		
	return false

func room_reward(reward_type : Globals.Reward) -> void:
	var reward_location
	var reward = null
	if is_multiplayer:
		reward_location = _find_2x2_open_area([Vector2i(floor(player1.global_position.x / 16), floor(player1.global_position.y / 16)),Vector2i(floor(player2.global_position.x / 16), floor(player2.global_position.y / 16))])
	else:
		reward_location = _find_2x2_open_area([Vector2i(floor(player1.global_position.x / 16), floor(player1.global_position.y / 16))])
	match reward_type:
		Globals.Reward.Remnant:
			reward = load("res://Game Elements/Objects/remnant_orb.tscn").instantiate()
			reward.set_meta("reward_type", "remnant")
		Globals.Reward.TimeFabric:
			reward = load("res://Game Elements/Objects/timefabric_orb.tscn").instantiate()
			reward.set_meta("reward_type", "timefabric")
		Globals.Reward.RemnantUpgrade:
			reward = load("res://Game Elements/Objects/upgrade_orb.tscn").instantiate()
			reward.set_meta("reward_type", "remnantupgrade")
		Globals.Reward.HealthUpgrade:
			reward = load("res://Game Elements/Objects/health_upgrade.tscn").instantiate()
			reward.set_meta("reward_type", "healthupgrade")
		Globals.Reward.Health:
			reward = load("res://Game Elements/Objects/health.tscn").instantiate()
			reward.set_meta("reward_type", "health")
		#Globals.Reward.NewWeapon:
		#	reward = load("res://Game Elements/Objects/new_weapon.tscn").instantiate()
		#	reward.set_meta("reward_type", "newweapon")
		#	reward.weapon_type = possible_weapon
	reward.position = reward_location
	room_instance.call_deferred("add_child",reward)
	

#Thread functions

func _thread_generate_rooms(room_data_array: Array, room_instance_data_sent: Room) -> Dictionary:
	var result := {}
	var direction_count = [0,0,0,0]
	
	for direction in room_instance_data_sent.pathway_direction:
		direction_count[direction] += 1
		var pathway_name = _get_pathway_name(direction, direction_count[direction])
		# Only precompute data. No scene calls
		var chosen_index = randi() % room_data_array.size()
		var next_room_data = room_data_array[chosen_index]
		result[pathway_name] = {
			"pathway": pathway_name,
			"direction": direction,
			"chosen_index": chosen_index,
			"scene_path": next_room_data.scene_location,
			"room_data": next_room_data
		}
	return result

func _on_thread_finished(data: Dictionary) -> void:
	for pathway_name in data.keys():
		pending_room_creations.append(data[pathway_name])

func _create_room_step() -> void:
	if pending_room_creations.is_empty():
		return
	
	var info = pending_room_creations.pop_front()
	
	var pathway_name = info["pathway"]
	var direction = info["direction"]
	var next_room_data = info["room_data"]
	var scene_path = info["scene_path"]
	
	if if_node_exists(pathway_name, room_instance):
		return
	if not room_instance.has_node(pathway_name + "_Detect"):
		return

	var pathway_detect = room_instance.get_node(pathway_name + "_Detect")
	if pathway_detect.used:
		return
	
	# use a preloaded scene
	var packed_scene: PackedScene = cached_scenes[scene_path]
	var next_room_instance = packed_scene.instantiate()
	next_room_instance.name = pathway_name
	next_room_instance.visible = false
	next_room_instance.process_mode = Node.PROCESS_MODE_DISABLED
	game_root.add_child(next_room_instance)
	
	# defer the more computationally heavy code
	call_deferred("_finalize_room_creation", next_room_instance, next_room_data, direction, pathway_detect)
	await get_tree().process_frame

func _exit_tree() -> void:
	if thread_running and room_gen_thread.is_alive():
		room_gen_thread.wait_to_finish()

func _compute_floor_noise_threaded(generated_room_data: Room, cells: Array) -> Dictionary:
	#Initialize variables
	var noise = generated_room_data.noise
	var thresholds = generated_room_data.fillings_terrain_threshold
	var num_fillings = generated_room_data.num_fillings
	
	#Create the output terrain array
	var terrains := []
	terrains.resize(num_fillings)
	for i in range(num_fillings):
		terrains[i] = []

	#Create Noise
	for cell in cells:
		var noise_val = (noise.get_noise_2d(int(cell.x),int(cell.y)) + 1.0) * 0.5
		for i in range(num_fillings):
			if noise_val < thresholds[i]:
				terrains[i].append(cell)
				break
	return {"terrains": terrains}

func _apply_floor_noise_async(next_room_instance: Node2D, next_room_data: Room, thread: Thread) -> void:
	var terrains_dict = thread.wait_to_finish()
	thread = null
	_start_apply_floor_noise_batched(next_room_instance, next_room_data, terrains_dict)

func _start_apply_floor_noise_batched(generated_room: Node2D, generated_room_data: Room, terrains_dict: Dictionary, batch_size: int = 100) -> void:
	var ground = generated_room.get_node("Ground")
	for i in range(generated_room_data.num_fillings):
		var terrain_cells = terrains_dict["terrains"][i]
		if terrain_cells.is_empty():
			continue
		# Split into segments
		for j in range(0, terrain_cells.size(), batch_size):
			var sub_array = terrain_cells.slice(j, j + batch_size)
			terrain_update_queue.append({
				"ground": ground,
				"cells": sub_array,
				"terrain_set": generated_room_data.fillings_terrain_set[i],
				"terrain_id": generated_room_data.fillings_terrain_id[i],
			})

func _process_terrain_batch() -> void:
	if terrain_update_queue.is_empty():
		return
	
	# Apply one segment per frame
	var entry = terrain_update_queue.pop_front()
	if is_instance_valid(entry["ground"]):
		entry["ground"].set_cells_terrain_connect(
			entry["cells"],
			entry["terrain_set"],
			entry["terrain_id"],
			true
		)

#Helper Functions

func open_death_menu() -> void:
	get_node("DeathMenu").activate()
	

func _randomize_room_reward(pathway_to_randomize : Node) -> void:
	var reward_type1 = null
	var reward_type2 = null
	var wave = false
	var prev_reward_type = pathway_to_randomize.reward1_type
	if prev_reward_type == Globals.Reward.Shop or prev_reward_type == Globals.Reward.Boss:
		return
	while reward_type1 == null:
		var reward_val = randi() % 6
		if reward_val!= 5 or !wave:
				match reward_val:
					0:
						reward_type1 = Globals.Reward.Remnant
						if reward_type1 == prev_reward_type:
							reward_type1 = null
					1:
						reward_type1 = Globals.Reward.TimeFabric
						if reward_type1 == prev_reward_type:
							reward_type1 = null
					2:
						if _upgradable_remnants():
							reward_type1 = Globals.Reward.RemnantUpgrade
							if reward_type1 == prev_reward_type:
								reward_type1 = null
					3:
						reward_type1 = Globals.Reward.HealthUpgrade
						if reward_type1 == prev_reward_type:
							reward_type1 = null
					4:
						reward_type1 = Globals.Reward.Health
						if reward_type1 == prev_reward_type:
							reward_type1 = null
						if is_multiplayer:
							if player1.current_health == player1.max_health and player2.current_health == player2.max_health:
								reward_type1 = null	
						elif player1.current_health == player1.max_health:
							reward_type1 = null
					5:
						wave = true
		if wave and reward_type2==null and reward_type1!=null: #Get two rewards
			reward_type2 = reward_type1
			reward_type1 = null
		if reward_type1 == reward_type2: #if a enemy wave room is being made, don't let both rewards be the same
			reward_type1 = null
	if reward_type2 == null:
		reward_type2 = Globals.Reward.Remnant
	
	#Pass the icon & type to the pathway node
	pathway_to_randomize.set_reward(reward_type1,wave,reward_type2)

func _choose_reward(pathway_name : String) -> void:
	var reward_type1 = null
	var reward_type2 = null
	var wave = false
	if generated_room_metadata[pathway_name].roomtype == Globals.RoomType.Shop:
		reward_type1 = Globals.Reward.Shop
		room_instance.get_node(pathway_name).set_reward(reward_type1,false,reward_type1)
		return
	if generated_room_metadata[pathway_name].roomtype == Globals.RoomType.Boss:
		reward_type1 = Globals.Reward.Boss
		room_instance.get_node(pathway_name).set_reward(reward_type1,false,reward_type1)
		return
	while reward_type1 == null:
		var reward_value = calculate_reward(reward_num)
		var last_reward_num = reward_num.duplicate()
		if reward_value!= 5 or !wave:
			match reward_value:
				0:
					reward_type1 = Globals.Reward.Remnant
					reward_num[reward_value] = reward_num[reward_value]/2.0

				1:
					reward_type1 = Globals.Reward.TimeFabric
					reward_num[reward_value] = reward_num[reward_value]/2.0

				2:
					if _upgradable_remnants():
						reward_type1 = Globals.Reward.RemnantUpgrade
						reward_num[reward_value] = reward_num[reward_value]/2.0
				3:
					reward_type1 = Globals.Reward.HealthUpgrade
					reward_num[reward_value] = reward_num[reward_value]/2.0
				4:
					reward_type1 = Globals.Reward.Health
					if is_multiplayer:
						if player1.current_health == player1.max_health and player2.current_health == player2.max_health:
							reward_type1 = null	
					elif player1.current_health == player1.max_health:
						reward_type1 = null
					if reward_type1!= null:
						reward_num[reward_value] = reward_num[reward_value]/2.0
				5:
					wave = true
					reward_num[reward_value] = reward_num[reward_value]/2.0
				#6:
				#	reward_type1 = Globals.Reward.NewWeapon
				#	reward_num[reward_value] = reward_num[reward_value]/2.0
		if wave and reward_type2==null and reward_type1!=null: #Get two rewards
			reward_type2 = reward_type1
			reward_type1 = null
		if reward_type1 == reward_type2: #if a enemy wave room is being made, don't let both rewards be the same
			reward_type1 = null
			reward_num = last_reward_num
	if reward_type2 == null:
		reward_type2 = Globals.Reward.Remnant
	#Pass the icon & type to the pathway node
	room_instance.get_node(pathway_name).set_reward(reward_type1,wave,reward_type2, possible_weapon)

func _enable_pathways() -> void:
	var pathway_name= ""
	var direction_count = [0,0,0,0]
	for p_direct in room_instance_data.pathway_direction:
		direction_count[p_direct]+=1
		pathway_name = _get_pathway_name(p_direct,direction_count[p_direct])
		if not if_node_exists(pathway_name,room_instance):
			var pathway_detect = room_instance.get_node_or_null(pathway_name+"_Detect/Area2D/CollisionShape2D")
			if pathway_detect and !room_instance.get_node(pathway_name+"_Detect").used:
				room_instance.get_node(pathway_name+"_Detect").enable_pathway()

func _upgradable_remnants() -> bool:
	var count = 0
	for remnant in player_1_remnants:
		if remnant.rank != 5:
			count+=1
			break
	for remnant in player_2_remnants:
		if remnant.rank != 5:
			count+=1
			break
	if count ==2:
		return true
	return false

func _setup_players() -> void:
	var player_scene = load("res://Game Elements/Characters/player_cat.tscn")
	if(is_multiplayer):
		player1 = player_scene.instantiate()
		player1.is_multiplayer = true
		player2 = player_scene.instantiate()
		player2.is_multiplayer = true
		player1.other_player = player2
		player2.other_player = player1
		player1.set_weapon(true, weapon1)
		player2.set_weapon(false, weapon2)
		game_root.add_child(player1)
		game_root.add_child(player2)
		player2.update_input_device(Globals.player2_input)
		player2.swap_color()
		player2.attack_requested.connect(_on_player_attack)
		player2.player_took_damage.connect(_on_player_take_damage)
		player2.activate.connect(_on_activate)
		player2.special.connect(_on_special)
		hud.connect_signals(player2)
	else:
		player1 = player_scene.instantiate()
		player1.is_multiplayer = false
		player1.set_weapon(true, weapon1)
		player1.set_weapon(false, weapon2)
		game_root.add_child(player1)
	player1.update_input_device(Globals.player1_input)
	player1.attack_requested.connect(_on_player_attack)
	player1.player_took_damage.connect(_on_player_take_damage)
	player1.activate.connect(_on_activate)
	player1.special.connect(_on_special)

func _enemy_to_timefabric(enemy : Node,direction : Vector2, amount_range : Vector2) -> void:
	if enemy.enemy_type=="binary_bot":
		var locations = enemy.get_node("Core")._return_glyph_locations()
		for loc in locations:
			_place_timefabric(randi()%6,Vector2i.ZERO,loc,direction)
		return
	var sprites = enemy.displays
	var total_area = 0.0
	var areas : Array
	for node in sprites:
		var sprite = enemy.get_node(node)
		if not sprite.texture:
			print("Sprite has no texture!")
		var img : Image = sprite.texture.get_image()
		if not img:
			print("Texture has no image!")
		var w = int(img.get_width() / sprite.hframes)
		var h = int(img.get_height() / sprite.vframes)
		total_area+=w*h
		areas.append(w*h)
	var i = 0
	for node in sprites:
		var sprite = enemy.get_node(node)
		_sprite_to_timefabric(sprite,direction, amount_range * (areas[i]/total_area),enemy)
		i+=1
		
func _sprite_to_timefabric(sprite : Node,direction : Vector2, amount_range : Vector2, enemy : Node) -> void:
	var amount_variance = (amount_range.y-amount_range.x) * randf() * .5
	var current_position = sprite.get_global_position() - sprite.get_rect().size /2
	var return_values : Array = _load_enemy_image(sprite)
	var pixels_to_cover : Dictionary = return_values[0]
	var enemy_width : int = return_values[1]
	var enemy_height : int = return_values[2]
	var timefabrics_to_place : Array[Array] = []
	var time_idx =0
	var offset = Vector2i(0,0)
	var num_time_fabrics = timefabric_masks.size()
	var best_score = 0.0
	var score = 0.0
	for i in range(0,100):
		best_score = 0.0
		#Place random timefabric variants and random locations.
		timefabrics_to_place.append([0,Vector2i(0,0)])
		for j in range(0,100):
			time_idx = randi() % num_time_fabrics
			offset = Vector2i(
				randi_range(1 - timefabric_sizes[time_idx][0], enemy_width - 1),
				randi_range(1 - timefabric_sizes[time_idx][1], enemy_height - 1)
			)
			score = _score_timefabric_placement(pixels_to_cover,timefabric_masks[time_idx],time_idx,offset)
			if score > best_score:
				best_score=score
				timefabrics_to_place[i]= [time_idx,offset]
			if best_score >= .95:
				break
		if best_score <= .5:
			timefabrics_to_place.pop_back()
			break
		for pixel in timefabric_masks[timefabrics_to_place[i][0]]:
			if pixels_to_cover.has(Vector2i(pixel+timefabrics_to_place[i][1])):
				pixels_to_cover[Vector2i(pixel+timefabrics_to_place[i][1])] = false
	if timefabrics_to_place.size() == 0:
		return
	while timefabrics_to_place.size() > amount_range.y-amount_variance:
		timefabrics_to_place.remove_at(randi() % timefabrics_to_place.size())
	while timefabrics_to_place.size() < amount_range.x+amount_variance:
		timefabrics_to_place.append(timefabrics_to_place[randi() % timefabrics_to_place.size()])
	for fabric in timefabrics_to_place:
		if enemy.enemy_type=="laser_e":
			_place_timefabric(fabric[0],fabric[1],current_position,(enemy.global_position-sprite.global_position).normalized())
		else:
			_place_timefabric(fabric[0],fabric[1],current_position,direction)

func _place_timefabric(time_idx : int, offset : Vector2i, current_position : Vector2, direction : Vector2) -> void:
	var timefabric_instance = timefabric.instantiate()
	room_instance.add_child(timefabric_instance)
	timefabric_instance.get_node("Sprite2D").frame = time_idx
	timefabric_instance.global_position = current_position + Vector2(offset) +Vector2(8,8)
	timefabric_instance.set_arrays(self)
	timefabric_instance.set_direction(direction)
	timefabric_instance.set_process(true)
	timefabric_instance.absorbed_by_player.connect(_on_timefabric_absorbed)
	return

func _score_timefabric_placement(pixels_to_cover : Dictionary, timefabric_pixels : Array, timefabric_idx : int,offset : Vector2i) -> float:
	var count = 0.0
	for pixel in timefabric_pixels:
		if pixels_to_cover.has(Vector2i(pixel+offset)) and pixels_to_cover[Vector2i(pixel+offset)]:
			count+=1.0
	return count / timefabric_sizes[timefabric_idx][2]

func _load_enemy_image(sprite : Node) -> Array: 
	if not sprite.texture:
		print("Sprite has no texture!")
	var img : Image = sprite.texture.get_image()
	if not img:
		print("Texture has no image!")
	var visible_pixels := {}  # Dictionary as hashmap
	var w = int(img.get_width() / sprite.hframes)
	var h = int(img.get_height() / sprite.vframes)
	#Get the coords of the current frame
	var cur_x = sprite.frame % sprite.hframes * w
	var cur_y = int (sprite.frame / sprite.hframes) * h
	for y in range(cur_y,cur_y+h):
		for x in range(cur_x,cur_x+w):
			var color = img.get_pixel(x, y)
			if color.a > 0.5:
				visible_pixels[Vector2i(x-cur_x,y-cur_y)] = true
	return [visible_pixels, w, h]

func _prepare_timefabric() -> void: 
	var sheet = preload("res://art/time_fabric.png") as Texture2D 
	var w = 16
	var h = 16
	var max_x
	var max_y
	for i in range(6): 
		var atlas = AtlasTexture.new() 
		atlas.atlas = sheet 
		atlas.region = Rect2(i * w, 0, w, h) 
		var img = atlas.get_image() 
		var mask = [] 
		max_x = 0
		max_y = 0
		timefabric_masks.append([])
		for y in range(h): 
			mask.append([]) 
			for x in range(w):
				if img.get_pixel(x,y).a > 0.5:
					max_x = max(max_x,x)
					max_y = max(max_y,y)
					timefabric_masks[i].append(Vector2i(x,y))
		timefabric_sizes.append(Vector3i(max_x,max_y,timefabric_masks[i].size()))

func _open_remnant_popup() -> void:
	if room_instance and !remnant_offer_popup:
		var offer_scene = load("res://Game Elements/ui/remnant_offer.tscn")
		remnant_offer_popup = offer_scene.instantiate()
		hud.add_child(remnant_offer_popup)
		remnant_offer_popup.remnant_chosen.connect(_on_remnant_chosen)
		remnant_offer_popup.popup_offer(player_1_remnants,player_2_remnants, [50,35,10,5,0])
		player1.get_node("Crosshair").visible = false
		if is_multiplayer:
			player2.get_node("Crosshair").visible = false

func _open_upgrade_popup() -> void:
	if room_instance and !remnant_upgrade_popup:
		var upgrade_scene = load("res://Game Elements/ui/remnant_upgrade.tscn")
		remnant_upgrade_popup = upgrade_scene.instantiate()
		hud.add_child(remnant_upgrade_popup)
		remnant_upgrade_popup.remnant_upgraded.connect(_on_remnant_upgraded)
		remnant_upgrade_popup.popup_upgrade(player_1_remnants.duplicate(),player_2_remnants.duplicate())
		
		player1.get_node("Crosshair").visible = false
		if is_multiplayer:
			player2.get_node("Crosshair").visible = false

func _find_2x2_open_area(player_positions: Array, max_distance: int = 20) -> Vector2i:
	var candidates := []
	#Combine all blocked and unsafe cells
	var unsafe_cells :Array = blocked_cells.duplicate()
	var safe_cells : Array = room_instance.get_node("Ground").get_used_cells()
	unsafe_cells.append_array(liquid_cells[0])
	unsafe_cells.append_array(trap_cells)
	var direction_count = [0,0,0,0]
	var pathway_positions = []
	var pathway_name = ""
	var temp_pos
	for p_direct in room_instance_data.pathway_direction:
		direction_count[p_direct]+=1
		pathway_name = _get_pathway_name(p_direct,direction_count[p_direct])
		if if_node_exists(pathway_name,room_instance):
			unsafe_cells += room_instance.get_node(pathway_name).get_used_cells()
		if if_node_exists(pathway_name+"_Detect",room_instance):
			temp_pos = room_instance.get_node(pathway_name+"_Detect").position
			pathway_positions.append(Vector2i(floor(temp_pos.x / 16), floor(temp_pos.y / 16)))
			
	#List all other reward locations(if in a wave room)
	var reward_positions = []
	for node in room_instance.get_children():
		if node.is_in_group("reward"):
			temp_pos = node.position
			reward_positions.append(Vector2i(floor(temp_pos.x / 16), floor(temp_pos.y / 16)))
	#Generate candidate 2x2 positions around each player
	for player_pos in player_positions:
		for dx in range(-max_distance, max_distance):
			for dy in range(-max_distance, max_distance):
				var candidate = player_pos + Vector2i(dx, dy)
				#Check the 2x2 area is free
				var all_free = true
				for x in range(-1,1):
					for y in range(-1,1):
						if unsafe_cells.has(candidate + Vector2i(x, y)) or !safe_cells.has(candidate + Vector2i(x, y)):
							all_free = false
							break
					if not all_free:
						break
				if all_free:
					for player_position in player_positions:
						if player_position.distance_to(candidate) < 3:
							all_free = false
							break
				if all_free:
					for path_position in pathway_positions:
						if path_position.distance_to(candidate) < 3:
							all_free = false
							break
				if all_free:
					for rew_position in reward_positions:
						if rew_position.distance_to(candidate) < 3:
							all_free = false
							break
				if all_free:
					candidates.append(candidate)

	if candidates.size()==0:
		return Vector2i.ZERO
	#Weighted random selection
	var weights := []
	for c in candidates:
		var min_dist = INF
		for player_pos in player_positions:
			var dist = player_pos.distance_to(c)
			if dist < min_dist:
				min_dist = dist
		#Closer = higher weight
		weights.append(1.0 / (min_dist*2 + 1))
	#_debug_tiles(candidates)


	# Pick a candidate based on weight
	var total_weight = 0.0
	for w in weights:
		total_weight += w

	var rnd = randf() * total_weight
	for i in range(candidates.size()):
		rnd -= weights[i]
		if rnd <= 0:
			return candidates[i] * 16

	return candidates[0] * 16

func _add_trap(generated_room: Node2D, generated_room_data: Room, trap_num: int) -> void:
	var cells = generated_room.get_node("Trap"+str(trap_num)).get_used_cells()
	var type = generated_room_data.trap_types[trap_num-1]
	for cell in cells:
		var place = generated_room.get_node("Trap"+str(trap_num)).get_cell_tile_data(cell).get_custom_data("place_trap")
		if !place:
			continue
		match type:
			Globals.Trap.Spike:
				var spike = load("res://Game Elements/Objects/spike_trap.tscn").instantiate()
				spike.position = generated_room.get_node("Trap"+str(trap_num)).map_to_local(cell)
				generated_room.add_child(spike)
			Globals.Trap.Fire:
				var fire = load("res://Game Elements/Objects/fire_trap.tscn").instantiate()
				fire.position = generated_room.get_node("Trap"+str(trap_num)).map_to_local(cell)
				generated_room.add_child(fire)

func return_trap_layer(tile_pos : Vector2i) -> TileMapLayer:
	for trap_num in range(1,room_instance_data.num_trap+1):
		if if_node_exists(("Trap"+str(trap_num)), room_instance):
			if tile_pos in room_instance.get_node("Trap"+str(trap_num)).get_used_cells():
				return room_instance.get_node("Trap"+str(trap_num))
	return null
	
func return_liquid_layer(tile_pos : Vector2i) -> TileMapLayer:
	var types = [0,0,0,0,0,0,0,0,0,0]
	for liquid in room_instance_data.liquid_types:
		types[liquid] +=1
		if if_node_exists(_get_liquid_string(liquid)+str(types[liquid]),room_instance):
			if tile_pos in room_instance.get_node(_get_liquid_string(liquid)+str(types[liquid])).get_used_cells():
				return room_instance.get_node(_get_liquid_string(liquid)+str(types[liquid]))
	return null

func _finalize_room_creation(next_room_instance: Node2D, next_room_data: Room, direction: int, pathway_detect: Node) -> void:
	
	var conflict_cells : Array[Vector2i] = []
	choose_pathways(direction, next_room_instance, next_room_data, conflict_cells)
	place_liquids(next_room_instance, next_room_data, conflict_cells)
	place_traps(next_room_instance, next_room_data, conflict_cells)
	
	# Async floor noise
	var ground = next_room_instance.get_node("Ground")
	var cells = ground.get_used_cells()

	var thread := Thread.new()
	thread.start(
		func() -> Dictionary:
			return _compute_floor_noise_threaded(next_room_data, cells)
	)

	# Defer the TileMap assignment to avoid blocking
	call_deferred("_apply_floor_noise_async", next_room_instance, next_room_data, thread)
	
	calculate_cell_arrays(next_room_instance, next_room_data)
	_set_tilemaplayer_collisions(next_room_instance, false)

	generated_room_metadata[pathway_detect.name] = next_room_data
	generated_rooms[pathway_detect.name] = next_room_instance
	generated_room_conflict[pathway_detect.name] = conflict_cells.duplicate()
	
	_choose_reward(pathway_detect.name)
	
func _move_to_pathway_room(pathway_id: String) -> void:
	var shido1 = 0.0
	var shido2 = 0.0
	var player1_ranked_up : Array[String] = []
	var player2_ranked_up : Array[String] = []
	for rem in player_1_remnants:
		if rem.remnant_name == "Remnant of Shido":
			shido1 = rem.variable_1_values[rem.rank-1]/100.0
			break
	for rem in player_2_remnants:
		if rem.remnant_name == "Remnant of Shido":
			shido2 = rem.variable_1_values[rem.rank-1]/100.0
			break
	if shido1!=0.0:
		for rem in player_1_remnants:
			if randf() < shido1 and rem.rank <= 4:
				rem.rank +=1
				player1_ranked_up.append(rem.remnant_name)
	if shido2!=0.0:
		for rem in player_2_remnants:
			if randf() < shido2 and rem.rank <= 4:
				rem.rank +=1
				player2_ranked_up.append(rem.remnant_name)
	hud.set_remnant_icons(player_1_remnants,player_2_remnants,player1_ranked_up,player2_ranked_up)
		
	
	
	if not generated_rooms.has(pathway_id):
		push_warning("No linked room for pathway " + pathway_id)
		return
	var next_room_data = generated_room_metadata[pathway_id]
	global_conflict_cells = generated_room_conflict[pathway_id]
	var next_room = generated_rooms[pathway_id]
	if not is_instance_valid(next_room):
		push_warning("Linked room instance invalid for " + pathway_id)
		return

	# Delete all other generated rooms
	for key in generated_rooms.keys():
		if key != pathway_id and is_instance_valid(generated_rooms[key]):
			generated_rooms[key].queue_free()
	generated_rooms.clear()
	generated_room_metadata.clear()
	generated_room_conflict.clear()
	reward_num = [1.0,1.0,1.0,1.0,1.0,1.0]
	
	# Delete the current room
	if is_instance_valid(room_instance):
		room_instance.queue_free()

	#Update algorithm statistics before data is overwriten
	update_ai_array(room_instance, room_instance_data)
	
	# Activate the chosen room
	next_room.visible = true
	next_room.process_mode = Node.PROCESS_MODE_INHERIT
	room_instance = next_room
	_placable_locations()
	apply_shared_noise_offset(room_instance)
	
	# Teleport player to the entrance of the next room
	player1.global_position =  generated_room_entrance[next_room.name]
	player1.disabled_countdown=3
	if(is_multiplayer):
		player2.global_position = generated_room_entrance[next_room.name] + Vector2(16,0)
		player2.disabled_countdown=3
		player1.global_position -= Vector2(16,0)
		
	
	room_instance.name = "Root"
	room_instance.y_sort_enabled = true
	# Enable Collisions
	_set_tilemaplayer_collisions(room_instance, true)
	

	# Assign a new generated_room_data definition for metadata
	room_instance_data = next_room_data
	
	if room_instance_data.roomtype == Globals.RoomType.Combat:
		var investment = load("res://Game Elements/Remnants/investment.tres")
		for rem in player_1_remnants:
			if rem.remnant_name == investment.remnant_name:
				timefabric_collected+= timefabric_collected * (rem.variable_1_values[rem.rank-1])/100.0

	# Update layers and other arrays
	trap_cells = room_instance.trap_cells
	blocked_cells = room_instance.blocked_cells
	liquid_cells = room_instance.liquid_cells
	
	if Globals.is_multiplayer:
		Spawner.spawn_enemies([player1,player2], room_instance, placable_cells.duplicate(),room_instance_data,self,is_wave_room)
	else:
		Spawner.spawn_enemies([player1], room_instance, placable_cells.duplicate(),room_instance_data,self,is_wave_room)
	
	pathfinding.setup_from_room(room_instance.get_node("Ground"), 
		room_instance.blocked_cells,
		room_instance.trap_cells
		)
	
	
	room_cleared= false
	reward_claimed = false
	
	var enemies : Array[Node]= []
	for child in room_instance.get_children():
		if child.is_in_group("enemy"):
			enemies.append(child)
	awareness_display.enemies = enemies.duplicate()
	
	if room_instance_data.roomtype == Globals.RoomType.Boss:
		room_instance.activate(self,camera,player1,player2)
	

func _set_tilemaplayer_collisions(generated_room: Node2D, enable: bool) -> void:
	for child in generated_room.get_children():
		if child is TileMapLayer:
			child.enabled = enable

func _get_pathway_name(direction: int, index: int) -> String:
	match direction:
		Globals.Direction.Up: 
			return "PathwayU" + str(index)
		Globals.Direction.Down: 
			return "PathwayD" + str(index)
		Globals.Direction.Left: 
			return "PathwayL" + str(index)
		Globals.Direction.Right: 
			return "PathwayR" + str(index)
	push_warning("Invalid pathway direction: " + str(direction))
	return ""

func _remove_duplicates(arr: Array) -> Array:
	var s := {}
	for element in arr:
		s[element] = true
	return s.keys()

func _amalgamate_liquids(liquids: Array) -> Array:
	var itr = -1
	var return_arr : Array = []
	for array in liquids:
		itr+=1
		if itr == 0:
			continue
		return_arr.append_array(array)
	return return_arr

func _arrays_intersect(array1 : Array[Vector2i], array2 : Array[Vector2i]) -> bool:
	var array2_dictionary = {}
	for vector in array2:
		array2_dictionary[vector] = true
	for vector in array1:
		if array2_dictionary.get(vector, false):
			return true
	return false
	
func _get_liquid_string(liquid : Globals.Liquid) -> String:
	match liquid:
		Globals.Liquid.Water:
			return "Water"
		Globals.Liquid.Lava:
			return "Lava"
		Globals.Liquid.Acid:
			return "Acid"
		Globals.Liquid.Conveyer:
			return "Conveyer"
		Globals.Liquid.Glitch:
			return "Glitch"
	return ""
	
func _open_pathway(input : String,generated_room : Node2D) -> void:
	_debug_message("Opened "+input+" In this room: "+generated_room.name)
	generated_room.get_node(input).queue_free()
	if !input.ends_with("_Detect"):
		generated_room.get_node(input+"_Detect").disable_pathway(false)
	
func if_node_exists(input : String,generated_room : Node2D) -> bool:
	if generated_room.get_node_or_null(input):
		return !generated_room.get_node(input).is_queued_for_deletion()
	else:
		return false

func _open_random_pathway_in_direction(dir : Globals.Direction, direction_count : Array,generated_room : Node2D) -> void:
	var pathway_name = _get_pathway_name(dir,int(randf()*direction_count[dir])+1)
	_open_pathway(pathway_name, generated_room)

func _open_random_pathways(generated_room : Node2D, generated_room_data : Room, conflict_cells : Array[Vector2i]) -> void:
	var direction_count = [0,0,0,0]
	var pathway_name = ""
	for p_direct in generated_room_data.pathway_direction:
		direction_count[p_direct]+=1
		pathway_name = _get_pathway_name(p_direct,direction_count[p_direct])
		if if_node_exists(pathway_name,generated_room):
			if randf() > .5:
				_open_pathway(pathway_name, generated_room)
			else:
				_open_pathway(pathway_name+"_Detect", generated_room)
				conflict_cells.append_array(generated_room.get_node(pathway_name).get_used_cells())
			
func _on_player_attack(_new_attack : PackedScene, _attack_position : Vector2, _attack_direction : Vector2, _damage_boost : float) -> void:
	layer_ai[6]+=1
	
func _on_player_take_damage(damage_amount : int,_current_health : int,_player_node : Node) -> void:
	layer_ai[11]+=damage_amount
	
func _on_enemy_take_damage(damage : int,current_health : int,enemy : Node, direction = Vector2(0,-1)) -> void:
	layer_ai[5]+=damage
	if current_health <= 0:
		for node in get_tree().get_nodes_in_group("attack"):
			if node.c_owner == enemy:
				node.queue_free()
		if(enemy.exploded != 0):
			var attack_instance = load("res://Game Elements/Attacks/explosion.tscn").instantiate()
			attack_instance.damage = enemy.exploded
			attack_instance.scale = attack_instance.scale * ((enemy.exploded) / 4)
			attack_instance.c_owner = enemy.last_hitter
			attack_instance.global_position = enemy.global_position
			room_instance.call_deferred("add_child",attack_instance)
		_enemy_to_timefabric(enemy,direction,Vector2(enemy.min_timefabric,enemy.max_timefabric))
		enemy.visible=false
		enemy.queue_free()
		layer_ai[7]+=1

func _on_remnant_chosen(remnant1 : Resource, remnant2 : Resource):
	player_1_remnants.append(remnant1.duplicate(true))
	player_2_remnants.append(remnant2.duplicate(true))
	remnant_offer_popup.queue_free()
	player1.get_node("Crosshair").visible = true
	if is_multiplayer:
		player2.get_node("Crosshair").visible = true
	hud.set_remnant_icons(player_1_remnants,player_2_remnants)
	
	player1.display_combo()
	if Globals.is_multiplayer:
		player2.display_combo()

func _on_remnant_upgraded(remnant1 : Resource, remnant2 : Resource):
	for i in range(player_1_remnants.size()):
		if player_1_remnants[i] == remnant1:
			player_1_remnants[i].rank +=1
	for i in range(player_2_remnants.size()):
		if player_2_remnants[i] == remnant2:
			player_2_remnants[i].rank +=1
	remnant_upgrade_popup.queue_free()
	player1.get_node("Crosshair").visible = true
	if is_multiplayer:
		player2.get_node("Crosshair").visible = true
	hud.set_remnant_icons(player_1_remnants,player_2_remnants)
	
	player1.display_combo()
	if Globals.is_multiplayer:
		player2.display_combo()
		

func _on_timefabric_absorbed(timefabric_node : Node):
	timefabric_collected+=1
	layer_ai[12]+=1
	timefabric_node.queue_free()
	
func _on_activate(player_node : Node):
	if room_instance and room_cleared:
		if check_reward(room_instance, room_instance_data,player_node):
			return
		if room_instance.get_node_or_null("Shop") and room_instance.get_node("Shop").check_rewards(player_node):
			return
		if reward_claimed:
			var direction = check_pathways(room_instance, room_instance_data,player_node,false)
			if direction != -1:
				create_new_rooms()
	
func _on_special(player_node : Node):
	var remnants : Array[Remnant] = []
	if player_node.is_purple:
		remnants = get_tree().get_root().get_node("LayerManager").player_1_remnants
	else:
		remnants = get_tree().get_root().get_node("LayerManager").player_2_remnants
	var trickster = load("res://Game Elements/Remnants/trickster.tres")
	for rem in remnants:
		if rem.remnant_name == trickster.remnant_name:
			if timefabric_collected >= int(rem.variable_1_values[rem.rank-1]):
				if check_pathways(room_instance, room_instance_data,player_node,true) == -1:
					timefabric_collected-=int(rem.variable_1_values[rem.rank-1])
	return -1

func _debug_message(msg : String) -> void:
	print("DEBUG: "+msg)

func _debug_tiles(array_of_tiles) -> void:
	var debug
	for tile in array_of_tiles:
		debug = load("res://Game Elements/General Game/debug_scene.tscn").instantiate()
		debug.position = tile*16
		room_instance.add_child(debug)

func calculate_reward(reward_probability : Array) -> int:
	var total = 0.0
	for val in reward_probability:
		total+= val
	var float_point = randf() * total
	var idx=0
	var running_weight = 0.0
	while idx < reward_probability.size():
		running_weight+=reward_probability[idx]
		if running_weight >= float_point:
			return idx
		idx+=1
	return 0

func apply_shared_noise_offset(root: Node):
	var shared_offset = Vector2(floor(randf() * 1000.0)*16, floor(randf() * 1000.0)*16)
	check_node(root,shared_offset)

func check_node(n: Node,shared_offset : Vector2):
	if n is TileMapLayer:
		var mat = n.material
		if mat is ShaderMaterial:
			mat.set_shader_parameter("noise_offset", shared_offset)

	for child in n.get_children():
		check_node(child,shared_offset)

func _placable_locations():
	var temp_placable_locations : Array[Vector2i]
	for cell in room_instance.get_node("Ground").get_used_cells():
		var c = Vector2i(cell.x, cell.y)
		if c not in global_conflict_cells:
			temp_placable_locations.append(c)
	placable_cells = temp_placable_locations


func _damage_indicator(damage : int, dmg_owner : Node,direction : Vector2 , attack_body: Node = null, c_owner : Node = null,override_color : Color = Color(0.267, 0.394, 0.394, 1.0)):
	var instance = load("res://Game Elements/Objects/damage_indicator.tscn").instantiate()
	room_instance.add_child(instance)
	instance.set_values(c_owner, attack_body, dmg_owner, damage, direction,64, override_color)
