extends Control

class PlayerState:
	var hover_button: Button = null
	var pressing: bool = false
	var input: String = "-1"

class UIState:
	var player1: PlayerState
	var player2: PlayerState	
	
@onready var UI_Group = $SubViewportContainer/SubViewport/UI_Group
@onready var Title = $SubViewportContainer/SubViewport/Title
@onready var cooldown : float = 0.0
@onready var mouse_cooldown : float = 0.0
@onready var the_ui : Texture2D
@onready var disruptive1 : bool = true
@onready var disruptive2 : bool = true
@onready var exploaded: bool = false
@onready var fragmenting: bool = true
@onready var prepared = false
var capture_all_states: bool = false
@export var saved_fragments_paths: Array[String] = ["res://Game Elements/ui/main_menu/BreakFXSavedWestern.tres","res://Game Elements/ui/main_menu/BreakFXSavedSpace.tres","res://Game Elements/ui/main_menu/BreakFXSavedMedieval.tres"]
var intro_started: bool = false


var last_mouse_pos : Vector2
var ui_textures: Dictionary = {}
var last_devices : Array = []
var title_textures : Array = [preload("res://art/title_assets/title_variants/western.png"),preload("res://art/title_assets/title_variants/space.png"),preload("res://art/title_assets/title_variants/medieval.png")]
var UI: UIState = UIState.new()
@onready var prev_state = null
var paused : bool = true
var skip_next_release : bool = false
var hover_cooldown: float = 0.0


func _on_skip() -> void:
	$Intro/AnimationPlayer.stop()
	$Intro.visible = false
	$Intro/AudioStreamPlayer.stop()
	Globals.cinematic_viewed = true
	paused = false
	start_menu_music()
	


func _begin_cinematic() -> void:
	$Intro.visible = true
	$Intro/AnimationPlayer.play("RESET")
	$Intro/AnimationPlayer.advance(0)
	$Intro/AnimationPlayer.play("main")
	$Intro/Skip.skip_requested.connect(_on_skip)
	$Intro/Skip.active = true
	intro_started = true

	get_tree().create_timer(65.0).timeout.connect(func():
		if paused:
			$Intro/AnimationPlayer.stop()
			$Intro.visible = false
			$Intro/AudioStreamPlayer.stop()
			Globals.cinematic_viewed = true
			paused = false
			start_menu_music()
	)

