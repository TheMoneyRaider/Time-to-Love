extends CanvasLayer

var mouse_mode = null
var active = false
@export var list_container : HBoxContainer
@export var scroller : Control

var velocity := 0.0
var is_dragging := false
var drag_last_x := 0.0
var scroll_position := 0.0
var snap_target := 0.0
var snap_speed := 10.0
var current_focus_index := -2  # -1 means return focused
@export var joystick_deadzone := 0.5  # adjust for your joystick sensitivity
var last_input_dir := 0  # prevent repeated triggers
var last_input_dirv := 0  # prevent repeated triggers

var LayerManager : Node
func _ready():
	
	LayerManager = get_tree().get_root().get_node("LayerManager")
	hide()

func queue_free_children(n :Node):
	for c in n.get_children():
		c.queue_free()

func _load_all_weapons() -> Array[Weapon]:
	var weapon_pool : Array[Weapon]= []
	var dir = ResourceLoader.list_directory("res://Game Elements/Weapons/")

	if dir == null:
		push_error("Weapons folder not found: res://Game Elements/Weapons/")
		return []
	for file in dir:
		if file.ends_with(".tres"):
			var res = ResourceLoader.load("res://Game Elements/Weapons/" + file)
			if res and res.is_player_weapon:
				weapon_pool.append(res)
	return weapon_pool
func populate_weapons():
	var i = 0
	var prog = Globals.save_state.total_progress
	var last_entry : Node = null
	var weapons = _load_all_weapons()
	weapons.sort_custom(_sort_by_progress_required)
	
	for wep in weapons:
		if wep.name !="Fist":
			var entry = preload("res://Game Elements/ui/guide/weapon_slot.tscn").instantiate()

			list_container.add_child(entry)
			entry.set_weapon(wep.duplicate(true))
			visualize(entry,prog)
			entry.index = i
			call_deferred("_setup_focus_neighbors", entry, last_entry)
			last_entry = entry
			i+=1
	# Reset scroll
	scroll_position = 0
	list_container.position.x = scroll_position
	list_container.position.y = 0

func _setup_focus_neighbors(entry, left_neighbor):
	if left_neighbor:
		entry.btn_select.focus_neighbor_left = left_neighbor.btn_select.get_path()
		left_neighbor.btn_select.focus_neighbor_right = entry.btn_select.get_path()
	entry.btn_select.focus_neighbor_top = get_node("Control/Return").get_path()
	if entry.index == 0:
		$Control/Return.focus_neighbor_bottom = entry.btn_select.get_path()


func _on_weapon_focus(focused_button: Button) -> void:
	# Center the focused button
	var child = focused_button.get_parent() # assuming btn_select is a direct child of entry
	var target_x = -child.position.x + scroller.size.x / 2 - child.size.x / 2

	# Clamp using first/last child
	var first_child = list_container.get_child(0)
	var last_child = list_container.get_child(list_container.get_child_count() - 1)
	var min_scroll = scroller.size.x/2 - last_child.position.x - last_child.size.x/2
	var max_scroll = scroller.size.x/2 - first_child.position.x - first_child.size.x/2
	scroll_position = clamp(target_x, min_scroll, max_scroll)
	snap_target = clamp(target_x, min_scroll, max_scroll)
	list_container.position.x = scroll_position
	
	# Update $Control/Return's bottom focus neighbor
	$Control/Return.focus_neighbor_bottom = focused_button.get_path()

func _sort_by_progress_required(a, b):
	if a.progress_required < b.progress_required:
		return true
	return false


func visualize(entry : Node, total_progress : float):
	var wep = entry.weapon
	var wep1 = LayerManager.player1.weapons[0].type
	var wep2= LayerManager.player1.weapons[1].type
	if LayerManager.is_multiplayer:
		wep2= LayerManager.player2.weapons[1].type
	if total_progress < wep.progress_required:
		entry.get_node("btn_select/container/description_label").visible = false
		entry.get_node("btn_select/container/name_label").visible = false
		entry.get_node("btn_select/container/WeaponSprite/Sprite2D").modulate = Color()
		entry.get_node("btn_select/container/WeaponSprite/Sprite2D").material.set_shader_parameter("grayscale",false)
	elif wep1 !=wep.type and wep2 !=wep.type:
		print("gray")
		entry.get_node("btn_select/container/description_label").visible = true
		entry.get_node("btn_select/container/name_label").visible = true
		entry.get_node("btn_select/container/WeaponSprite/Sprite2D").modulate = Color(1.0, 1.0, 1.0, 1.0)
		entry.get_node("btn_select/container/WeaponSprite/Sprite2D").material.set_shader_parameter("grayscale",true)
	else:
		entry.get_node("btn_select/container/description_label").visible = true
		entry.get_node("btn_select/container/name_label").visible = true
		entry.get_node("btn_select/container/WeaponSprite/Sprite2D").modulate = Color(1.0, 1.0, 1.0, 1.0)
		entry.get_node("btn_select/container/WeaponSprite/Sprite2D").material.set_shader_parameter("grayscale",false)
		




func activate():
	active = true
	show()
	populate_weapons()
	$Control/Return.grab_focus()
