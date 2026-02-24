class_name Arm extends Node2D
## Procedural tentacle arm showcasing FABRIK IK with a wave (hello)
##
## This script shows a multi-pass approach to believable procedural animation:
## 1. FABRIK IK gets the arm pointing at targets accurately
## 2. Constraints prevent the physics from breaking (stretching, compression)
## 3. Wave motion adds life and organic feel
## 4. Final constraint pass keeps everything in check. ¯\_(⊙_ʖ⊙)_/¯
##
## The @tool annotation makes it work in the editor, cool.

#region Exports
@export_group("Node References")
## Main tentacle
@export var base_node: Line2D

## Optional target node to track. If not set, tracks mouse position instead.
@export var target: Node2D
@export var reward: Node2D

@export_group("IK Configuration")
## More _segments = smoother curves but higher computation cost. Start low, increase if jerky.
## The setter rebuilds the segment arrays so you can see changes immediately in the editor.
@export_range(3, 50, 1) var num__segments: int = 24
## Total arm length. IK will compress the arm when target is closer than this distance.
## The setter recalculates segment lengths for immediate visual feedback in the editor.
@export_range(10.0, 256.0, 1.0) var max_length: float = 128.0
## Higher iterations = more accurate target tracking but diminishing returns after 3-4.
@export_range(1, 10, 1) var ik_iterations: int = 2
## Higher iterations = more rigid _segments. Too low and the arm will stretch/compress.
@export_range(1, 20, 1) var constraint_iterations: int = 10
## Enable or disable constraints
@export var enable_contraint: bool = true

@export_group("Wave Motion")
## Perpendicular displacement. Too high destroys the IK targeting, too low looks stiff.
@export_range(0.0, 5.0, 0.5) var wave_amplitude: float = 2.5
## Controls wavelength. Higher values create tighter, more frequent waves along the arm.
@export_range(0.0, 5, 0.1) var wave_frequency: float = 2.0
## Animation speed multiplier. Independent from physics delta for artistic control.
@export_range(0.0, 10.0, 0.1) var wave_speed: float = 0.5

@export_group("Visual Properties")
## Base width of the Line2D in pixels. The width_curve modulates this value along the length.
## Keeping this synchronized ensures the shadow perfectly matches the main tentacle.
@export_range(1.0, 100.0, 0.5) var line_width: float = 24.0
## Width curve controls tapering from base (thick) to tip (thin). Keeping this in code
## ensures the shadow Line2D matches the main Line2D perfectly - no manual sync needed.
## The setter ensures live updates in the editor when you modify the curve.
@export var width_curve: Curve
		
@export var light_color: Color = Color("93faff")
@export var dark_color: Color = Color("00e1e4")
@export var hole_global_position : Vector2 = Vector2(8,32)
@export var emerge_height : float = 40



#endregion

#region Private Var
var _segments: Array[Vector2] = []
var _segment_lengths: Array[float] = []
var _base_position: Vector2
var _wave_time: float = 0.0
#endregion

var hole_image: Image
var hole_texture: Texture2D
var hole_size: Vector2 = Vector2(128,128)
var hole_source : String = "shop_tentacles_sdf"

## Runs on scene load and sets up segments.
## Separate from _initialize_segments() so setters can rebuild segments during editing.
var viewport_offset
func _ready() -> void:
	viewport_offset = $SubViewportContainer.position + base_node.position
	_wave_time = randf() * 100
	hole_texture = load("res://art/holes/"+hole_source+".png")
	hole_image = hole_texture.get_image()
	compute_hole_sdf()
	
	$SubViewportContainer/SubViewport/TwoToneCanvasGroup.material = $SubViewportContainer/SubViewport/TwoToneCanvasGroup.material.duplicate()
	if base_node:
		_base_position = Vector2.ZERO
		base_node.width = line_width
		base_node.width_curve = width_curve
	_initialize_segments()
	$SubViewportContainer/SubViewport/TwoToneCanvasGroup.material.set_shader_parameter("light_color",light_color)
	$SubViewportContainer/SubViewport/TwoToneCanvasGroup.material.set_shader_parameter("dark_color",dark_color)
	$SubViewportContainer.material.set_shader_parameter("emerge_height",emerge_height)