func _ready():
	if Globals.cinematic_viewed:
		paused = false
		$Intro.visible = false
		start_menu_music()
	Title.texture = title_textures[Globals.menu]
	fragmenting = Globals.config.get_value("fragmentation", "enabled", true)
	if capture_all_states:
		fragmenting = true
	UI.player1 = PlayerState.new()
	UI.player2 = PlayerState.new()
	if !fragmenting:
		$RichTextLabel.visible = false
		UI_Group.visible = true
		Title.visible = true

		# Disable focus so Godot doesn't handle navigation
		for button in $SubViewportContainer/SubViewport/UI_Group/VBoxContainer.get_children():
			if button is Button:
				button.focus_mode = Control.FOCUS_NONE
				button.mouse_entered.connect(_on_focus_entered)  # ← mouse hover
				button.focus_entered.connect(_on_focus_entered)  # ← keyboard/controller
				button.pressed.connect(func(): sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"), 0 , "UI"))
	else:
		if !capture_all_states:
			preload_all_textures()
		randomize()
		cooldown = 10.0
		await get_tree().process_frame
		await get_tree().process_frame
		# Capture the UI once
		var vp_tex = $SubViewportContainer/SubViewport.get_texture()
		the_ui = ImageTexture.create_from_image(vp_tex.get_image())
		UI_Group.visible = true if capture_all_states else false
		Title.visible = true if capture_all_states else false
		if fragmenting:
			await explode_ui()
			cooldown = -1
		if capture_all_states:
			capture_all_ui_states()
	if !Globals.cinematic_viewed:
		_begin_cinematic()
		
			
			
	if Globals.total_progress < 1.0:
		$ColorRect.material.set_shader_parameter("tendril_count", 30)
		$ColorRect.material.set_shader_parameter("range_start", 1.5)
		$ColorRect.material.set_shader_parameter("range_end", 2.5)
	elif Globals.total_progress < 2.0:
		$ColorRect.material.set_shader_parameter("tendril_count", 20)
		$ColorRect.material.set_shader_parameter("range_start", 1.625)
		$ColorRect.material.set_shader_parameter("range_end", 2.375)
	elif Globals.total_progress < 3.0:
		$ColorRect.material.set_shader_parameter("tendril_count", 10)
		$ColorRect.material.set_shader_parameter("range_start", 1.75)
		$ColorRect.material.set_shader_parameter("range_end", 2.25)
	elif Globals.total_progress < 4.0:
		$ColorRect.material.set_shader_parameter("tendril_count", 2)
		$ColorRect.material.set_shader_parameter("range_start", 2)
		$ColorRect.material.set_shader_parameter("range_end", 2)
		
func _begin_explosion_cooldown():
	if cooldown < 0:
		cooldown = randf_range(2,4)
		exploaded = true

func start_menu_music():
	music_manager.play_theme("main")
	
func _load_save_time(idx: int) -> float:
	var path = Globals.save_dir + "save_%d.res" % idx
	if ResourceLoader.exists(path):
		var loaded = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if loaded is SaveState:
			return loaded.time_spent
	return 0


var nav_cooldown: float = 0.0
var nav_cooldown_time: float = 0.2  # seconds between navigation steps

func _process(delta):
	nav_cooldown -= delta
	hover_cooldown-=delta
	if paused:
		if !intro_started or $Intro/AnimationPlayer.is_playing():
			return
		else:
			print("_process: animation finished naturally")
			$Intro.visible = false
			$Intro/AnimationPlayer.stop()
			$Intro/AudioStreamPlayer.stop()
			Globals.cinematic_viewed = true
			paused=false
			skip_next_release = true
			start_menu_music()
	if Globals.player1_input:
		if !prepared:
			update_prompt()
			prepared=true
			UI.player1.input = Globals.player1_input
			UI.player2.input = Globals.player2_input
			if UI.player1.input != "key" and int(UI.player1.input) in Input.get_connected_joypads():
				UI.player1.hover_button = $SubViewportContainer/SubViewport/UI_Group/VBoxContainer.get_child(2)
			if UI.player2.input != "key" and int(UI.player2.input) in Input.get_connected_joypads():
				UI.player2.hover_button = $SubViewportContainer/SubViewport/UI_Group/VBoxContainer.get_child(2)
		if Input.get_connected_joypads() != last_devices:
			last_devices=Input.get_connected_joypads()
			update_prompt()
		if Input.is_action_just_pressed("swap_" + Globals.player1_input):
			disruptive1 = !disruptive1
			update_prompt()
		if Input.is_action_just_pressed("swap_" + Globals.player2_input):
			disruptive2 = !disruptive2
			update_prompt()
		if Input.is_action_just_pressed("Feedback"):
			var total_save_time = 0
			for i in range(3):
				total_save_time += _load_save_time(i)
			var progress : String = str(Globals.save_state.total_progress)
			var gpu_name : String = RenderingServer.get_video_adapter_name()
			var gpu_api : String = RenderingServer.get_video_adapter_api_version()
			var gpu_adapter : String = str(RenderingServer.get_video_adapter_type())
			var cpu_name : String = OS.get_processor_name()
			var cpu_cores : String = str(OS.get_processor_count())
			var ram : String = str(OS.get_memory_info()["physical"] / 1073741824.0)
			var static_mem : String = str(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
			DisplayServer.clipboard_set(str(total_save_time) + "," + progress + ","  + gpu_name + "," + gpu_api + "," + gpu_adapter + "," + cpu_name + "," + cpu_cores + "," + ram + "," + static_mem)
			OS.shell_open("https://docs.google.com/forms/d/e/1FAIpQLSdi6Cud_Lk8Z1nC_vxo8Z86O0FkFxxIehl1sPip_KGtnudooA/viewform?usp=publish-editor")
	if prepared:
		inputs(UI.player1.input)
		inputs(UI.player2.input)
		# For non-fragmenting, manually highlight the hovered button
		if !fragmenting:
			_update_button_visuals()
		else:
			update_ui_display()
			fragment_disruption()
	cooldown -= delta
	if mouse_cooldown ==-1:
		if UI.player1.input == "key":
			UI.player1.hover_button = null
			UI.player1.pressing = false
		if UI.player2.input == "key":
			UI.player2.hover_button = null
			UI.player2.pressing = false
	
	if cooldown < 0 and cooldown > -.9 and exploaded:
		exploaded = false
		cooldown = 1
		rewind_ui(cooldown)
		

func _update_button_visuals() -> void:
	for button in $SubViewportContainer/SubViewport/UI_Group/VBoxContainer.get_children():
		if button is Button:
			var is_p1 = button == UI.player1.hover_button
			var is_p2 = button == UI.player2.hover_button
			if (is_p1 and UI.player1.pressing) or (is_p2 and UI.player2.pressing):
				button.add_theme_stylebox_override("normal", button.get_theme_stylebox("pressed"))
			elif is_p1 or is_p2:
				button.add_theme_stylebox_override("normal", button.get_theme_stylebox("hover"))
			else:
				button.add_theme_stylebox_override("normal", button.get_theme_stylebox("disabled"))

func fragment_disruption():
	if get_viewport() and last_mouse_pos.distance_to(get_viewport().get_mouse_position()) >10:
		mouse_cooldown -= 1
		last_mouse_pos = get_viewport().get_mouse_position()
	if !fragmenting:
		return
	if disruptive1 and get_viewport():
		if UI.player1.input == "key":
			var mouse_pos = get_viewport().get_mouse_position()
			for frag in $BreakFX.get_children():
				frag.apply_force_frag(mouse_pos)
		if UI.player1.input != "key" and UI.player1.hover_button != null and int(UI.player1.input) in Input.get_connected_joypads():
			var cont_pos = UI.player1.hover_button.get_global_rect().position + UI.player1.hover_button.get_global_rect().size/2
			for frag in $BreakFX.get_children():
				frag.apply_force_frag(cont_pos)
	if disruptive2 and get_viewport():
		if UI.player2.input == "key":
			var mouse_pos = get_viewport().get_mouse_position()
			for frag in $BreakFX.get_children():
				frag.apply_force_frag(mouse_pos)
		if UI.player2.input != "key" and UI.player2.hover_button != null and int(UI.player2.input) in Input.get_connected_joypads():
			var cont_pos = UI.player2.hover_button.get_global_rect().position + UI.player2.hover_button.get_global_rect().size/2
			for frag in $BreakFX.get_children():
				frag.apply_force_frag(cont_pos)

func button_pressed(button: Button):
	if UI.player1.input == "key":
		UI.player1.hover_button = button
		UI.player1.pressing = true
	if UI.player2.input == "key":
		UI.player2.hover_button = button
		UI.player2.pressing = true

func mouse_over(button: Button):
	mouse_cooldown = 1
	if UI.player1.input == "key":
		UI.player1.hover_button = button
	if UI.player2.input == "key":
		UI.player2.hover_button = button

func _input(event):
	if !Globals.cinematic_viewed:
		return
	if !fragmenting:
		return
	if event is InputEventMouseButton:
		if not event.pressed:
			if UI.player1.input == "key":
				UI.player1.pressing = false
				if UI.player1.hover_button:
					UI.player1.hover_button.emit_signal("pressed")
					if fragmenting: sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
			if UI.player2.input == "key":
				UI.player2.pressing = false
				if UI.player2.hover_button:
					UI.player2.hover_button.emit_signal("pressed")
					if fragmenting: sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))

