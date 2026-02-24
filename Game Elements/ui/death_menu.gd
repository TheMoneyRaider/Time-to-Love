extends CanvasLayer

@export var recent_seconds := 6
@export var rewind_time := 10 #can't be smaller than recent_seconds. also the actual rewind time is generally 3 seconds or so greater.
@export var recent_fps : float = 32.0
@export var longterm_fps : float = 8.0
@export var min_shader_intensity = 0.1
@export	var max_shader_intensity = 1.25
@export	var longterm_buffer_size := 10000

var initial_replay_fps = 12

@onready var replay_texture: TextureRect = $Control/Replay
@onready var death_box: VBoxContainer = $Control/VBoxContainer

var recent_buffer := []
var longterm_buffer := []
var capture_timer: Timer
var capturing := true
var rewinding := false
var total_time = 0.0
var final_frame : Image

var frame_amount = 0

func _ready():
	hide()
	#Disable buttons at start
	for button in death_box.get_children():
		if button is Button:
			button.disabled = true
	capture_timer = Timer.new()
	capture_timer.wait_time = 1.0 / recent_fps
	capture_timer.one_shot = false
	add_child(capture_timer)
	capture_timer.timeout.connect(_capture_frame)
	capture_timer.start()

func _process(delta):
	if capturing:
		total_time+=delta

func activate():
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

func _capture_frame():
	frame_amount +=1
	if not capturing:
		return
	var viewport = get_parent().get_node("game_container/game_viewport") as SubViewport
	var img = viewport.get_texture().get_image()

	#Save final frame
	if frame_amount == 3:
		final_frame = img.duplicate(true)
	#Add to recent buffer (rotating)
	recent_buffer.append(img)
	if recent_buffer.size() > recent_seconds * recent_fps:
		var oldest = recent_buffer.pop_front()
		#Push oldest to long-term buffer
		if frame_amount % int(recent_fps/longterm_fps) == 0:
			longterm_buffer.append(oldest)
			if longterm_buffer.size() > longterm_buffer_size:
				longterm_buffer.pop_front()

func _on_quit_pressed():
	if rewinding:
		return
	get_tree().paused = false
	get_tree().quit()
func _on_menu_pressed():
	if rewinding:
		return
	get_tree().paused = false
	get_tree().call_deferred("change_scene_to_file", "res://Game Elements/ui/main_menu/main_menu.tscn")

func _on_replay_pressed():
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
	
	var now := Time.get_time_dict_from_system()
	print(now.second)
	play_replay_reverse()

func play_replay_reverse():
	#Variables
	var elapsed = 0.0
	var recent_len = recent_buffer.size()
	var longterm_len = longterm_buffer.size()
	var desc = total_time - initial_replay_fps

	#Change rewind time if total time is too low
	if total_time < 5/float(4) * rewind_time:
		rewind_time = float(4)/5 * total_time
	
	while elapsed < rewind_time:
		elapsed += get_process_delta_time()
		print("calcing frame and dur at %f out of %f" % [elapsed, rewind_time])
		var portion = elapsed / rewind_time
		var to_disp = desc * portion * portion + initial_replay_fps * portion # this gives the time stamp of the frame that needs to be displayed
		var cur_fps = 2 * desc * portion + initial_replay_fps
		print(to_disp)
		
		# to get frame from timestamp, need to check whether it's in the long term buffer or short term buffer
		if to_disp > recent_seconds:
			var time_through = to_disp - recent_seconds
			var idx = time_through * longterm_fps + 1
			idx = min(longterm_len,floori(idx))
			print("got frame %f from the longterm buffer" % idx)
			idx = longterm_len - idx
			replay_texture.texture = ImageTexture.create_from_image(longterm_buffer[idx])
			if cur_fps < longterm_fps:
				cur_fps = longterm_fps
		else:
			var idx = to_disp * recent_fps + 1
			idx = min(recent_len,floori(idx))
			idx = recent_len - idx
			if longterm_len > 8 or idx > 3:
				print("got frame %f from the recent buffer, %f" % [idx, portion])
				replay_texture.texture = ImageTexture.create_from_image(recent_buffer[idx])
			else:
				replay_texture.texture = ImageTexture.create_from_image(final_frame)
			if cur_fps < recent_fps:
				cur_fps = recent_fps
		
		replay_texture.material.set_shader_parameter("intensity", get_shader_intensity(elapsed, rewind_time, min_shader_intensity, max_shader_intensity))
		replay_texture.material.set_shader_parameter("time", elapsed)
		await get_tree().process_frame
	
	end_replay()


#this function calculates how blurry the screen is for the given frame
func get_shader_intensity(current_time: float, total_time_func: float, min_intensity: float, max_intensity: float, exponent: float = 3.0) -> float:
	var t = clamp(current_time / total_time_func, 0.0, 1.0)
	#Exponential curve: start slow, end fast
	var exp_curve = pow(t, exponent)
	# Map to shader intensity
	return lerp(min_intensity, max_intensity, exp_curve)
	
func end_replay():
	var now := Time.get_time_dict_from_system()
	print(now.second)
	capturing = false
	recent_buffer.clear()
	longterm_buffer.clear()
	frame_amount = 0

	# Create a full-screen overlay with the last frame
	var overlay = load("res://Game Elements/ui/transition_texture.tscn").instantiate()
	overlay.get_node("TextureRect").texture = ImageTexture.create_from_image(final_frame)
	overlay.get_properties(replay_texture)
	get_tree().get_root().add_child(overlay)
	get_tree().paused = false
	# Load the next scene deferred, the overlay keeps the last frame visible
	get_tree().call_deferred("change_scene_to_file", "res://Game Elements/General Game/layer_manager.tscn")
