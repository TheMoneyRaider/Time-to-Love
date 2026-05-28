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

var last_center_index: int = -1

func _ready():
	$Control/Return.mouse_entered.connect(func(): SFXManager.play(preload("res://Game Elements/sfx/world/remnant_hover.ogg"), 0.0, "UI"))
	$Control/Return.focus_entered.connect(func(): SFXManager.play(preload("res://Game Elements/sfx/world/remnant_hover.ogg"), 0.0, "UI"))
	hide()

func queue_free_children(n :Node):
	for c in n.get_children():
		c.queue_free()

func populate_remnants():
	var i = 0
	var prog = max(Globals.save_state.total_progress,Globals.total_progress,RoomManager.current_progress)
	var last_entry : Node = null
	var rems = RemnantManager.remnant_pool.duplicate(true)
	rems.sort_custom(_sort_by_progress_required)
	
	for rem in rems:
		rem.rank = 1
		var entry = preload("res://Game Elements/ui/remnant_slot.tscn").instantiate()

		list_container.add_child(entry)
		entry.set_remnant(rem.duplicate(true),false)
		visualize(entry,prog)
		entry.slot_selected.connect(_on_slot_selected)
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


func _on_remnant_focus(focused_button: Button) -> void:
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
	var a_is_boss = a.tags.size() > 0 and a.tags[0] == "boss_remnant"
	var b_is_boss = b.tags.size() > 0 and b.tags[0] == "boss_remnant"

	if a_is_boss != b_is_boss:
		return a_is_boss  # boss remnants sort first
	return a.progress_required < b.progress_required


func visualize(entry : Node, total_progress : float):
	var rem = entry.remnant
	var discovered = Globals.save_state.remnant_progress.has(rem.remnant_name)
	if total_progress < rem.progress_required or (rem.tags.size()>0 and rem.tags[0]=="boss_remnant" and !discovered):
		print(rem.remnant_name)
		entry.modulate = Color()
		return
	if !discovered:
		entry.get_node("btn_select/container/description_label").visible = false
		entry.get_node("btn_select/art").material.set_shader_parameter("grayscale",true)
		return
	var max_rank = Globals.save_state.remnant_progress[rem.remnant_name]
	if rem.rank >max_rank:
		entry.get_node("btn_select/container/description_label").visible = false
		entry.get_node("btn_select/art").material.set_shader_parameter("grayscale",true)
		return
	entry.get_node("btn_select/container/description_label").visible = true
	entry.get_node("btn_select/art").material.set_shader_parameter("grayscale",false)
		




func activate():
	SFXManager.pause_all_continuous()
	active = true
	show()
	populate_remnants()
	$Control/Return.grab_focus()
var rem_snapped = false
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
			# Snap to nearest remnant
			if !rem_snapped:
				_calculate_snap_target()
				rem_snapped = true
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
	SFXManager.play(preload("res://Game Elements/sfx/world/remnant_hover.ogg"), 0.0, "UI")
	if current_focus_index >= 0:
		var entry = list_container.get_child(current_focus_index)
		var btn = entry.btn_select
		_on_remnant_focus(btn)

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

	var center_x = scroller.global_position.x + scroller.size.x / 2
	var nearest_idx = 0
	var nearest_dist = INF
	var idx = 0
	for child in list_container.get_children():
		var center_dist = abs(child.global_position.x + child.size.x/2 - center_x)
		var scale_factor = clamp(1 - center_dist / 2400.0, 0.8, 1)
		child.scale = Vector2.ONE * scale_factor
		if center_dist < nearest_dist:
			nearest_dist = center_dist
			nearest_idx = idx
		idx += 1

	if nearest_idx != last_center_index:
		last_center_index = nearest_idx
		SFXManager.play(preload("res://Game Elements/sfx/world/remnant_hover.ogg"), 0.0, "UI")

# Find nearest remnant and set snap target
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


func _on_slot_selected(idx: int) -> void:
	SFXManager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"), 0.0, "UI")
	var prog = max(Globals.save_state.total_progress,Globals.total_progress,RoomManager.current_progress)
	var entry = list_container.get_child(idx)
	var rem = list_container.get_child(idx).remnant
	rem.rank=(rem.rank %5)+1
	entry.set_remnant(rem,false)
	visualize(entry,prog)


func _on_return_pressed():
	SFXManager.play(preload("res://Game Elements/ui/sfx/select_002.ogg"), 0.0, "UI")
	SFXManager.resume_all_continuous()
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
				rem_snapped = false
				is_dragging = false

	elif event is InputEventMouseMotion and is_dragging:
		var delta = event.position.x - drag_last_x
		drag_last_x = event.position.x

		scroll_position += delta
		velocity = delta
		_update_scroll()