func get_button_polygon(button: Button, frag_start_pos: Vector2) -> Array:
	var rect = button.get_global_rect()
	return [
		rect.position - frag_start_pos,
		rect.position + Vector2(rect.size.x, 0) - frag_start_pos,
		rect.position + rect.size - frag_start_pos,
		rect.position + Vector2(0, rect.size.y) - frag_start_pos
	]

# Recursive helper to collect leaf nodes
func collect_leaf_children(node: Node, bounds: Dictionary) -> void:
	for child in node.get_children():
		if child.get_child_count() == 0:
			# Leaf node, add to dictionary
			if child is Control and child.get_class() == "Control":
				continue
			bounds[child] = child.get_global_rect()
		else:
			# Recurse into children
			collect_leaf_children(child, bounds)

func explode_ui():
	# If saved fragments exist, load them
	if ResourceLoader.exists(saved_fragments_paths[Globals.menu]):
		load_fragments(saved_fragments_paths[Globals.menu])
		update_ui_display()
		return

	# --- Otherwise, generate fragments ---
	print("start saving fragments")
	for state in [Globals.MenuState.Western,Globals.MenuState.Space,Globals.MenuState.Medieval]:
		Title.texture = title_textures[state]
		await get_tree().process_frame
		var vp_tex = $SubViewportContainer/SubViewport.get_texture()
		the_ui = ImageTexture.create_from_image(vp_tex.get_image())

		var button_bounds = {}
		for button in $SubViewportContainer/SubViewport/UI_Group/VBoxContainer.get_children():
			if button is Button:
				button_bounds[button] = button.get_global_rect()

		# Generate polygons
		var fragments_data = generate_jittered_grid_fragments(the_ui.get_size(), 40, 40)

		var fragment_resources: Array = []

		for frag_poly in fragments_data:

			var frag = preload("res://Game Elements/ui/main_menu/break_frag.tscn").instantiate()
			$BreakFX.add_child(frag)

			# Assign polygon & texture
			var assigned_buttons = find_button_for_fragment(frag_poly, button_bounds)
			frag.begin_break(frag_poly, the_ui, UI_Group.global_position)
			frag.add_interactive_area(frag_poly, assigned_buttons)

			#Add way to not save if has no alpha pixels.
			if !frag or frag.is_queued_for_deletion():
				continue
			# Save fragment data
			var fdata = FragmentData.new()
			fdata.polygon = frag_poly.duplicate()
			fdata.position = frag.global_position
			fragment_resources.append(fdata)
			frag.queue_free()

		# Save all fragments to resource
		#var container = FragmentsContainer.new()
		#container.fragments = fragment_resources
		#ResourceSaver.save(container, saved_fragments_paths[state])
		#fragment_resources.clear()
		#print("Saved fragments of menu "+str(state))
		
	#print("All fragment data saved!")