func shrink(shrink_amount : float, change_length : bool = true):
	if change_length:
		max_length = int(max_length * shrink_amount)

	var from_hole : Vector2 = target.origin - hole_global_position
	target.origin = hole_global_position + from_hole * shrink_amount
	target.global_position = target.origin
	_initialize_segments()


func set_hole(hole_position : Vector2):
	hole_global_position = hole_position
var total_length
var root_offset
## Runs each physics frame applying IK, constraints, wave motion, then constraints again.
func _physics_process(delta: float) -> void:
	root_offset = get_parent().get_parent().get_parent().position
	var target_pos: Vector2 = to_local(target.global_position)-root_offset if target else to_local(get_global_mouse_position())
	solve_ik(target_pos)
	apply_wave_motion(delta)
	apply_constraints()

	update_line2d()


## Two-pass FABRIK IK: backward pass pulls tip to target, forward pass anchors base.
## Iterate both to satisfy tip and base constraints simultaneously.
func solve_ik(target_position: Vector2) -> void:

	# Set the tip to the target ( ͡° ͜ʖ ͡°)
	_segments[-1] = target_position

	for _iter in range(ik_iterations):
		# Backward: Start from the known good tip position and work back
		# After this pass, tip is correct but base has drifted
		for i in range(num__segments - 1, -1, -1):
			var vec: Vector2 = _segments[i] - _segments[i + 1]
			var dir_len = vec.length()
			var dir = vec / dir_len if dir_len > 0.0001 else Vector2.RIGHT
			_segments[i] = _segments[i + 1] + dir * _segment_lengths[i]
			
			# Clamp to hole if under ground
			_segments[i] = constrain_to_hole_mask(_segments[i],i)

		# Forward: Re-anchor the base and propagate correct lengths forward
		# After this pass, base is correct but tip has moved slightly off target
		# That's why we iterate - each iteration gets closer to satisfying both
		_segments[0] = _base_position
		for i in range(num__segments):
			var vec: Vector2 = _segments[i + 1] - _segments[i]
			var dir_len = vec.length()
			var dir = vec / dir_len if dir_len > 0.0001 else Vector2.RIGHT
			_segments[i + 1] = _segments[i] + dir * _segment_lengths[i]
			
			# Clamp to hole if under ground
			_segments[i + 1] = constrain_to_hole_mask(_segments[i + 1],i + 1)


## moves both _segments toward each other to fix segment stretching. (ಠ_ಠ)
## Multiple iterations let corrections ripple through the chain.
func apply_constraints() -> void:
	if not enable_contraint:
		return
	_segments[0] = _base_position

	for _iter in range(constraint_iterations):
		for i in range(num__segments):
			var current_vec: Vector2 = _segments[i + 1] - _segments[i]
			var distance: float = current_vec.length()

			# Segments can overlap during extreme IK solving (rapid target movements).
			# If that happens _segments can stay stuck.
			# If the distance is small, separate them with an arbitrary direction.
			if distance < 0.0001:
				_segments[i + 1] = _segments[i] + Vector2.RIGHT * _segment_lengths[i]
				continue

			# Calculate the error between current and target length
			var target_vec: Vector2 = current_vec.normalized() * _segment_lengths[i]
			var error_vec: Vector2 = target_vec - current_vec

			# Apply 25% of error to each segment (bilateral correction = 50% total)
			# Base is immovable anchor point - only its neighbor moves toward it
			if i > 0:
				_segments[i] -= error_vec * 0.25
			_segments[i + 1] += error_vec * 0.25

		_segments[0] = _base_position


