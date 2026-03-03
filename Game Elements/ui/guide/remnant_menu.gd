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

func _ready():
	hide()

func queue_free_children(n :Node):
	for c in n.get_children():
		c.queue_free()

func populate_remnants():
	var i = 0
	queue_free_children(list_container)
	var prog = Globals.config.get_value("progress", "total_progress", 0.0)
	var last_entry : Node = null
	for rem in RemnantManager.remnant_pool:
		rem.rank = 1
		var entry = preload("res://Game Elements/ui/remnant_slot.tscn").instantiate()

		list_container.add_child(entry)
		entry.set_remnant(rem,false)
		visualize(entry,prog)
		entry.slot_selected.connect(_on_slot_selected)
		entry.index = i
		if last_entry:
			entry.btn_select.focus_neighbor_left = last_entry.btn_select.get_path()
			last_entry.btn_select.focus_neighbor_right = entry.btn_select.get_path()
		entry.btn_select.focus_neighbor_top = $Control/Return.get_path()
		last_entry = entry
		i+=1
	# Reset scroll
	scroll_position = 0
	list_container.position.x = scroll_position
	list_container.position.y = 0

func _input(event):
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

func visualize(entry : Node, total_progress : float):
	var rem = entry.remnant
	var discovered = Globals.remnant_progress.has(rem.remnant_name)
	if total_progress < rem.progress_required:
		#entry.modulate = Color()
		return
	if !discovered:
		entry.get_node("btn_select/container/description_label").visible = false
		entry.get_node("btn_select/art").material.set_shader_parameter("grayscale",true)
		return
	var max_rank = Globals.remnant_progress[rem.remnant_name]
	if rem.rank >max_rank:
		entry.get_node("btn_select/container/description_label").visible = false
		entry.get_node("btn_select/art").material.set_shader_parameter("grayscale",true)
		return
	entry.get_node("btn_select/container/description_label").visible = true
	entry.get_node("btn_select/art").material.set_shader_parameter("grayscale",false)
		


func activate():
	active = true
	show()
	if Globals.is_multiplayer or Globals.player1_input != "key":
		$Control/Return.grab_focus()
	populate_remnants()
var rem_snapped = false
func _process(delta):
	if !active:
		return
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

func _update_scroll():
	
	var view_width = scroller.size.x
	var content_width = list_container.size.x

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

	# Use the same center-based clamp as _update_scroll
	var first_child = list_container.get_child(0)
	var last_child = list_container.get_child(list_container.get_child_count() - 1)
	var min_scroll = scroller.size.x/2 - last_child.position.x - last_child.size.x/2
	var max_scroll = scroller.size.x/2 - first_child.position.x - first_child.size.x/2

	snap_target = clamp(snap_target, min_scroll, max_scroll)


func _on_slot_selected(idx: int) -> void:
	#print(list_container.get_child(idx).remnant.remnant_name)
	pass


func _on_return_pressed():
	active = false
	hide()
	snap_target=0.0
	scroll_position=0.0
	get_parent().get_node("PauseMenu").activate()
	
