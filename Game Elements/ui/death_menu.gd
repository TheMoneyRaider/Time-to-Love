extends CanvasLayer



@export var time_per_buffer := 10 # hard cap on time will be this * 6
@export var rewind_time := 5.0 #can't be smaller than recent_seconds. also the actual rewind time is generally 3 seconds or so greater.

@export var min_shader_intensity = 0.0
@export	var max_shader_intensity = .75

var initial_replay_fps = 12

@onready var replay_texture: TextureRect = $Control/Replay
@onready var death_box: VBoxContainer = $Control/VBoxContainer

var active = false

var buffer_fps := [32,16,8,4,2,1]
var buffers := [[],[],[],[],[],[]]
var capture_timer: Timer
var capturing := true
var getting_time := true
var rewinding := false
var total_time = 0.0
var final_frame : Image
var rewind_mode = 0
var test_buffer := []
var test_buffer_fps := 30
var test_buffer_size = 300
var test_frame_timer : float = 0.0
var test_frame_duration : float = 1.0 / (test_buffer_fps * 2)

var frame_amount = 0
var input_delay : float = 0.0
func _ready():
	hide()
	rewind_mode = Globals.config.get_value("rewind", "rewind_mode", 0)
	#Disable buttons at start
	for button in death_box.get_children():
		if button is Button:
			button.disabled = true
	if(rewind_mode != 2):
		capture_timer = Timer.new()
		if(rewind_mode == 0):
			capture_timer.wait_time = 1.0 / test_buffer_fps
		else:
			capture_timer.wait_time = 1.0 / buffer_fps[0]
		capture_timer.one_shot = false
		add_child(capture_timer)
		#capture_timer.timeout.connect(_capture_frame) TEST
		if(rewind_mode == 0):
			capture_timer.timeout.connect(_test_capture_frame)
		else:
			capture_timer.timeout.connect(_capture_frame)
		capture_timer.start()
	else:
		capturing = false

func _process(delta):
	if getting_time:
		total_time+=delta
	if input_delay > 0:
		input_delay-=delta

func state_change():
	Globals.save_state.time_spent+=total_time
	
	if buffers[0].size() > 0:
		var img = buffers[0][0]
		if img is Image and not img.is_empty():
			Globals.save_state.picture = ImageTexture.create_from_image(img)
	elif test_buffer.size() > 0:
		var img = test_buffer.back()
		if img is Image and not img.is_empty():
			Globals.save_state.picture = ImageTexture.create_from_image(img)


func activate():
	TutorialManager.deactivate()
	input_delay = .75
	active = true
	state_change()
	if(getting_time):
		getting_time = false
	if(capturing):
		capturing=false
		capture_timer.stop()
	show()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var game_root = get_parent().get_node("game_container/game_viewport/game_root")
	game_root.call_deferred("set", "process_mode", Node.PROCESS_MODE_DISABLED)
	for button in death_box.get_children():
		if button is Button:
			button.disabled = false
	if Globals.is_multiplayer or Globals.player1_input != "key":
		$Control/VBoxContainer/Rewind.grab_focus()
	for node in get_tree().get_nodes_in_group("attack"):
		node.pause_shaders()

func _capture_frame():
	frame_amount +=1
	if not capturing:
		return
	var viewport = get_parent().get_node("game_container/game_viewport") as SubViewport
	var img = viewport.get_texture().get_image()
	img.resize(viewport.size.x / 4, viewport.size.y / 4, Image.INTERPOLATE_NEAREST)
	img.convert(Image.FORMAT_RGB8)
	#img.compress(Image.CompressMode.COMPRESS_ETC2)
	#Save final frame
	if frame_amount == 3:
		final_frame = img.duplicate(true)
	#Add to recent buffer (rotating)
	buffers[0].append(img)
	for i in range(6):
		if buffers[i].size() > buffer_fps[i] * time_per_buffer:
			var oldest = buffers[i].pop_front()
			
			if i < 5 and (frame_amount % (2 << i)) == 0:
				buffers[i+1].append(oldest)

func _test_capture_frame():
	frame_amount +=1
	if not capturing:
		return
	var viewport = get_parent().get_node("game_container/game_viewport") as SubViewport
	var img = viewport.get_texture().get_image()
	img.resize(viewport.size.x / 4, viewport.size.y / 4, Image.INTERPOLATE_NEAREST)
	img.convert(Image.FORMAT_RGB8)
	#img.compress(Image.CompressMode.COMPRESS_ETC2)
	#Save final frame
	if frame_amount == 3:
		final_frame = img.duplicate(true)
	#Add to recent buffer (rotating)
	test_buffer.append(img)
	_resize_test_buffer()
	
func _resize_test_buffer():
	var n = 8
	if(test_buffer.size() >= test_buffer_size * (float(n) / (n-1))):
		var new_buffer = []
		for i in range(0, test_buffer.size() - (n-2), n):
			for j in range(0, n - 1):
				new_buffer.append(test_buffer[i+j])
			
		test_buffer = new_buffer
		#test_buffer_fps.append(test_buffer_fps.back() * 2.0)

func _on_quit_pressed():
	if input_delay > 0:
		return
	active = false
	if rewinding:
		return
	get_tree().paused = false
	Globals.save_config()
	get_tree().quit()
func _on_menu_pressed():
	if input_delay > 0:
		return
	active = false
	if rewinding:
		return
	get_tree().paused = false
	Globals.save_config()
	get_tree().call_deferred("change_scene_to_file", "res://Game Elements/ui/main_menu/main_menu.tscn")