## Adds sine wave displacement perpendicular to arm direction so waves don't fight IK.
## Phase-based animation creates traveling waves from base to tip.
func apply_wave_motion(delta: float) -> void:

	# No amplitude, no wave!!
	if wave_amplitude <= 0.0:
		return

	_wave_time += delta * wave_speed
	
	var accumulated_length: float = 0.0
	for i in range(1, _segments.size()):
		accumulated_length += _segment_lengths[i - 1]

		# Normalized position (0-1) along the arm determines wave phase offset
		var t: float = accumulated_length / total_length

		var vec: Vector2 = _segments[i] - _segments[i - 1]
		var direction: Vector2 = vec.normalized()
		var perpendicular: Vector2 = direction.orthogonal()

		# Phase combines time (animation) with position (traveling wave) ᶘ ◕ᴥ◕ᶅ
		var wave_phase: float = _wave_time + t * wave_frequency * TAU
		var wave_offset: float = sin(wave_phase) * wave_amplitude
		_segments[i] += perpendicular * wave_offset


## Updates Line2D points
## Shadow offset interpolates from small (base) to large (tip) for depth trick.
func update_line2d() -> void:
	base_node.clear_points()
	for pos in _segments:
		base_node.add_point(pos-viewport_offset) #Offset due to viewport


## Rebuilds segment arrays when num__segments or max_length change.
## Starts with straight horizontal line so IK has valid initial positions.
func _initialize_segments() -> void:
	# Early exit if called from setter before nodes are ready
	if not base_node:
		return
		
	##adaptive segment count based on length
	#num__segments = int (max_length / 7.30769230769)

	# Clear and rebuild arrays
	_segments.clear()
	_segment_lengths.clear()

	_segments.append(_base_position)
	for i in range(num__segments):
		# Equal-length _segments simplify math and create even wave distribution
		var length: float = max_length / num__segments
		_segment_lengths.append(length)
		_segments.append(_base_position + Vector2(length * (i + 1), 0))

	# Update visual immediately for editor feedback
	update_line2d()
	total_length = max_length





var hole_sdf: PackedFloat32Array
var sdf_size: Vector2
var hole_grad_x: PackedFloat32Array
var hole_grad_y: PackedFloat32Array

var sdf_resource_path := "res://Game Elements/tentacle_resources/"
var sdf_data: SDFData

func compute_hole_sdf():
	# 1. Try to load cached SDF resource
	if FileAccess.file_exists(sdf_resource_path+str(emerge_height)+hole_source+".tres"):
		var loaded = ResourceLoader.load(sdf_resource_path+str(emerge_height)+hole_source+".tres")
		if loaded is SDFData:
			sdf_data = loaded
			sdf_size = sdf_data.sdf_size
			hole_sdf = sdf_data.hole_sdf
			hole_grad_x = sdf_data.hole_grad_x
			hole_grad_y = sdf_data.hole_grad_y
			print("Loaded cached SDF from disk.")
			return
			
	# 2. If not found, compute normally
	print("No SDF cache found — computing from scratch.")
	_compute_sdf_internal()

	# 3. Save result to resource file
	sdf_data = SDFData.new()
	sdf_data.sdf_size = sdf_size
	sdf_data.hole_sdf = hole_sdf
	sdf_data.hole_grad_x = hole_grad_x
	sdf_data.hole_grad_y = hole_grad_y

	ResourceSaver.save(sdf_data,sdf_resource_path+str(emerge_height)+hole_source+".tres")
	print("SDF saved to disk for next run.")
	