func load_fragments(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	UI_Group.visible = true
	var container: FragmentsContainer = load(path)
	for fdata in container.fragments:
		var frag = preload("res://Game Elements/ui/main_menu/break_frag.tscn").instantiate()
		$BreakFX.add_child(frag)
		frag.global_position = fdata.position
		var button_bounds = {}
		for button in $SubViewportContainer/SubViewport/UI_Group/VBoxContainer.get_children():
			if button is Button:
				button_bounds[button] = button.get_global_rect()
		var assigned_buttons = find_button_for_fragment(fdata.polygon, button_bounds)
		frag.begin_break(fdata.polygon, the_ui, UI_Group.global_position)
		frag.add_interactive_area(fdata.polygon, assigned_buttons)
	UI_Group.visible = false
	prev_state = normalize_ui_state({
		"p1_hover": null,
		"p1_press": false,
		"p2_hover": null,
		"p2_press": false
	})
	update_ui_display()


func rewind_ui(time : float):
	for f in $BreakFX.get_children():
		if "begin_rewind" in f:
			f.begin_rewind(time)

func overlaps_any_ui_element(frag_poly: Array, button_bounds: Dictionary) -> bool:
	for p in frag_poly:
		var global_point = UI_Group.global_position + p
		for rect in button_bounds.values():
			if rect.has_point(global_point):
				return true
	return false

func generate_jittered_grid_fragments(size_tex: Vector2, grid_x: int, grid_y: int, jitter: float = 10.0) -> Array:
	var fragments = []
	var cell_w = size_tex.x / grid_x
	var cell_h = size_tex.y / grid_y
	var points = []
	for x in range(grid_x + 1):
		points.append([])
		for y in range(grid_y + 1):
			points[x].append(Vector2.ZERO)
	var stop = false
	for y in range(grid_y+1):
		for x in range(grid_x+1):
			var px = x * cell_w
			var py = y * cell_h
			for vec in [Vector2(0,0),Vector2(0,size_tex.y),Vector2(size_tex.x,0),Vector2(size_tex.x,size_tex.y)]:
				if Vector2(px,py)==vec:
					points[x][y]= Vector2(px,py)
					stop = true
					break
			if stop:
				stop = false
			elif px == size_tex.x or px == 0:
				points[x][y] = Vector2(
					px,
					jitter_point(py, jitter, 0, size_tex.y)
				)
			elif py == size_tex.y or py == 0:
				points[x][y] = Vector2(
					jitter_point(px, jitter, 0, size_tex.x),
					py
				)
			else:
				points[x][y] = Vector2(
					jitter_point(px, jitter, 0, size_tex.x),
					jitter_point(py, jitter, 0, size_tex.y)
				)
	for y in range(grid_y):
		for x in range(grid_x):
			# Convex hull to ensure valid polygon
			var poly = [points[x][y],points[x+1][y],points[x+1][y+1],points[x][y+1]]
			# Remove last point if it equals the first
			if poly.size() > 1 and poly[0] == poly[poly.size() - 1]:
				poly.remove_at(poly.size() - 1)
			fragments.append(poly)
	return fragments
	
func jitter_point(p: float, jitter: float, min_val: float, max_val: float) -> float:
	return clamp(p + randf_range(-jitter, jitter), min_val, max_val)
	
func find_button_for_fragment(frag_poly: Array, button_bounds: Dictionary) -> Array[Button]:
	var overlapping_buttons : Array[Button]= []
	for button in button_bounds.keys():
		var rect = button_bounds[button]
		for p in frag_poly:
			var global_point = p + UI_Group.global_position
			if rect.has_point(global_point):
				overlapping_buttons.append(button)
				break
	return overlapping_buttons
	
func update_prompt():
	if Globals.player1_input == "key" and Input.get_connected_joypads().size() == 0:
		var text = "[font=res://addons/input_prompt_icon_font/icon.ttf]"
		if disruptive1:
			text += "keyboard_space[/font]"
		else:
			text += "keyboard_space_outline[/font]"
		$RichTextLabel.bbcode_text = text+": Toggle Fracturing "
	else:
		var text = ""
		text += button_state(Globals.player1_input,disruptive1) +"/"
		text += button_state(Globals.player2_input,disruptive2)
		$RichTextLabel.bbcode_text = text+": Toggle Fracturing "

func _on_focus_entered() -> void:
	print("focus entered")
	if hover_cooldown <= 0.0:
		print("playing audio")
		sfx_manager.play(preload("res://Game Elements/sfx/world/remnant_hover.ogg"), 0.0, "UI")
		hover_cooldown = 0.025

func button_state(input_type : String, active : bool):
	if input_type == "key":
		if active:
			return "[font=res://addons/input_prompt_icon_font/icon.ttf]keyboard_space[/font]"
		return "[font=res://addons/input_prompt_icon_font/icon.ttf]keyboard_space_outline[/font]"
	if active:
		return "[font=res://addons/input_prompt_icon_font/icon.ttf]playstation_trigger_l2[/font]"
	return "[font=res://addons/input_prompt_icon_font/icon.ttf]playstation_trigger_l2_outline[/font]"

func preload_all_textures():
	var buttons = []
	for button in $SubViewportContainer/SubViewport/UI_Group/VBoxContainer.get_children():
		if button is Button:
			buttons.append(button)
	var states = generate_all_valid_ui_states(buttons)
	for state in states:
		var fname = generate_filename(state)
		var path = "res://ui_captures/" + fname + ".png"
		if ResourceLoader.exists(path):
			ui_textures[fname] = load(path)
		else:
			fname = generate_filename(state, true)
			path = "res://ui_captures/" + fname + ".png"
			if ResourceLoader.exists(path):
				ui_textures[fname] = ResourceLoader.load(path)
		

func generate_all_valid_ui_states(buttons: Array) -> Array:
	var states = []
	for p1_hover in [null] + buttons:
		for p1_press in [false, true]:
			if p1_press and p1_hover == null:
				continue
			for p2_hover in [null] + buttons:
				# Avoid duplicate hover (both players on same button)
				if p2_hover != null and p2_hover == p1_hover:
					continue
				for p2_press in [false, true]:
					if p2_press and p2_hover == null:
						continue
					var state = {
						"p1_hover": p1_hover,
						"p1_press": p1_press,
						"p2_hover": p2_hover,
						"p2_press": p2_press
					}
					states.append(state)
	return states
	
func update_ui_display():
	var state = normalize_ui_state({
		"p1_hover": UI.player1.hover_button,
		"p1_press": UI.player1.pressing,
		"p2_hover": UI.player2.hover_button,
		"p2_press": UI.player2.pressing
	})
	if !prev_state or state!=prev_state:
		
		# handles UI sfx
		if prev_state and (state["p1_hover"] != prev_state["p1_hover"] \
		or state["p2_hover"] != prev_state["p2_hover"]):
			if hover_cooldown <= 0.0:
				print("playing hover sound")
				sfx_manager.play(preload("res://Game Elements/sfx/world/remnant_hover.ogg"), 0.0, "UI")
				hover_cooldown = 0.1
		
		prev_state=state
		var fname = generate_filename(prev_state)
		if !ui_textures.has(fname):
			fname = generate_filename(state, true)
		for frag in $BreakFX.get_children():
			if frag.is_in_group("ui_fragments"):
				frag.set_display_texture(ui_textures[fname])
	
func capture_all_ui_states():		
	print("capturing")
	var buttons = []
	for button in $SubViewportContainer/SubViewport/UI_Group/VBoxContainer.get_children():
		if button is Button:
			buttons.append(button)
	
	var valid_states = generate_all_valid_ui_states(buttons)
	for state in valid_states:
		var img = await capture_state(state)
		var filename = generate_filename(state)
		img.get_image().save_png("res://ui_captures/"+filename+".png")
	print("All states saved!")

func capture_state(state: Dictionary) -> ViewportTexture:
	# Update UI: apply hover/press for each player
	set_player_ui_state(state)
	
	await get_tree().process_frame

	var vp_tex = $SubViewportContainer/SubViewport.get_texture()
	return vp_tex
	
func generate_filename(state: Dictionary, reverse: bool = false) -> String:
	var norm_state = normalize_ui_state(state)
	var p1_name =  norm_state["p1_hover"].name if norm_state["p1_hover"] != null else "none"
	var p2_name =  norm_state["p2_hover"].name if norm_state["p2_hover"] != null else "none"
	var p1_press =  "press" if norm_state["p1_press"] else "hover"
	var p2_press = "press" if norm_state["p2_press"] else "hover"
	if reverse:
		return "p1_%s_%s_p2_%s_%s" % [p2_name, p2_press,p1_name, p1_press]
	return "p1_%s_%s_p2_%s_%s" % [p1_name, p1_press, p2_name, p2_press]

func set_player_ui_state(state: Dictionary) -> void:
	#Reset all buttons
	for button in $SubViewportContainer/SubViewport/UI_Group/VBoxContainer.get_children():
		if button is Button:
			button.button_pressed = false
			button.add_theme_stylebox_override("normal", button.get_theme_stylebox("disabled"))

	# Set P1
	if state["p1_hover"] != null:
		var b = state["p1_hover"]
		b.add_theme_stylebox_override("normal", b.get_theme_stylebox("hover"))
		if state["p1_press"]:
			b.add_theme_stylebox_override("normal", b.get_theme_stylebox("pressed"))

	# Set P2
	if state["p2_hover"] != null:
		var b = state["p2_hover"]
		b.add_theme_stylebox_override("normal", b.get_theme_stylebox("hover"))
		if state["p2_press"]:
			b.add_theme_stylebox_override("normal", b.get_theme_stylebox("pressed"))

func inputs(input_device):
	if input_device=="key":
		return
	if Input.is_action_just_pressed("menu_up_" + input_device) or \
		(Input.is_action_pressed("menu_up_" + input_device) and nav_cooldown <= 0.0):
		if nav_cooldown <= 0.0:
			nav_cooldown = nav_cooldown_time
			if UI.player1.input == input_device:
				UI.player1.pressing = false
				UI.player1.hover_button = get_next_button(UI.player1.hover_button, true)
				if !fragmenting: _on_focus_entered()
			if UI.player2.input == input_device:
				UI.player2.pressing = false
				UI.player2.hover_button = get_next_button(UI.player2.hover_button, true)
				if !fragmenting: _on_focus_entered()

	if Input.is_action_just_pressed("menu_down_" + input_device) or \
		(Input.is_action_pressed("menu_down_" + input_device) and nav_cooldown <= 0.0):
		if nav_cooldown <= 0.0:
			nav_cooldown = nav_cooldown_time
			if UI.player1.input == input_device:
				UI.player1.pressing = false
				UI.player1.hover_button = get_next_button(UI.player1.hover_button, false)
				if !fragmenting: _on_focus_entered()
			if UI.player2.input == input_device:
				UI.player2.pressing = false
				UI.player2.hover_button = get_next_button(UI.player2.hover_button, false)
				if !fragmenting: _on_focus_entered()

	if Input.is_action_just_pressed("activate_" + input_device):
		if UI.player1.input == input_device:
			UI.player1.pressing = true
		if UI.player2.input == input_device:
			UI.player2.pressing = true

	if Input.is_action_just_released("activate_" + input_device):
		if skip_next_release:
			skip_next_release = false
		else:
			if UI.player1.input == input_device and UI.player1.pressing:
				UI.player1.hover_button.emit_signal("pressed")
				if fragmenting: sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))
			if UI.player2.input == input_device and UI.player2.pressing:
				UI.player2.hover_button.emit_signal("pressed")
				if fragmenting: sfx_manager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"))

