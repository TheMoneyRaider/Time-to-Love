extends Node2D

const ARM_SCENE = preload("res://Game Elements/Objects/tentacle2.tscn")

# 3 color pairs matching Arm's light_color / dark_color exports
const COLOR_SETS = [
	{ "light": Color("ce7eff"), "dark": Color("bd39ff") },
	{ "light": Color("ff5e60"), "dark": Color("f00032") },
	{ "light": Color("89ffa9"), "dark": Color("00a650") },
]

const ARM_COUNT = 128          # total arms around the perimeter

var arms: Array[Node2D] = []
var targets: Array[Marker2D] = []
var screen_center: Vector2
var vp_size: Vector2
var frame_count: int = 0
var playing: bool = false

func _ready() -> void:
	vp_size = Vector2(480,270)
	screen_center = Vector2.ZERO
func play() -> void:
	playing = true
	_spawn_arms()
	_run_sequence()
	
func _stop_playing():
	playing = false
	queue_free()
	
func get_perimeter_point(t: float) -> Dictionary:
	var W = vp_size.x
	var H = vp_size.y
	var perimeter = 2.0 * (W + H)
	var dist = t * perimeter

	var pos: Vector2

	if dist < W:
		# Top edge, left to right
		pos = Vector2(dist, 0)
	elif dist < W + H:
		# Right edge, top to bottom
		pos = Vector2(W, dist - W)
	elif dist < 2.0 * W + H:
		# Bottom edge, right to left
		pos = Vector2(W - (dist - W - H), H)
	else:
		# Left edge, bottom to top
		pos = Vector2(0, H - (dist - 2.0 * W - H))

	return { "pos": pos-vp_size/2.0, "normal": (pos-vp_size/2.0).normalized() }

const BASE_OFFSCREEN: float = 32.0  # how far the arm base sits outside the edge
const OVERSHOOT = 256.0+128.0       # how far outside screen targets start

func _spawn_arms() -> void:
	for i in range(ARM_COUNT):
		var t_val = float(i) / float(ARM_COUNT)
		var edge = get_perimeter_point(t_val)

		var edge_pos: Vector2 = edge["pos"]
		var outward: Vector2 = edge["normal"]
		var inward: Vector2 = -outward

		var target_marker = Marker2D.new()
		# Use position (local) instead of global_position
		target_marker.position = edge_pos + outward * OVERSHOOT
		add_child(target_marker)
		targets.append(target_marker)

		var arm: Node2D = ARM_SCENE.instantiate()
		arm.uses_sdf = false
		var colors = COLOR_SETS[i % COLOR_SETS.size()]
		arm.light_color = colors["light"]
		arm.dark_color  = colors["dark"]
		arm.max_length = (128.0 + 64.0 * randf()) * edge_pos.length() / 160.0
		arm.num__segments = int(arm.max_length / 128.0 * 24.0)
		$ArmContainer.add_child(arm)

		# Use position (local) instead of global_position
		arm.position = edge_pos + outward * BASE_OFFSCREEN
		arm.rotation = inward.angle()
		arm.target = target_marker
		arms.append(arm)
		arm.visible = false


func _run_sequence() -> void:
	var tween = create_tween().set_parallel(false)

	# Phase 1 — arms reach inward (targets move to center)
	tween.tween_callback(_animate_targets_to_center.bind(2.0))
	tween.tween_interval(3.5)   # wait for IK to fully converge

	# Phase 1.5 — fade everything to white
	tween.tween_callback(_fade_arms_to_white.bind(1.0))
	tween.tween_interval(2.2)
	
	# Phase 3 — text appears
	tween.tween_callback(_show_text.bind(0.01))
	tween.tween_interval(2.5)
#
	# Phase 4 — text fades
	tween.tween_callback(_fade_text_out.bind(0.4))
	tween.tween_interval(0.5)
#
	# Phase 5 — outlines reappear
	tween.tween_callback(_restore_outlines.bind(0.3))
	tween.tween_interval(0.4)
