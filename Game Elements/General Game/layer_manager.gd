extends Node2D
@onready var timefabric = preload("res://Game Elements/Objects/time_fabric.tscn")
@onready var health_pickup = preload("res://Game Elements/Objects/health_pickup.tscn")
@onready var reward_num : Array = [2.0,1.0,1.0,1.0,0.0,0.2]
@onready var base_reward_probabilities : Array = [2.0,1.0,1.0,1.0,0.0,0.2]
### Temp Multiplayer Fix
var player1 = null
var player2 = null
var undiscovered_weapons = []
var has_rewarded_for_boss : bool = false
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
var num_enemies_in_room : int = 0
var check_agro : bool = false


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
@onready var credits = $Credits

#Cached scenes to speed up room loading at runtime
var room_location : Resource 
var room_instance
var remnant_offer_popup
var remnant_upgrade_popup
#The total time of this run
var time_passed := 0.0
# time spent in room
var time_in_room := 0.0
var trap_cells := []
var blocked_cells := []
var liquid_cells : Array[Array]= [[],[],[],[],[],[],[],[],[],[]]
var is_multiplayer = Globals.is_multiplayer
var has_spent_timefabric : bool = false
#
@onready var PathwayViewport =  $PathwayViewport
@onready var PathwayTransition =  $game_container/game_viewport/game_root/Camera2D/PathwayTransition

var current_song_idx: int = -1

var timefabric_collected_sounds = [
	preload("res://Game Elements/sfx/enemies/time_fabric/collect1.ogg"),
	preload("res://Game Elements/sfx/enemies/time_fabric/collect2.ogg"),
	preload("res://Game Elements/sfx/enemies/time_fabric/collect3.ogg"),
	preload("res://Game Elements/sfx/enemies/time_fabric/collect4.ogg"),
	preload("res://Game Elements/sfx/enemies/time_fabric/collect5.ogg"),
]

var weapon_select_sounds = [
	preload("res://Game Elements/sfx/weapons/selection/selection1.wav"),
	preload("res://Game Elements/sfx/weapons/selection/selection2.wav"),
	preload("res://Game Elements/sfx/weapons/selection/selection3.wav"),
	preload("res://Game Elements/sfx/weapons/selection/selection4.wav"),
	preload("res://Game Elements/sfx/weapons/selection/selection5.wav"),
]

var cactus_explosion_sound = [
	preload("res://Game Elements/sfx/weapons/selection/selection1.wav"),
	preload("res://Game Elements/sfx/weapons/selection/selection2.wav"),
	preload("res://Game Elements/sfx/weapons/selection/selection3.wav"),
	preload("res://Game Elements/sfx/weapons/selection/selection4.wav"),
	preload("res://Game Elements/sfx/weapons/selection/selection5.wav")
]

func _ready() -> void:
	RemnantManager.has_gotten_remnant = false
	TutorialManager.player_req = [[0.0,0.0,0.0,0.0],[0.0,0.0,0.0,0.0]]
	$LettersPopup.modulate.a=0.0
	$game_container.material = $game_container.material.duplicate(true)
	var conflict_cells : Array[Vector2i] = []
	_setup_players()
	hud.set_players(player1,player2)
	hud.connect_signals(player1)
	hud.set_cross_position()
	#dev_remnants()
	
	
	
	####
	game_root.add_child(pathfinding)
	randomize()
	room_instance_data = RoomManager.starting_rooms[clamp(int(max(Globals.save_state.total_progress,Globals.total_progress)),0,2)]
	room_location = load(room_instance_data.scene_location)
	room_instance = room_location.instantiate()
	RoomManager.update_ai_array(room_instance, room_instance_data,self)
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
		check_agro = true
		num_enemies_in_room =Spawner.spawn_enemies([player1,player2], room_instance, placable_cells.duplicate(),room_instance_data,self,false,-1,"",true)
		Spawner.spawn_letters([player1,player2],room_instance, placable_cells.duplicate(),room_instance_data)
	else:
		check_agro = true
		num_enemies_in_room =Spawner.spawn_enemies([player1], room_instance, placable_cells.duplicate(),room_instance_data,self,false,-1,"",true)
		Spawner.spawn_letters([player1],room_instance, placable_cells.duplicate(),room_instance_data)
	
	var enemies : Array[Node]= []
	for child in room_instance.get_children():
		if child.is_in_group("enemy"):
			enemies.append(child)
	awareness_display.set_array(enemies.duplicate(),0)
	floor_noise_sync(room_instance, room_instance_data)
	calculate_cell_arrays(room_instance, room_instance_data)
	trap_cells = room_instance.trap_cells
	blocked_cells = room_instance.blocked_cells
	liquid_cells = room_instance.liquid_cells
	var ground = room_instance.get_node("Ground")
	if ground.get_node_or_null("GrassAddon"):
		camera.get_node("GrassTexture").visible = true
		ground.get_node("GrassAddon").initalize(conflict_cells.duplicate())
	else:
		camera.get_node("GrassTexture").visible = false
	create_new_rooms()
	pathfinding.setup_from_room(room_instance.get_node("Ground"), room_instance.blocked_cells, room_instance.trap_cells,room_instance.liquid_cells)
	_prepare_timefabric()
	PathwayTransition.material.set_shader_parameter("mask_texture", PathwayTransition.get_texture())
	
	music_player_a = AudioStreamPlayer.new()
	music_player_a.bus = "Music"
	add_child(music_player_a)
	music_player_b = AudioStreamPlayer.new()
	music_player_b.bus = "Music"
	add_child(music_player_b)
	active_player = music_player_a
	inactive_player = music_player_b
	
	var progress = clamp(int(Globals.total_progress), 0, 2)
	var themes = ["medieval"]
	if progress >= 1:
		themes.append("western")
		if progress >= 2:
			themes.append("scifi")
	
	MusicManager.play_random_theme(themes)
	
	room_cleared = true
	reward_claimed = true
	if Globals.has_gotten_tutorial:
		_enable_pathways()
	#move_to_limbo_phase_2()

func _load_save_time(idx: int) -> float:
	var path = Globals.save_dir + "save_%d.res" % idx
	if ResourceLoader.exists(path):
		var loaded = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if loaded is SaveState:
			return loaded.time_spent
	return 0
