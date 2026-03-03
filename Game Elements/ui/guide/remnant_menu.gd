extends CanvasLayer

var mouse_mode = null
var active = false
@export var list_container : Node
@export var marg_container : Node

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
		var discovered = Globals.remnant_progress.has(rem.remnant_name)

		list_container.add_child(entry)
		entry.set_remnant(rem,false)
		#if #total progress check
		if prog < rem.progress_required:
			entry.modulate = Color()
		elif !discovered:
			entry.get_node("btn_select/art").material.set_shader_parameter("grayscale",true)
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

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_last_x = event.position.x
				velocity = 0
			else:
				is_dragging = false
				_calculate_snap_target()

	if event is InputEventMouseMotion and is_dragging:
		var delta = event.position.x - drag_last_x
		drag_last_x = event.position.x

		scroll_position += delta
		velocity = delta

		_update_scroll()


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
			velocity = lerp(velocity, 0, 5 * delta)
			_update_scroll()
		else:
			# Snap to nearest remnant
			var diff = snap_target - scroll_position
			scroll_position += diff * clamp(snap_speed * delta, 0, 1)
			_update_scroll()

func _update_scroll():
	list_container.position.x = scroll_position

	var view_width = marg_container.size.x
	var content_width = list_container.size.x

	# Clamp scrolling
	scroll_position = clamp(scroll_position, min(view_width - content_width, 0), 0)
	list_container.position.x = scroll_position

	for child in list_container.get_children():
		var center_dist = abs(child.global_position.x - marg_container.size.x / 2)
		var scale_factor = clamp(1.2 - center_dist / 600.0, 0.8, 1.2)
		child.scale = Vector2.ONE * scale_factor

# Find nearest remnant and set snap target
func _calculate_snap_target():
	if list_container.get_child_count() == 0:
		return

	var center_x = marg_container.size.x / 2
	var nearest = list_container.get_child(0)
	var nearest_dist = abs((nearest.position.x + nearest.size.x/2 + scroll_position) - center_x)

	for child in list_container.get_children():
		var child_center = child.position.x + child.size.x / 2 + scroll_position
		var dist = abs(child_center - center_x)
		if dist < nearest_dist:
			nearest = child
			nearest_dist = dist

	# Snap target = so that nearest child is centered
	snap_target = -nearest.position.x + center_x - nearest.size.x/2
	# Clamp
	snap_target = clamp(snap_target, min(marg_container.size.x - list_container.size.x, 0), 0)



func _on_slot_selected(idx: int) -> void:
	pass


func _on_return_pressed():
	active = false
	hide()
	get_parent().get_node("PauseMenu").activate()
	