func _on_replay_pressed():
	Globals.total_progress = max(Globals.total_progress, RoomManager.current_progress)
	if input_delay > 0:
		return
	if rewinding:
		return
	rewinding = true
	replay_texture.visible = true
	var tween = create_tween()
	tween.tween_property(get_parent().get_node("EnemyAwareness/AwarenessManager"),"modulate:a",0.0,1.0)
	tween.parallel().tween_property(get_parent().get_node("Hud/RootControl"),"modulate:a",0.0,1.0)
	tween.parallel().tween_property(death_box,"modulate:a",0.0,1.0)
	tween.parallel().tween_property(get_node("Control/DeathAnnouncement"),"modulate:a",0.0,1.0)
	await tween.finished
	if(rewind_mode == 2):
		end_replay()
		return
	SFXManager.play(preload("res://Game Elements/sfx/world/rewind.ogg"),0.0,"SFX")
	var now := Time.get_time_dict_from_system()
	#play_replay_reverse() TEST
	if(rewind_mode == 0):
		test_play_replay_reverse()
	else:
		play_replay_reverse()
func play_replay_reverse():
	var reusable_texture := ImageTexture.new()
	#Variables
	var elapsed = 0.0
	var total_time = 0.0
	for i in range(6):
		total_time += buffers[i].size() / buffer_fps[i]
	var desc = total_time - initial_replay_fps

	#Change rewind time if total time is too low
	if total_time < 5/float(4) * rewind_time:
		rewind_time = float(4)/5 * total_time
	
	while elapsed < rewind_time:
		elapsed += get_process_delta_time()
		#print("calcing frame and dur at %f out of %f" % [elapsed, rewind_time])
		var portion = elapsed / rewind_time
		var to_disp = desc * portion * portion + initial_replay_fps * portion # this gives the time stamp of the frame that needs to be displayed
		
		#print(to_disp)
		
		# to get frame from timestamp, need to check whether it's in the long term buffer or short term buffer
		var which_buffer = int(to_disp / time_per_buffer)
		var time_through = to_disp
		while time_through > time_per_buffer:
			time_through -= time_per_buffer
		if which_buffer > 5:
			which_buffer = 5
			time_through = time_per_buffer
		#print("Need to print the frame that is %f seconds through buffer %d" % [time_through, which_buffer])
		var buffer_len = buffers[which_buffer].size()
		var idx = time_through * buffer_fps[which_buffer] + 1
		idx = min(buffer_len, floori(idx))
		#print("getting the %dth frame" % [idx])
		idx = buffer_len - idx
		
		
		reusable_texture.set_image(buffers[which_buffer][idx])
		replay_texture.texture = reusable_texture
		
		replay_texture.material.set_shader_parameter("intensity", get_shader_intensity(elapsed, rewind_time, min_shader_intensity, max_shader_intensity))
		replay_texture.material.set_shader_parameter("time", elapsed)
		await get_tree().process_frame
	
	end_replay()

func test_play_replay_reverse():
	var reusable_texture := ImageTexture.new()
	#Variables
	var elapsed_frames = 0
	var total_rewind_time = 0.0
	total_rewind_time = test_buffer.size() / float(test_buffer_fps)

	#Change rewind time if total time is too low
	if total_rewind_time < rewind_time:
		rewind_time = total_rewind_time
	
	while test_buffer.size() != 0:
		await get_tree().process_frame
		test_frame_timer += get_process_delta_time()
		if(test_frame_timer >= test_frame_duration):
			test_frame_timer -= test_frame_duration
			reusable_texture.set_image(test_buffer.pop_back())
			replay_texture.texture = reusable_texture
			replay_texture.material.set_shader_parameter("intensity", get_shader_intensity(elapsed_frames / float(test_buffer_fps), rewind_time, min_shader_intensity, max_shader_intensity))
			replay_texture.material.set_shader_parameter("time", elapsed_frames / float(test_buffer_fps))
			elapsed_frames += 1
	
	end_replay()



#this function calculates how blurry the screen is for the given frame
func get_shader_intensity(current_time: float, total_time_func: float, min_intensity: float, max_intensity: float, exponent: float = 4.0) -> float:
	var t = clamp(current_time / total_time_func, 0.0, 1.0)
	#Exponential curve: start slow, end fast
	var exp_curve = pow(t, exponent)
	# Map to shader intensity
	return lerp(min_intensity, max_intensity, exp_curve)
	
func end_replay():
	var now := Time.get_time_dict_from_system()
	active = false
	capturing = false
	getting_time = false
	for i in range(6):
		buffers[i].clear()
	frame_amount = 0
	
	test_buffer.clear()
	test_frame_timer =0
	RoomManager.current_progress = 0.0
	# Create a full-screen overlay with the last frame
	if(rewind_mode != 2):
		var overlay = preload("res://Game Elements/ui/transition_texture.tscn").instantiate()
		overlay.get_node("TextureRect").texture = ImageTexture.create_from_image(final_frame)
		overlay.get_properties(replay_texture)
		final_frame = null
		get_tree().get_root().add_child(overlay)
	get_tree().paused = false
	# Load the next scene deferred, the overlay keeps the last frame visible
	get_tree().call_deferred("change_scene_to_file", "res://Game Elements/General Game/layer_manager.tscn")