var current_crosshair_offset : Vector2 = Vector2.ZERO
func _process(delta: float) -> void:
	if PathwayViewport.get_children().size() > 0: 
		PathwayTransition.material.set_shader_parameter("mask_texture", PathwayTransition.get_texture())
	time_passed += delta
	time_in_room += delta
	
	if !camera_override:
		if is_multiplayer:
			camera.global_position = (player1.global_position + player2.global_position) / 2 +camera.get_cam_offset(delta)
		else:
			var average_crosshair_position = Globals.config.get_value("settings", "crosshair", true)
			if average_crosshair_position:
				if !player1.disabled and !get_tree().paused:
					var crosshair_component = player1.crosshair.global_position - player1.global_position
					current_crosshair_offset = crosshair_component
					camera.position = (current_crosshair_offset + player1.global_position * 8.0) / 8.0 + camera.get_cam_offset(delta)
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
	
	if Input.is_action_just_pressed("Feedback"):
		var total_save_time = 0
		if(!get_node("DeathMenu").active):
			total_save_time = get_node("DeathMenu").total_time
		for i in range(3):
			total_save_time += _load_save_time(i)
		var progress : String = str(max(Globals.save_state.total_progress+RoomManager.current_progress))
		var gpu_name : String = RenderingServer.get_video_adapter_name()
		var gpu_api : String = RenderingServer.get_video_adapter_api_version()
		var gpu_adapter : String = str(RenderingServer.get_video_adapter_type())
		var cpu_name : String = OS.get_processor_name()
		var cpu_cores : String = str(OS.get_processor_count())
		var ram : String = str(OS.get_memory_info()["physical"] / 1073741824.0)
		var static_mem : String = str(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
		DisplayServer.clipboard_set(str(total_save_time) + "," + progress + ","  + gpu_name + "," + gpu_api + "," + gpu_adapter + "," + cpu_name + "," + cpu_cores + "," + ram + "," + static_mem)
		OS.shell_open("https://docs.google.com/forms/d/e/1FAIpQLSdi6Cud_Lk8Z1nC_vxo8Z86O0FkFxxIehl1sPip_KGtnudooA/viewform?usp=publish-editor")
		if(!pause.active):
			pause.activate()
	if Input.is_action_just_pressed("give_remnant") and Globals.config.get_value("debug", 'enabled', false):
		_open_remnant_popup()
	
	if Input.is_action_just_pressed("pause") and !get_node("DeathMenu").active and \
			!pause.active and !camera_override and \
			!transitioning and !remnant_offer_popup and \
			!remnant_upgrade_popup and hud.get_node("../PauseMenu").pause_cooldown == 0 and \
			(room_instance_data.roomtype!= Globals.RoomType.Boss or RoomManager.current_progress <= 3.0) \
			and !get_tree().paused:
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
		var temp_num_enemies = 0
		for child in room_instance.get_children():
			if child.is_in_group("enemy"):
				if child.position.distance_to(player1.position) > 5000 or is_nan(child.position.x) or is_nan(child.position.y): #Haphazard fix for the disappearing enemy
					push_error("REMOVED ENEMY DUE TO BUG")
					child.queue_free()
				temp_num_enemies+=1
				
		if temp_num_enemies <= num_enemies_in_room *.35 and check_agro:
			agro_enemies()
		if temp_num_enemies >0:
			return
		if is_wave_room and total_waves > current_wave:
			current_wave+=1
			hud.display_notification("Wave "+str(current_wave)+" / "+str(total_waves))
			if Globals.is_multiplayer:
				check_agro = true
				num_enemies_in_room =Spawner.spawn_enemies([player1,player2], room_instance, placable_cells.duplicate(),room_instance_data,self,true,-1,"",true)
			else:
				check_agro = true
				num_enemies_in_room =Spawner.spawn_enemies([player1], room_instance, placable_cells.duplicate(),room_instance_data,self,true,-1,"",true)
			
			var enemies : Array[Node]= []
			for child in room_instance.get_children():
				if child.is_in_group("enemy"):
					enemies.append(child)
			awareness_display.set_array(enemies.duplicate(),0)
			return
		if room_instance_data.roomtype == Globals.RoomType.Combat:
			RoomManager.layer_ai[4] += time_passed - RoomManager.layer_ai[3] #Add to combat time
			room_reward(this_room_reward1)
			if is_wave_room:
				room_reward(this_room_reward2)
		room_cleared= true
		
		await get_tree().process_frame
		var rewards : Array[Node]= []
		for child in room_instance.get_children():
			if child.is_in_group("reward"):
				rewards.append(child)
		awareness_display.set_array(rewards.duplicate(),1)
	else:
		if !reward_claimed:
			for node in room_instance.get_children():
				if node.is_in_group("reward"):
					return
			if this_room_reward1 == Globals.Reward.Shop:
				for i in 4:
					await get_tree().process_frame
			if !reward_claimed and room_instance_data.roomtype!=Globals.RoomType.Boss:
				_enable_pathways()
				reward_claimed=true
				
				var pathways : Array[Node]= []
				for child in room_instance.get_children():
					if child.is_in_group("pathway") and !child.used and child.active:
						pathways.append(child)
				awareness_display.set_array(pathways.duplicate(),2)
				
func agro_enemies():
	print("GRRRRR")
	check_agro = false
	for child in room_instance.get_children():
		if child.is_in_group("enemy"):
			if child.get_node_or_null("BTPlayer"):
				var board = child.get_node("BTPlayer").blackboard
				if board.get_var("state") != "spawning" or child.enemy_type!="robot":
					print(str(child)+" I'm ANGRY!")
					var positions = board.get_var("player_positions")
					var distances_squared = []
					if positions:
						for pos in positions: 
							distances_squared.append(global_position.distance_squared_to(pos))
						var i = 0
						if distances_squared.size()>1 and distances_squared[1]<distances_squared[0]:
							i= 1
						var temp_position = player1.global_position if (!is_multiplayer or randf() > .5) else player2.global_position
						board.set_var("target_pos", temp_position)
						board.set_var("player_idx", i)
						board.set_var("state", "agro")





var music_player_a: AudioStreamPlayer
var music_player_b: AudioStreamPlayer
var active_player: AudioStreamPlayer
var inactive_player: AudioStreamPlayer

# In _ready(), replace the music player creation with:

func play_timeline_music() -> void:
	
	var themes = [
		"medieval",
		"western",
		"scifi",
		"shop_m",
		"shop_w",
		"shop_s",
	]
	
	var active_theme
	if room_instance_data.roomtype == Globals.RoomType.Shop:
		match int(RoomManager.current_progress):
			0:
				active_theme = "shop_m"
			1:
				active_theme = "shop_w"
			2: 
				active_theme = "shop_s"
			_:
				active_theme = "shop_m"
	else:
		var progress = RoomManager.current_progress
		if progress < 1.0:
			active_theme = themes[0]
		elif progress < 2.0:
			active_theme = themes[1]
		else:
			active_theme = themes[2]

	MusicManager.play_theme(active_theme)

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
	room_gen_thread.start(_thread_generate_rooms.bind(room_instance_data))

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
							if pathway_detect.reward1_type == Globals.Reward.Shop or pathway_detect.reward1_type == Globals.Reward.Boss:
								return 0
							_randomize_room_reward(pathway_detect)
							return -1
						is_wave_room  = pathway_detect.is_wave
						this_room_reward1 = pathway_detect.reward1_type
						this_room_reward2 = pathway_detect.reward2_type
						_move_to_pathway_room(pathway_name+"_Detect",is_wave_room)
						print(is_special_action)
						return p_direct
	if is_special_action:
		return 0
	return -1


func choose_pathways(direction : int, generated_room : Node2D, generated_room_data : Room, conflict_cells : Array[Vector2i]) -> void:
	# Place required pathway(where the player(s) is entering		
	var direction_count = [0,0,0,0]
	for p_direct in generated_room_data.pathway_direction:
		direction_count[p_direct]+=1
	var pathway_name
	#Invert player direction so they come out the opposite side of a pathway
	direction = Globals.invert_direction(direction)
	
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
	if generated_room_data.roomtype != Globals.RoomType.Boss:
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

func _populate_health_rewards(generated_room : Node2D,_generated_room_data : Room):
	var pathway_name= ""
	var direction_count = [0,0,0,0]
	for p_direct in _generated_room_data.pathway_direction:
		direction_count[p_direct]+=1
		pathway_name = _get_pathway_name(p_direct,direction_count[p_direct])
		if not if_node_exists(pathway_name,generated_room):
			var pathway = generated_room.get_node_or_null(pathway_name+"_Detect")
			_attempt_health_reward(pathway)

func check_reward(generated_room : Node2D, _generated_room_data : Room, player_reference : Node) -> bool:
	
	for node in generated_room.get_children():
		match node.name:
			"Shop":
				var vision = generated_room.get_node("Shop/VisionNPC") as Area2D
				if player_reference in vision.tracked_bodies:
					vision.activate()
					return true
			"Tutorial":
				var vision = node.get_node("VisionNPC") as Area2D
				if player_reference in vision.tracked_bodies:
					vision.activate()
					return true
			"RemnantOrb":
				if player_reference in node.tracked_bodies:
					if RemnantManager.will_softlock(player_1_remnants,player_2_remnants,false):
						if timefabric_rewarded <= 0: timefabric_rewarded = 200
						node.name = "TimeFabricOrb"
						return true
					node.queue_free()
					_open_remnant_popup()
					_populate_health_rewards(generated_room, _generated_room_data)
					#base_reward_probabilities[0] *= .9
					return true
			"TimeFabricOrb":
				if player_reference in node.tracked_bodies:
					if timefabric_rewarded <= 0: timefabric_rewarded = 200
					_populate_health_rewards(generated_room, _generated_room_data)
					#base_reward_probabilities[0] *= .8
					return true
			"UpgradeOrb":
				if player_reference in node.tracked_bodies:
					if RemnantManager.will_softlock(player_1_remnants,player_2_remnants,true):
						if timefabric_rewarded <= 0: timefabric_rewarded = 200
						node.name = "TimeFabricOrb"
						return true
					node.queue_free()
					_open_upgrade_popup()
					_populate_health_rewards(generated_room, _generated_room_data)
					#base_reward_probabilities[0] *= .9
					return true
			"HealthUpgrade":
				if player_reference in node.tracked_bodies:
					if is_multiplayer:
						player2.change_health(5.0,5.0)
					player1.change_health(5.0,5.0)
					var particle =  load("res://Game Elements/Particles/heal_particles.tscn").instantiate()
					particle.position = node.position
					generated_room.add_child(particle)
					node.queue_free()
					_populate_health_rewards(generated_room, _generated_room_data)
					#base_reward_probabilities[0] *= .8
					return true
			"Health":
				if player_reference in node.tracked_bodies:
					if is_multiplayer:
						player2.change_health(player2.max_health * .75)
					player1.change_health(player1.max_health * .75)
					var particle =  load("res://Game Elements/Particles/heal_particles.tscn").instantiate()
					particle.position = node.position
					generated_room.add_child(particle)
					node.queue_free()
					_populate_health_rewards(generated_room, _generated_room_data)
					return true
		if node.is_in_group("weapon_select"):
			if(node.enabled == true):
				if player_reference in node.tracked_bodies:
					player_reference.update_weapon(node.weapon_type)
					SFXManager.play(weapon_select_sounds[randi() % weapon_select_sounds.size()], -4.0,"SFX",player_reference.global_position)
					hud.set_cooldown_icons()
					return true
		if node.is_in_group("letter"):
			if player_reference in node.tracked_bodies:
				node.spawn_letter()
				if is_multiplayer:
					player2.change_health(player2.max_health / 5.0)
				player1.change_health(player1.max_health / 5.0)
				var particle =  load("res://Game Elements/Particles/heal_particles.tscn").instantiate()
				particle.position = node.position
				generated_room.add_child(particle)
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
			reward = preload("res://Game Elements/Objects/remnant_orb.tscn").instantiate()
			reward.set_meta("reward_type", "remnant")
		Globals.Reward.TimeFabric:
			reward = preload("res://Game Elements/Objects/timefabric_orb.tscn").instantiate()
			reward.set_meta("reward_type", "timefabric")
		Globals.Reward.RemnantUpgrade:
			reward = preload("res://Game Elements/Objects/upgrade_orb.tscn").instantiate()
			reward.set_meta("reward_type", "remnantupgrade")
		Globals.Reward.HealthUpgrade:
			reward = preload("res://Game Elements/Objects/health_upgrade.tscn").instantiate()
			reward.set_meta("reward_type", "healthupgrade")
		Globals.Reward.Health:
			reward = preload("res://Game Elements/Objects/health.tscn").instantiate()
			reward.set_meta("reward_type", "health")
		#Globals.Reward.NewWeapon:
		#	reward = preload("res://Game Elements/Objects/new_weapon.tscn").instantiate()
		#	reward.set_meta("reward_type", "newweapon")
		#	reward.weapon_type = possible_weapon
	reward.position = reward_location
	room_instance.call_deferred("add_child",reward)
	

#Thread functions

func _thread_generate_rooms(room_instance_data_sent: Room) -> Dictionary:
	var result := {}
	var direction_count = [0,0,0,0]
	
	for direction in room_instance_data_sent.pathway_direction:
		direction_count[direction] += 1
		var pathway_name = _get_pathway_name(direction, direction_count[direction])
		var room_data = RoomManager.get_room(room_instance_data_sent)
		result[pathway_name] = {
			"pathway": pathway_name,
			"direction": direction,
			"scene_path": room_data.scene_location,
			"room_data": room_data
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
	var packed_scene: PackedScene = RoomManager.cached_scenes[scene_path]
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

func _attempt_health_reward(pathway_to_randomize : Node) -> void:
	var reward_type1 = null
	var reward_type2 = null
	var wave = false
	var prev_reward_type = pathway_to_randomize.reward1_type
	if prev_reward_type == Globals.Reward.Shop or prev_reward_type == Globals.Reward.Boss:
		return
	if(percent_health_missing() > .5):
		if(randf() < percent_health_missing()*2.0-1.0):
			reward_type1 = Globals.Reward.Health
			reward_type2 = Globals.Reward.Health
			pathway_to_randomize.set_reward(reward_type1,wave,reward_type2)
	

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
						if !RemnantManager.will_softlock(player_1_remnants,player_2_remnants,false):
							reward_type1 = Globals.Reward.Remnant
							if reward_type1 == prev_reward_type:
								reward_type1 = null
					1:
						reward_type1 = Globals.Reward.TimeFabric
						if reward_type1 == prev_reward_type:
							reward_type1 = null
					2:
						if !RemnantManager.will_softlock(player_1_remnants,player_2_remnants,true):
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

func _choose_reward(pathway_name : String, reward_setter : int = -1) -> void:
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
	if(reward_setter < 0):
		while reward_type1 == null:
			var reward_value = calculate_reward(reward_num)
			var last_reward_num = reward_num.duplicate()
			if reward_value!= 5 or !wave:
				match reward_value:
					0:
						if !RemnantManager.will_softlock(player_1_remnants,player_2_remnants,false):
							reward_type1 = Globals.Reward.Remnant
							reward_num[reward_value] = reward_num[reward_value] * .1

					1:
						reward_type1 = Globals.Reward.TimeFabric
						reward_num[reward_value] = reward_num[reward_value] * .1

					2:
						if !RemnantManager.will_softlock(player_1_remnants,player_2_remnants,true):
							if _upgradable_remnants():
								reward_type1 = Globals.Reward.RemnantUpgrade
								reward_num[reward_value] = reward_num[reward_value] * .1
					3:
						reward_type1 = Globals.Reward.HealthUpgrade
						reward_num[reward_value] = reward_num[reward_value] * .1
					4:
						reward_type1 = Globals.Reward.Health
						if is_multiplayer:
							if player1.current_health == player1.max_health and player2.current_health == player2.max_health:
								reward_type1 = null	
						elif player1.current_health == player1.max_health:
							reward_type1 = null
						#if reward_type1!= null:
							#reward_num[reward_value] = reward_num[reward_value] * .5 #Maybe not necessary?
					5:
						wave = true
						reward_num[reward_value] = reward_num[reward_value] * .1
			if wave and reward_type2==null and reward_type1!=null: #Get two rewards
				reward_type2 = reward_type1
				reward_type1 = null
			if reward_type1 == reward_type2: #if a enemy wave room is being made, don't let both rewards be the same
				reward_type1 = null
				reward_num = last_reward_num
		if reward_type2 == null:
			reward_type2 = Globals.Reward.Remnant
	else:
		reward_type1 = reward_setter
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
		count+=1
	for remnant in player_2_remnants:
		count+=1
	if count >=6:
		return true
	return false


func update_players_input_devices():
	if(is_multiplayer):
		player2.update_input_device(Globals.player2_input)
	player1.update_input_device(Globals.player1_input)
	

func _setup_players() -> void:
	var player_scene = preload("res://Game Elements/Characters/player_cat.tscn")
	if(is_multiplayer):
		player1 = player_scene.instantiate()
		player1.is_multiplayer = true
		player2 = player_scene.instantiate()
		player2.is_multiplayer = true
		player1.other_player = player2
		player2.other_player = player1
		player1.set_weapon(true, Globals.weapon1)
		player2.set_weapon(false, Globals.weapon2)
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
		player1.set_weapon(true, Globals.weapon1)
		player1.set_weapon(false, Globals.weapon2)
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
			if(randf() < amount_range[1] / len(locations)):
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
	if timefabrics_to_place.size() == 0:
		return
	while timefabrics_to_place.size() < amount_range.x+amount_variance:
		timefabrics_to_place.append(timefabrics_to_place[randi() % timefabrics_to_place.size()])
	for fabric in timefabrics_to_place:
		if enemy.enemy_type=="laser_e":
			_place_timefabric(fabric[0],fabric[1],current_position,(enemy.global_position-sprite.global_position).normalized())
		else:
			_place_timefabric(fabric[0],fabric[1],current_position,direction)

func _place_health_up(offset : Vector2i, current_position : Vector2, direction : Vector2) -> void:
	var health_instance = health_pickup.instantiate()
	room_instance.add_child(health_instance)
	health_instance.global_position = current_position + Vector2(offset) +Vector2(8,8)
	health_instance.set_arrays(self)
	health_instance.set_direction(direction)
	health_instance.set_process(true)
	health_instance.absorbed_by_player.connect(_on_healthpickup_absorbed)
	return

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
		
		SFXManager.play(preload("res://Game Elements/sfx/world/display_remnants.ogg"))
		
		var offer_scene = preload("res://Game Elements/ui/remnant_offer.tscn")
		remnant_offer_popup = offer_scene.instantiate()
		hud.add_child(remnant_offer_popup)
		remnant_offer_popup.remnant_chosen.connect(_on_remnant_chosen)
		remnant_offer_popup.popup_offer(player_1_remnants,player_2_remnants)
		player1.get_node("Crosshair").visible = false
		if is_multiplayer:
			player2.get_node("Crosshair").visible = false

func _open_upgrade_popup() -> void:
	if room_instance and !remnant_upgrade_popup:
		var upgrade_scene = preload("res://Game Elements/ui/remnant_upgrade.tscn")
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
				var spike = preload("res://Game Elements/Objects/spike_trap.tscn").instantiate()
				spike.position = generated_room.get_node("Trap"+str(trap_num)).map_to_local(cell)
				generated_room.add_child(spike)
			Globals.Trap.Fire:
				var fire = preload("res://Game Elements/Objects/fire_trap.tscn").instantiate()
				fire.position = generated_room.get_node("Trap"+str(trap_num)).map_to_local(cell)
				generated_room.add_child(fire)
			Globals.Trap.Snare:
				var snare = preload("res://Game Elements/Objects/snare_trap.tscn").instantiate()
				snare.position = generated_room.get_node("Trap"+str(trap_num)).map_to_local(cell)
				generated_room.add_child(snare)
			Globals.Trap.CryptSpike:
				var cryptspike = load("res://Game Elements/Objects/spike_trap_crypt.tscn").instantiate()
				cryptspike.position = generated_room.get_node("Trap"+str(trap_num)).map_to_local(cell)
				generated_room.add_child(cryptspike)

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
	if(room_instance_data.roomtype == Globals.RoomType.Misc):
		_choose_reward(pathway_detect.name,1)
	else:
		_choose_reward(pathway_detect.name)


var transitioning : bool = false
func _move_to_pathway_room(pathway_id: String, is_wave_room_p : bool) -> void:
	hud.get_node("Tutorial_Display").visible = false
	if Globals.weapon1!="res://Game Elements/Weapons/Fist.tres" or Globals.weapon2!="res://Game Elements/Weapons/Fist.tres":
		Globals.has_equiped_weapon = true
	time_in_room = 0
	var shido1 = 0.0
	var shido2 = 0.0
	var player1_ranked_up : Array[String] = []
	var player2_ranked_up : Array[String] = []
	if generated_room_metadata[pathway_id].roomtype != Globals.RoomType.Boss:
		if transitioning:
			return
		#Transition
		var pathway =  room_instance.get_node(pathway_id)
		pathway.get_node("Prompt1").visible = false
		pathway.get_node("Prompt2").visible = false
		pathway.get_node("Icons").visible = false
		player1.disabled = true
		if is_multiplayer:
			player2.disabled = true
		
		SFXManager.play(preload("res://Game Elements/sfx/world/room_transition2.ogg"), 5.0)
		MusicManager.quite_music(3.4)
		var particles = load("res://Game Elements/Particles/pathway_particles.tscn").instantiate()
		PathwayTransition.global_position = pathway.global_position
		PathwayViewport.add_child(particles)
		var gray_value = true if RoomManager.current_progress >=2.1 and room_instance_data.roomtype == Globals.RoomType.Boss or (RoomManager.current_progress >=3.0) else false
		particles.get_child(0).material.set_shader_parameter("grayscale",gray_value)
		particles.position = Vector2(1024,1024)
		transitioning = true
		await get_tree().create_timer(2,false).timeout
		player1.disabled = false
		if is_multiplayer:
			player2.disabled = false

		transitioning = false
		if is_wave_room_p:
			total_waves = 2 #TODO make dynamic
			current_wave = 1
			delay_wave_notification("Wave "+str(current_wave)+" / "+str(total_waves),4.0)
	
	var shido = preload("res://Game Elements/Remnants/shido.tres")
	var mancermancer = preload("res://Game Elements/Remnants/mancermancer.tres")
	var giant = preload("res://Game Elements/Remnants/giant.tres")
	for rem in player_1_remnants:
		if rem.remnant_name == shido.remnant_name and rem.active:
			shido1 = rem.variable_1_values[rem.rank-1]/100.0
			break
	for rem in player_2_remnants:
		if rem.remnant_name == shido.remnant_name and rem.active:
			shido2 = rem.variable_1_values[rem.rank-1]/100.0
			break
	if shido1!=0.0:
		for rem in player_1_remnants:
			if randf() < shido1 and rem.rank <= 4:
				rem.rank +=1
				if(rem.remnant_name == mancermancer.remnant_name) and rem.active:
					player1.mancermancer_values[0] = rem.rank
				if(rem.remnant_name == giant.remnant_name) and rem.active:
					if(!is_multiplayer):
						if(player1.is_purple):
							player1.change_health(5, 5)
					else:
						player1.change_health(5, 5)
					player1.weapons[1].damage = player1.weapons[1].damage + (rem.rank % 2)
				player1_ranked_up.append(rem.remnant_name)
	if shido2!=0.0:
		for rem in player_2_remnants:
			if randf() < shido2 and rem.rank <= 4:
				rem.rank +=1
				if(rem.remnant_name == mancermancer.remnant_name) and rem.active:
					if(is_multiplayer):
						player2.mancermancer_values[1] = rem.rank
					else:
						player1.mancermancer_values[1] = rem.rank
				if(rem.remnant_name == giant.remnant_name) and rem.active:
					if(is_multiplayer):
						player2.change_health(5, 5)
						player2.weapons[0].damage = player2.weapons[0].damage + (rem.rank % 2)
					else:
						if(player1.is_purple == false):
							player1.change_health(5, 5)
						player1.weapons[0].damage = player1.weapons[0].damage + (rem.rank % 2)
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
	reward_num = base_reward_probabilities.duplicate()
	
	# Delete the current room
	if is_instance_valid(room_instance):
		room_instance.queue_free()

	#Update algorithm statistics before data is overwriten
	RoomManager.update_ai_array(room_instance, room_instance_data,self)
	# Activate the chosen room
	next_room.visible = true
	next_room.process_mode = Node.PROCESS_MODE_INHERIT
	room_instance = next_room
	if RoomManager.current_progress > 3.0:
		RoomManager.make_room_limbo(room_instance,room_instance.z_index,self)
	_placable_locations()
	apply_shared_noise_offset(room_instance)
	
	# Teleport player to the entrance of the next room
	player1.global_position =  generated_room_entrance[next_room.name]
	player1.disabled_countdown=3
	player1.current_room = next_room_data.roomtype
	if(is_multiplayer):
		player2.current_room = next_room_data.roomtype
		player2.global_position = generated_room_entrance[next_room.name] + Vector2(16,0)
		player2.disabled_countdown=3
		player1.global_position -= Vector2(16,0)
		
	
	room_instance.name = "Root"
	room_instance.y_sort_enabled = true
	# Enable Collisions
	_set_tilemaplayer_collisions(room_instance, true)
	

	# Assign a new generated_room_data definition for metadata
	room_instance_data = next_room_data
	
	if room_instance_data.roomtype == Globals.RoomType.Combat or room_instance_data.roomtype == Globals.RoomType.Boss:
		var investment = preload("res://Game Elements/Remnants/investment.tres")
		for rem in player_1_remnants:
			if rem.remnant_name == investment.remnant_name and rem.active:
				timefabric_collected+= timefabric_collected * (rem.variable_1_values[rem.rank-1])/100.0
		for rem in player_2_remnants:
			if rem.remnant_name == investment.remnant_name and rem.active:
				timefabric_collected+= timefabric_collected * (rem.variable_1_values[rem.rank-1])/100.0

	# Update layers and other arrays
	trap_cells = room_instance.trap_cells
	blocked_cells = room_instance.blocked_cells
	liquid_cells = room_instance.liquid_cells
	
	if Globals.is_multiplayer:
		check_agro = true
		num_enemies_in_room =Spawner.spawn_enemies([player1,player2], room_instance, placable_cells.duplicate(),room_instance_data,self,is_wave_room,-1,"",true)
		Spawner.spawn_letters([player1,player2],room_instance, placable_cells.duplicate(),room_instance_data)
	else:
		check_agro = true
		num_enemies_in_room =Spawner.spawn_enemies([player1], room_instance, placable_cells.duplicate(),room_instance_data,self,is_wave_room,-1,"",true)
		Spawner.spawn_letters([player1],room_instance, placable_cells.duplicate(),room_instance_data)
	
	pathfinding.setup_from_room(room_instance.get_node("Ground"), 
		room_instance.blocked_cells,
		room_instance.trap_cells,
		room_instance.liquid_cells
		)
	
	
	room_cleared= false
	reward_claimed = false
	
	if RoomManager.current_progress != 0:
		play_timeline_music()
	
	var enemies : Array[Node]= []
	
	if room_instance_data.roomtype != Globals.RoomType.Boss:
		for child in room_instance.get_children():
			if child.is_in_group("enemy"):
				enemies.append(child)
				child.process_mode = Node.PROCESS_MODE_DISABLED
	awareness_display.set_array(enemies.duplicate(),0)
	
	if room_instance_data.roomtype == Globals.RoomType.Boss:
		room_instance.activate(camera,player1,player2)
	var ground = room_instance.get_node("Ground")
	if ground.get_node_or_null("GrassAddon"):
		camera.get_node("GrassTexture").texture = null
		camera.get_node("GrassTexture").visible = true
		ground.get_node("GrassAddon").initalize(global_conflict_cells.duplicate())
	else:
		camera.get_node("GrassTexture").visible = false
		camera.get_node("GrassTexture").texture = null
	
	
	create_new_rooms()
	
	
	if room_instance_data.roomtype != Globals.RoomType.Boss:
		await get_tree().create_timer(1.25,false).timeout
		for child in enemies:
			if child:
				child.process_mode = Node.PROCESS_MODE_PAUSABLE
	

func delay_wave_notification(message : String, delay : float):
		await get_tree().create_timer(delay,false).timeout
		hud.display_notification(message)
	

func _set_tilemaplayer_collisions(generated_room: Node2D, enable: bool) -> void:
	for child in generated_room.get_children():
		if child is TileMapLayer:
			child.enabled = enable
		for child2 in child.get_children():
			if child2 is TileMapLayer:
				child2.enabled = enable

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
			if randf() < .65:
				_open_pathway(pathway_name, generated_room)
			else:
				_open_pathway(pathway_name+"_Detect", generated_room)
				conflict_cells.append_array(generated_room.get_node(pathway_name).get_used_cells())
			
func _on_player_attack(_new_attack : PackedScene, _attack_position : Vector2, _attack_direction : Vector2, _damage_boost : float) -> void:
	RoomManager.layer_ai[6]+=1
	
func _on_player_take_damage(damage_amount : float,_current_health : float,_player_node : Node) -> void:
	RoomManager.layer_ai[11]+=damage_amount
	
func _on_enemy_take_damage(damage : float,current_health : float,enemy : Node, direction = Vector2(0,-1)) -> void:
	RoomManager.layer_ai[5]+=damage
	if current_health <= 0.0 and (!enemy.is_boss or enemy.boss_die):
		enemy.hitable = false
		if enemy.is_boss:
			boss_rewards()
		var has_death_attack = false
		for node in get_tree().get_nodes_in_group("attack"):
			if node.c_owner == enemy:
				if node.has_method("clear_effects"):
					node.clear_effects()
				node.queue_free()
		if(enemy.exploded != 0):
			var remnants : Array[Remnant]
			if enemy.last_hitter.is_purple:
				remnants = player_1_remnants
			else:
				remnants = player_2_remnants
			var killer = preload("res://Game Elements/Remnants/killer.tres")
			var killer_chance = 0
			for rem in remnants:
				if rem.remnant_name == killer.remnant_name and rem.active:
					killer_chance =  rem.variable_1_values[rem.rank -1 ] / 100.0
			var num_times = 2 if(randf() < killer_chance) else 1
			for i in range(num_times):
				var attack_instance = preload("res://Game Elements/Attacks/explosion.tscn").instantiate()
				attack_instance.damage = enemy.exploded
				attack_instance.scale = attack_instance.scale * ((enemy.exploded) / 4)
				attack_instance.c_owner = enemy.last_hitter
				attack_instance.global_position = enemy.global_position
				room_instance.call_deferred("add_child",attack_instance)
		if(enemy.purple_explode):
			var attack_instance = load("res://Game Elements/Attacks/enemy_explosion.tscn").instantiate()
			attack_instance.modulate = Color("bb20ff")
			attack_instance.scale = attack_instance.scale * 2
			attack_instance.damage = 5
			attack_instance.c_owner = enemy
			attack_instance.global_position = enemy.global_position
			room_instance.call_deferred("add_child",attack_instance)
			has_death_attack = true
		if(enemy.cactus_explode):
			SFXManager.play(cactus_explosion_sound[randi() % cactus_explosion_sound.size()], -6.0,"SFX",enemy.global_position)
			var attack_direction
			if(enemy.last_hitter != null):
				attack_direction = (enemy.last_hitter.global_position - enemy.global_position).normalized()
			else:
				attack_direction = Vector2.RIGHT
			for i in range(0,12):
				var attack_instance = preload("res://Game Elements/Attacks/cactus_spine.tscn").instantiate()
				attack_instance.c_owner = enemy
				attack_instance.global_position = enemy.global_position
				attack_instance.direction = attack_direction.rotated(i * 2 * PI / 12)
				room_instance.call_deferred("add_child", attack_instance)
			has_death_attack = true
		enemy.clear_effects()
		var health_chance = randf()
		var percentage_health_missing
		if(enemy.max_timefabric != 0):
			if is_multiplayer:
				percentage_health_missing = ((player1.max_health - player1.current_health) + (player2.max_health - player2.current_health)) / (player1.max_health + player2.max_health)
			else:
				percentage_health_missing = (player1.max_health - player1.current_health) / (player1.max_health)
			if(100 * health_chance <= (percentage_health_missing * 6)):
				_place_health_up(Vector2i.ZERO,enemy.global_position,direction)
		_enemy_to_timefabric(enemy,direction,Vector2(enemy.min_timefabric,enemy.max_timefabric))
		enemy.visible=false
		if(has_death_attack == true):
			enemy.hitable = false
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
			await get_tree().create_timer(2).timeout
			if enemy and is_instance_valid(enemy): enemy.queue_free()
			RoomManager.layer_ai[7]+=1
		else:
			enemy.queue_free()
			RoomManager.layer_ai[7]+=1

func _on_remnant_chosen(remnant1 : Resource, remnant2 : Resource):
	
	player_1_remnants.append(remnant1.duplicate(true))
	player_2_remnants.append(remnant2.duplicate(true))
	remnant_update(remnant1,player1,true)
	if is_multiplayer:
		remnant_update(remnant2,player2,false)
	else:
		remnant_update(remnant2,player1, false)
		
	remnant_offer_popup.queue_free()
	player1.get_node("Crosshair").visible = true
	if is_multiplayer:
		player2.get_node("Crosshair").visible = true
	hud.set_remnant_icons(player_1_remnants,player_2_remnants)


var required_mancers = [preload("res://Game Elements/Remnants/aeromancer.tres"),
						preload("res://Game Elements/Remnants/hydromancer.tres"),
						preload("res://Game Elements/Remnants/terramancer.tres"),
						preload("res://Game Elements/Remnants/pyromancer.tres"),
						preload("res://Game Elements/Remnants/winters_embrace.tres"),
						preload("res://Game Elements/Remnants/mancermancer.tres")]

func check_mancer_achievement():
	var all_remnants = player_1_remnants + player_2_remnants
	for mancer in required_mancers:
		var found = false
		for rem in all_remnants:
			if rem.remnant_name == mancer.remnant_name:
				found = true
				break
		if not found:
			return #Missing at least one
	SteamManager.unlock_achievement("MANCER_ALL")


func remnant_update(remnant : Remnant, player : Node, is_purple :bool,gained : bool = true):
	var mancermancer = preload("res://Game Elements/Remnants/mancermancer.tres")
	var giant = preload("res://Game Elements/Remnants/giant.tres")
	var lawman = preload("res://Game Elements/Remnants/lawman.tres")
	var hare = preload("res://Game Elements/Remnants/hare.tres")
	var bandit = preload("res://Game Elements/Remnants/bandit.tres")
	check_mancer_achievement()
	if gained:
		if(remnant.remnant_name == mancermancer.remnant_name) and remnant.active:
			SteamManager.unlock_achievement("MANCER")
			if is_purple:
				player.mancermancer_values[0] = remnant.rank
			else:
				player.mancermancer_values[1] = remnant.rank
		if(remnant.remnant_name == lawman.remnant_name) and remnant.active:
			var lawman_aura = preload("res://Game Elements/Remnants/lawman/lawman.tscn").instantiate()
			player.add_child(lawman_aura)
			player.lawman_aura = lawman_aura
		if(remnant.remnant_name == giant.remnant_name) and remnant.active:
			if(player.is_purple == is_purple):
				player.scale = player.scale * 1.5
				player.change_health(remnant.variable_1_values[remnant.rank - 1], remnant.variable_1_values[remnant.rank - 1],true)
			if is_purple:
				player.weapons[1].damage = player.weapons[1].damage + remnant.variable_2_values[remnant.rank - 1]
			else:
				player.weapons[0].damage = player.weapons[0].damage + remnant.variable_2_values[remnant.rank - 1]
		if(remnant.remnant_name == hare.remnant_name) and remnant.active:
			player.hare_values[is_purple as int] = 1 + remnant.variable_1_values[remnant.rank - 1] * .01
			#if(is_purple == player.is_purple):
			#	player.move_speed = player.base_move_speed * (1 + remnant.variable_1_values[remnant.rank - 1] * .01)
		if(remnant.remnant_name == bandit.remnant_name) and remnant.active:
			if is_purple:
				hud.LeftCooldownBar.set_max_cooldown(player.weapons[1].cooldown* (1.0-remnant.variable_1_values[remnant.rank-1] / 100.0))
			else:
				hud.RightCooldownBar.set_max_cooldown(player.weapons[0].cooldown* (1.0-remnant.variable_1_values[remnant.rank-1] / 100.0))
	else:
		if(remnant.remnant_name == mancermancer.remnant_name):
			if is_purple:
				player.mancermancer_values[0] = remnant.rank
			else:
				player.mancermancer_values[1] = remnant.rank
		if(remnant.remnant_name == lawman.remnant_name):
			if player.lawman_aura:
				player.lawman_aura.queue_free()
			if is_purple:
				player.mancermancer_values[0] = 0
			else:
				player.mancermancer_values[1] = 0
		if(remnant.remnant_name == giant.remnant_name):
			if(player.is_purple == is_purple):
				player.scale = player.scale / 1.5
				player.change_health(-remnant.variable_1_values[remnant.rank - 1], -remnant.variable_1_values[remnant.rank - 1],true)
			if is_purple:
				player.weapons[1].damage = player.weapons[1].damage - remnant.variable_2_values[remnant.rank - 1]
			else:
				player.weapons[0].damage = player.weapons[0].damage - remnant.variable_2_values[remnant.rank - 1]
		if(remnant.remnant_name == hare.remnant_name):
			player.hare_values[is_purple as int] = 1
			#if(is_purple == player.is_purple):
			#	player.move_speed = player.base_move_speed / (1 + remnant.variable_1_values[remnant.rank - 1] * .01)
		if(remnant.remnant_name == bandit.remnant_name):
			if is_purple:
				hud.LeftCooldownBar.set_max_cooldown(player.weapons[1].cooldown)
			else:
				hud.RightCooldownBar.set_max_cooldown(player.weapons[0].cooldown)
	player.display_combo()
	

func _on_remnant_upgraded(remnant1 : Resource, remnant2 : Resource):
	var mancermancer = preload("res://Game Elements/Remnants/mancermancer.tres")
	var hare = preload("res://Game Elements/Remnants/hare.tres")
	for i in range(player_1_remnants.size()):
		if player_1_remnants[i] == remnant1:
			player_1_remnants[i].rank += max(1, int(RoomManager.current_progress) + 2 -player_1_remnants[i].rank)
	for i in range(player_2_remnants.size()):
		if player_2_remnants[i] == remnant2:
			player_2_remnants[i].rank += max(1, int(RoomManager.current_progress) + 2 -player_2_remnants[i].rank)
	if(remnant1.remnant_name == mancermancer.remnant_name and remnant1.active):
		player1.mancermancer_values[0] = remnant1.rank
	elif(remnant2.remnant_name == mancermancer.remnant_name and remnant2.active):
		if(is_multiplayer):
			player2.mancermancer_values[1] = remnant2.rank
		else:
			player1.mancermancer_values[1] = remnant2.rank
	if(remnant1.remnant_name == hare.remnant_name and remnant1.active):
		player1.hare_values[1] = 1 + remnant1.variable_1_values[remnant1.rank - 1] * .01
		#if(player1.is_purple):
		#	player1.move_speed = player1.base_move_speed * (1 + remnant1.variable_1_values[remnant1.rank - 1] * .01)
	elif(remnant2.remnant_name == hare.remnant_name and remnant2.active):
		if(!is_multiplayer):
			player1.hare_values[0] = 1 + remnant2.variable_1_values[remnant2.rank - 1] * .01
			#if(!player1.is_purple):
			#	player1.move_speed = player1.base_move_speed * (1 + remnant1.variable_1_values[remnant1.rank - 1] * .01)
		else:
			player2.hare_values[player2.is_purple as int] = 1 + remnant2.variable_1_values[remnant2.rank - 1] * .01
			#player2.move_speed = player2.base_move_speed * (1 + remnant2.variable_1_values[remnant2.rank - 1] * .01)
	if(remnant1.remnant_name == "Remnant of The Giant" and remnant1.active):
		if(!is_multiplayer):
			if(player1.is_purple):
				player1.change_health(5, 5)
		else:
			player1.change_health(5, 5)
		player1.weapons[1].damage = player1.weapons[1].damage + (remnant1.rank % 2)
	elif(remnant2.remnant_name == "Remnant of The Giant" and remnant2.active):
		if(is_multiplayer):
			player2.change_health(5, 5)
			player2.weapons[0].damage = player2.weapons[0].damage + (remnant2.rank % 2)
		else:
			if(player1.is_purple == false):
				player1.change_health(5, 5)
			player1.weapons[0].damage = player1.weapons[0].damage + (remnant2.rank % 2)
	
	remnant_upgrade_popup.queue_free()
	player1.get_node("Crosshair").visible = true
	if is_multiplayer:
		player2.get_node("Crosshair").visible = true
	hud.set_remnant_icons(player_1_remnants,player_2_remnants)
	
	player1.display_combo()
	if Globals.is_multiplayer:
		player2.display_combo()
		

func _on_healthpickup_absorbed(player_node : Node, health_node : Node):
	var particle =  preload("res://Game Elements/Particles/heal_particles.tscn").instantiate()
	particle.global_position = player_node.global_position
	room_instance.add_child(particle)
	var healed = 2.5
	healed = max(2.5,player_node.max_health * .2)
	player_node.change_health(healed)
	health_node.queue_free()

func _on_timefabric_absorbed(timefabric_node : Node):
	timefabric_collected+=1
	SFXManager.play(timefabric_collected_sounds[randi() % timefabric_collected_sounds.size()], 0.0, "SFX", timefabric_node.global_position)
	RoomManager.layer_ai[12]+=1
	timefabric_node.queue_free()
	
func _on_activate(player_node : Node):
	if room_instance:
		if check_reward(room_instance, room_instance_data,player_node):
			return
		if room_instance_data.roomtype == Globals.RoomType.Shop and room_instance.get_node("Shop").check_rewards(player_node):
			return
		if reward_claimed and room_cleared:
			check_pathways(room_instance, room_instance_data,player_node,false)
		if !reward_claimed and room_cleared and room_instance_data.roomtype == Globals.RoomType.Boss:
			check_pathways(room_instance, room_instance_data,player_node,false)
			
	
func _on_special(player_node : Node):
	var remnants : Array[Remnant] = []
	if player_node.is_purple:
		remnants = get_tree().get_root().get_node("LayerManager").player_1_remnants
	else:
		remnants = get_tree().get_root().get_node("LayerManager").player_2_remnants
	var trickster = preload("res://Game Elements/Remnants/trickster.tres")
	for rem in remnants:
		if rem.remnant_name == trickster.remnant_name and rem.active:
			if timefabric_collected >= int(rem.variable_1_values[rem.rank-1]):
				if check_pathways(room_instance, room_instance_data,player_node,true) == -1:
					timefabric_collected-=int(rem.variable_1_values[rem.rank-1])
					has_spent_timefabric = true
	return -1

func _debug_message(msg : String) -> void:
	print("DEBUG: "+msg)

func _debug_tiles(array_of_tiles) -> void:
	var debug
	for tile in array_of_tiles:
		debug = load("res://Game Elements/General Game/debug_scene.tscn").instantiate()
		debug.position = tile*16
		room_instance.add_child(debug)

func percent_health_missing() -> float:
	var percentage_health_missing = 0.0
	if is_multiplayer:
		percentage_health_missing = ((player1.max_health - player1.current_health) + (player2.max_health - player2.current_health)) / (player1.max_health + player2.max_health)
	else:
		percentage_health_missing = (player1.max_health - player1.current_health) / (player1.max_health)
	return percentage_health_missing		
	
func calculate_reward(reward_probability : Array) -> int:
	var total = 0.0
	var idx=0
	for val in reward_probability:
		total+= val
		idx += 1
	idx = 0
	var float_point = randf() * total
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
var _placable_cell_set : Dictionary = {}

func _placable_locations():
	var temp_placable_locations : Array[Vector2i]
	for cell in room_instance.get_node("Ground").get_used_cells():
		var c = Vector2i(cell.x, cell.y)
		if c not in global_conflict_cells:
			temp_placable_locations.append(c)
	placable_cells = temp_placable_locations
	for c in placable_cells:
		_placable_cell_set[c] = true

func _damage_indicator(damage : float, dmg_owner : Node,direction : Vector2 , attack_body: Node = null, c_owner : Node = null,override_color : Color = Color(0.267, 0.394, 0.394, 1.0)):
	var instance = preload("res://Game Elements/Objects/damage_indicator.tscn").instantiate()
	room_instance.add_child(instance)
	instance.set_values(c_owner, attack_body, dmg_owner, damage, direction,64, override_color)


func dev_remnants():
	var rem
	
	rem = load("res://Game Elements/Remnants/tortoise.tres")
	rem.rank = 5
	player_1_remnants.append(rem.duplicate(true))
	remnant_update(rem,player1,true)
	
	rem = load("res://Game Elements/Remnants/terramancer.tres")
	rem.rank = 5
	player_1_remnants.append(rem.duplicate(true))
	remnant_update(rem,player1,true)
	#
	#rem = load("res://Game Elements/Remnants/demon.tres")
	#rem.rank = 5
	#player_1_remnants.append(rem.duplicate(true))
	#remnant_update(rem,player1,true)
	#
	#rem = load("res://Game Elements/Remnants/angel.tres")
	#rem.rank = 5
	#player_2_remnants.append(rem.duplicate(true))
	#remnant_update(rem,player1,true)
	#
	#rem = load("res://Game Elements/Remnants/cowboy.tres")
	#rem.rank = 5
	#player_2_remnants.append(rem.duplicate(true))
	#remnant_update(rem,player1,true)
	#
	#rem = load("res://Game Elements/Remnants/drone.tres")
	#rem.rank = 5
	#player_1_remnants.append(rem.duplicate(true))
	#remnant_update(rem, player1, true)
	
	player1.display_combo()
	if is_multiplayer:
		player2.display_combo()
	
	hud.set_remnant_icons(player_1_remnants,player_2_remnants)
	#timefabric_collected = 10000
	
var limboing : bool = false
func move_to_limbo_phase_2():
	if limboing:
		return
	limboing = true
	
	for child in room_instance.get_children():
		if child.is_in_group("enemy") and child is DynamEnemy:
			child.current_health = -1.0
			child.emit_signal("enemy_took_damage",100.0,child.current_health,child,Vector2(0,-1))
	player1.disabled = true
	if is_multiplayer:
		player2.disabled = true
	get_node("LimboTransition/LimboTransition").play()
	await get_tree().create_timer(4.0, false).timeout
	camera.zoom = Vector2(2.0,2.0)
	var next_room_data = load("res://Game Elements/Rooms/resources/limbo_boss2.tres")
	global_conflict_cells = []
	var next_room = load("res://Game Elements/Bosses/limbo/boss_room2.tscn").instantiate()
	game_root.add_child(next_room)

	var boss= next_room.boss
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	# Delete all other generated rooms
	for key in generated_rooms.keys():
		if is_instance_valid(generated_rooms[key]):
			generated_rooms[key].queue_free()
	generated_rooms.clear()
	generated_room_metadata.clear()
	generated_room_conflict.clear()
	
	# Delete the current room
	if is_instance_valid(room_instance):
		room_instance.queue_free()

	room_instance = next_room
	_placable_locations()
	apply_shared_noise_offset(room_instance)
	
	# Teleport player to the entrance of the next room
	player1.global_position =  Vector2.ZERO
	player1.disabled_countdown=3
	if(is_multiplayer):
		player2.global_position = Vector2(16,0)
		player2.disabled_countdown=3
		player1.global_position = Vector2(16,0)

	room_instance.name = "Root"
	room_instance.y_sort_enabled = true
	liquid_cells = [[],[],[],[],[],[],[],[],[],[]]
	trap_cells = []
	blocked_cells = []

	# Assign a new generated_room_data definition for metadata
	room_instance_data = next_room_data

	pathfinding.setup_from_room(room_instance.get_node("Ground"), 
		[],
		[],
		[]
		)
	room_cleared= false
	reward_claimed = false
	room_instance.activate()
	await get_tree().create_timer(4.0, false).timeout
	player1.disabled = false
	
	if is_multiplayer:
		player2.disabled = false
	
	await get_tree().create_timer(3.0, false).timeout
	boss.process_mode = Node.PROCESS_MODE_PAUSABLE

func boss_rewards():
	var rooms_taken = RoomManager.layer_ai[15]
	room_reward(Globals.Reward.Remnant)
	if rooms_taken <= 7:
		room_reward(Globals.Reward.Health)
	if rooms_taken <= 6:
		room_reward(Globals.Reward.RemnantUpgrade)
	if rooms_taken <= 5:
		room_reward(Globals.Reward.HealthUpgrade)
	if rooms_taken <= 4:
		room_reward(Globals.Reward.TimeFabric)
	await get_tree().process_frame
	var rewards : Array[Node]= []
	for child in room_instance.get_children():
		if child.is_in_group("reward"):
			rewards.append(child)
	awareness_display.set_array(rewards.duplicate(),1)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			if !get_node("DeathMenu").active and \
			!pause.active and !camera_override and \
			!transitioning and !remnant_offer_popup and \
			!remnant_upgrade_popup and hud.get_node("../PauseMenu").pause_cooldown == 0 and \
			(room_instance_data.roomtype!= Globals.RoomType.Boss or RoomManager.current_progress <= 3.0):
				pause.activate()