#
	# Phase 6 — targets pull back out, arms retract
	tween.tween_callback(_animate_targets_outward.bind(2.0))
	tween.tween_interval(3.2)
	tween.tween_callback(_stop_playing)
	
# --- Fade to white: modulate the Line2D color + shader params ---
func _fade_arms_to_white(duration: float) -> void:
	var ft = create_tween()
	ft.tween_property($WhiteFlash, "modulate:a", 1.0, duration*5.0/6.0).set_ease(Tween.EASE_IN_OUT)
	var at = create_tween()
	for arm in arms:
		var mat = arm.get_node("SubViewportContainer/SubViewport/TwoToneCanvasGroup").material
		var cur_colA = mat.get_shader_parameter("light_color")
		var cur_colB = mat.get_shader_parameter("dark_color")
		var new_duration = duration *randf() * 2.0/3.0 + duration * 1.0/3.0
		at.parallel().tween_method(
			func(value: Color): mat.set_shader_parameter("light_color", value),
			cur_colA,
			Color(1.0,1.0,1.0,1.0),
			new_duration
		)
		at.parallel().tween_method(
			func(value: Color): mat.set_shader_parameter("dark_color", value),
			cur_colB,
			Color(1.0,1.0,1.0,1.0),
			new_duration
		)

# --- Text ---
func _show_text(duration: float) -> void:
	var t = create_tween()
	t.tween_property($Label, "modulate:a", 1.0, duration).set_ease(Tween.EASE_OUT)

func _fade_text_out(duration: float) -> void:
	var t = create_tween()
	t.tween_property($Label, "modulate:a", 0.0, duration)


# --- Restore outlines only (keep fill white) ---
func _restore_outlines(duration: float) -> void:
	# Lower the white flash so arm outlines show through
	var flash = $WhiteFlash
	var ft = create_tween()
	ft.tween_property(flash, "modulate:a", 0.0, duration)


# --- Open rotation ---
func _start_open_rotation(angle: float, duration: float) -> void:
	for arm in arms:
		var target_rot = arm.rotation - angle
		var t = create_tween()
		t.tween_property(arm, "rotation", target_rot, duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

const TIMING_VARIANCE: float = 1.0  # max random delay in seconds
func _animate_targets_to_center(duration: float) -> void:
	for i in range(targets.size()):
		var target_marker = targets[i]
		var start: Vector2 = target_marker.position  # local

		var edge = get_perimeter_point(float(i) / float(ARM_COUNT))
		var outward: Vector2 = edge["normal"]
		var perp: Vector2 = outward.orthogonal()
		var arc_strength: float = 350.0
		var mid: Vector2 = start.lerp(screen_center, 0.5) + perp * arc_strength
		var delay: float = randf() * TIMING_VARIANCE

		var t = create_tween()
		t.tween_interval(delay)
		t.tween_method(
			func(f: float) -> void:
				var u = 1.0 - f
				target_marker.position = u*u*start + 2.0*u*f*mid + f*f*screen_center,
			0.0, 1.0, duration
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		
		
		
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	for i in range(arms.size()):
		arms[i].visible = true


func _animate_targets_outward(duration: float) -> void:
	var edge_data: Array = []
	for i in range(ARM_COUNT):
		edge_data.append(get_perimeter_point(float(i) / float(ARM_COUNT)))

	for i in range(targets.size()):
		var outward: Vector2 = edge_data[i]["normal"]
		var edge_pos: Vector2 = edge_data[i]["pos"]
		var end_pos: Vector2 = edge_pos + outward * OVERSHOOT
		var start: Vector2 = targets[i].position  # local

		var perp: Vector2 = outward.orthogonal()
		var arc_strength: float = 350.0
		var mid: Vector2 = start.lerp(end_pos, 0.5) + perp * arc_strength

		var marker = targets[i]
		var delay: float = randf() * TIMING_VARIANCE
		var t = create_tween()
		t.tween_interval(delay)
		t.tween_method(
			func(f: float) -> void:
				var u = 1.0 - f
				marker.position = u*u*start + 2.0*u*f*mid + f*f*end_pos,
			0.0, 1.0, duration
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
