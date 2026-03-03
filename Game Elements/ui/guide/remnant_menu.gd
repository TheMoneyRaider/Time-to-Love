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
				is_dragging = false
				_calculate_snap_target()

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
			scroll_position = lerp(scroll_position, snap_target, snap_speed * delta)
			_update_scroll()

func _update_scroll():
	var view_width = scroller.size.x
	var content_width = list_container.size.x

	# Clamp scrolling
	scroll_position = clamp(scroll_position, min(view_width - content_width, 0), 0)
	list_container.position.x = scroll_position

	for child in list_container.get_children():
		var center_dist = abs(child.global_position.x - scroller.size.x / 2)
		var scale_factor = clamp(1.2 - center_dist / 600.0, 0.8, 1.2)
		child.scale = Vector2.ONE * scale_factor

# Find nearest remnant and set snap target
func _calculate_snap_target():
	if list_container.get_child_count() == 0:
		return

	# Assume all children have the same width
	var child_width = list_container.get_child(0).size.x

	# Compute approximate nearest index from scroll_position
	var center = scroller.size.x / 2
	var approx_index = round((center - scroll_position - child_width / 2) / child_width)

	# Clamp to valid child indices
	approx_index = clamp(approx_index, 0, list_container.get_child_count() - 1)

	# Snap to the child at that index
	var child = list_container.get_child(approx_index)
	snap_target = -child.position.x + center - child.size.x / 2

	# Clamp snap_target to scroll bounds
	snap_target = clamp(snap_target, min(scroller.size.x - list_container.size.x, 0), 0)



func _on_slot_selected(idx: int) -> void:
	#print(list_container.get_child(idx).remnant.remnant_name)
	pass


func _on_return_pressed():
	active = false
	hide()
	snap_target=0.0
	scroll_position=0.0
	get_parent().get_node("PauseMenu").activate()
	