func _compute_sdf_internal():
	sdf_size = hole_size
	var w = int(hole_size.x)
	var h = int(hole_size.y)
	hole_sdf = PackedFloat32Array()
	hole_sdf.resize(w * h)

	# Initialize
	for y in range(h):
		for x in range(w):
			var idx = y * w + x
			var uv = Vector2(x / float(w), y / float(h))

			# Extra rules from is_inside_hole()
			var inside = false
			if y < emerge_height:
				inside = true
			elif abs(uv.x - 0.5) < 0.26 and uv.y > 0.5:
				inside = true
			else:
				var c = hole_image.get_pixel(x, y)
				if c.r > 0.5:
					inside = true
			hole_sdf[idx] = 0.0 if inside else INF

	# First pass
	for y in range(h):
		for x in range(w):
			var idx = y * w + x
			if x > 0:
				hole_sdf[idx] = min(hole_sdf[idx], hole_sdf[idx-1] + 1)
			if y > 0:
				hole_sdf[idx] = min(hole_sdf[idx], hole_sdf[idx-w] + 1)

	# Second pass
	for y in range(h-1, -1, -1):
		for x in range(w-1, -1, -1):
			var idx = y * w + x
			if x < w-1:
				hole_sdf[idx] = min(hole_sdf[idx], hole_sdf[idx+1] + 1)
			if y < h-1:
				hole_sdf[idx] = min(hole_sdf[idx], hole_sdf[idx+w] + 1)

	# Get Euclidean distance
	for i in range(hole_sdf.size()):
		hole_sdf[i] = sqrt(hole_sdf[i])
	# Allocate gradient arrays
	hole_grad_x = PackedFloat32Array()
	hole_grad_y = PackedFloat32Array()
	hole_grad_x.resize(w * h)
	hole_grad_y.resize(w * h)

	# Compute normalized gradients once
	for y in range(h):
		for x in range(w):
			var idx = y * w + x

			# Sample neighbors (clamped)
			var left   = hole_sdf[idx] if x == 0      else hole_sdf[idx - 1]
			var right  = hole_sdf[idx] if x == w - 1  else hole_sdf[idx + 1]
			var up     = hole_sdf[idx] if y == 0      else hole_sdf[idx - w]
			var down   = hole_sdf[idx] if y == h - 1  else hole_sdf[idx + w]

			var dx = right - left
			var dy = down - up

			# Normalize gradient — only ONCE at load time
			var grad_len = sqrt(dx * dx + dy * dy)
			if grad_len > 0.0001:
				dx /= grad_len
				dy /= grad_len
			else:
				dx = 0.0
				dy = 0.0

			hole_grad_x[idx] = dx
			hole_grad_y[idx] = dy


func sample_sdf_gradient(pos: Vector2) -> Vector2:
	var local = pos - (hole_global_position - hole_size / 2)
	local.x = clamp(local.x, 0, sdf_size.x - 1)
	local.y = clamp(local.y, 0, sdf_size.y - 1)
	var idx = int(local.y) * int(sdf_size.x) + int(local.x)
	return Vector2(hole_grad_x[idx], hole_grad_y[idx])

func sample_sdf(pos: Vector2) -> float:
	# Convert world pos to local hole image UV
	var local = pos - (hole_global_position - hole_size / 2)
	local.x = clamp(local.x, 0, hole_size.x - 1)
	local.y = clamp(local.y, 0, hole_size.y - 1)
	var idx = int(local.y) * int(sdf_size.x) + int(local.x)
	return hole_sdf[idx]


func constrain_to_hole_mask(p_local: Vector2, index: int) -> Vector2:
	var p_world = to_global(p_local)+root_offset
	var radius = get_segment_half_width(index)
	
	var sdf_value = sample_sdf(p_world)
	if sdf_value >= radius:
		# Approximate gradient
		var grad = sample_sdf_gradient(p_world)
		
		# Move along gradient by (sdf - radius) so the edge fits
		p_world -= grad * (sdf_value - radius)
	
	return to_local(p_world -root_offset)

@export var debug_draw_hole_grid := false
@export var debug_grid_size := 4      # pixel size of each cell
@export var debug_grid_radius := 128   # how far from hole center to scan

func get_segment_half_width(index: int) -> float:
	if not width_curve:
		return line_width * 0.5
	var t = float(index) / float(num__segments)
	return width_curve.sample(t) * 0.5

## Returns target segment lengths for constraint visualization
func get_segment_lengths() -> Array:
	return _segment_lengths