var wep_snapped = false
func _process(delta):
	if !active:
		return
		
	# --- Handle joystick navigation ---
	var joy_dir := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var v_joy_dir := Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	# Check for deadzone to avoid tiny movements
	if abs(v_joy_dir) < joystick_deadzone:
		last_input_dirv = 0
	elif int(sign(v_joy_dir)) != last_input_dirv:
		last_input_dirv = int(sign(v_joy_dir))
		if last_input_dirv > 0:
			current_focus_index = -1
			$Control/Return.release_focus()
		if last_input_dirv < 0:
			current_focus_index = -2
			$Control/Return.grab_focus()
	if abs(joy_dir) < joystick_deadzone:
		last_input_dir = 0
	elif int(sign(joy_dir)) != last_input_dir:
		last_input_dir = int(sign(joy_dir))
		move_focus(last_input_dir)

	# --- BUTTON PRESS ---
	if Input.is_action_just_pressed("ui_accept"):
		if current_focus_index >= 0:
			var entry = list_container.get_child(current_focus_index)
			entry.btn_select.emit_signal("pressed")  # or call _on_slot_selected
		else:
			_on_return_pressed()
	
	if Input.is_action_just_pressed("ui_cancel"):
		_on_return_pressed()
		
	if not is_dragging:
		# Apply inertia
		if abs(velocity) > 0.1:
			scroll_position += velocity
			velocity = lerp(velocity, 0.0, 5 * delta)
			_update_scroll()
		else:
			# Snap to nearest weapon
			if !wep_snapped:
				_calculate_snap_target()
				wep_snapped = true
			scroll_position = lerp(scroll_position, snap_target, snap_speed * delta)
			_update_scroll()

func move_focus(direction: int) -> void:
	if list_container.get_child_count() == 0:
		return

	# Initialize focus if none
	if current_focus_index == -1:
		current_focus_index = 0
	elif current_focus_index >= 0:
		current_focus_index += direction
		current_focus_index = clamp(current_focus_index, 0, list_container.get_child_count() - 1)
	SFXManager.play(preload("res://Game Elements/sfx/world/remnant_hover.ogg"), 0.0, "UI")  # ← add here
	if current_focus_index >= 0:
		var entry = list_container.get_child(current_focus_index)
		var btn = entry.btn_select
		_on_weapon_focus(btn)

func _update_scroll():
	
	var view_width = scroller.size.x

	if list_container.get_child_count() == 0:
		return

	var first_child = list_container.get_child(0)
	var last_child = list_container.get_child(list_container.get_child_count() - 1)

	# Calculate min/max so first/last can be centered
	var min_scroll = view_width/2 - last_child.position.x - last_child.size.x/2
	var max_scroll = view_width/2 - first_child.position.x - first_child.size.x/2

	# Clamp scroll position to center first/last
	scroll_position = clamp(scroll_position, min_scroll, max_scroll)
	list_container.position.x = scroll_position

	# Scale effect for children
	for child in list_container.get_children():
		var center_dist = abs(child.global_position.x + child.size.x/2 - scroller.global_position.x - scroller.size.x/2)
		var scale_factor = clamp(1 - center_dist / 2400.0, 0.8, 1)
		child.scale = Vector2.ONE * scale_factor

# Find nearest weapon and set snap target
func _calculate_snap_target():
	if list_container.get_child_count() == 0:
		return

	var center_x = scroller.global_position.x + scroller.size.x / 2
	var nearest = list_container.get_child(0)
	var nearest_dist = abs(nearest.global_position.x + nearest.size.x/2 - center_x)

	for child in list_container.get_children():
		var child_center = child.global_position.x + child.size.x/2
		var dist = abs(child_center - center_x)
		if dist < nearest_dist:
			nearest = child
			nearest_dist = dist

	# Compute snap target to center nearest child
	snap_target = -nearest.position.x + scroller.size.x/2 - nearest.size.x/2
	if current_focus_index >= -1:
		current_focus_index = nearest.index
	# Use the same center-based clamp as _update_scroll
	var first_child = list_container.get_child(0)
	var last_child = list_container.get_child(list_container.get_child_count() - 1)
	var min_scroll = scroller.size.x/2 - last_child.position.x - last_child.size.x/2
	var max_scroll = scroller.size.x/2 - first_child.position.x - first_child.size.x/2

	snap_target = clamp(snap_target, min_scroll, max_scroll)


func _on_return_pressed():
	SFXManager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"), 0.0, "UI")
	queue_free_children(list_container)
	active = false
	hide()
	velocity = 0.0
	is_dragging = false
	drag_last_x = 0.0
	scroll_position = 0.0
	snap_target = 0.0
	current_focus_index = -2
	$Control/Return.grab_focus()
	get_parent().get_node("PauseMenu").activate()
	
	

func _on_control_gui_input(event: InputEvent) -> void:
	if !active:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_last_x = event.position.x
				velocity = 0
			else:
				wep_snapped = false
				is_dragging = false

	elif event is InputEventMouseMotion and is_dragging:
		var delta = event.position.x - drag_last_x
		drag_last_x = event.position.x

		scroll_position += delta
		velocity = delta
		_update_scroll()