func normalize_ui_state(state: Dictionary) -> Dictionary:
	var p1_hover = state["p1_hover"]
	var p2_hover = state["p2_hover"]
	var p1_press = state["p1_press"]
	var p2_press = state["p2_press"]
	if	p2_hover != null and p2_hover == p1_hover: #If illegal state, resolve it
		if p2_press:
			p1_hover=null
		else:
			p2_hover=null
	#If both players hover different buttons, order them by button name
	if p1_hover != null and p2_hover != null:
		if p1_hover.name > p2_hover.name:
			# Swap players
			var tmp_hover = p1_hover
			var tmp_press = p1_press
			p1_hover = p2_hover
			p1_press = p2_press
			p2_hover = tmp_hover
			p2_press = tmp_press
	return {
	"p1_hover": p1_hover,
	"p1_press": p1_press,
	"p2_hover": p2_hover,
	"p2_press": p2_press
	}


func get_next_button(current_button: Button, reverse_order : bool, container: VBoxContainer = $SubViewportContainer/SubViewport/UI_Group/VBoxContainer) -> Button:
	var children = container.get_children()

	#Reverse the list if needed
	if reverse_order:
		children.reverse()

	var found_current = false
	for child in children:
		if child is Button:
			if found_current:
				return child  #Next button found
			if child == current_button:
				found_current = true

	#Wrap around: return the first button in the (possibly reversed) list
	for child in children:
		if child is Button:
			return child
	return null  #No buttons found
