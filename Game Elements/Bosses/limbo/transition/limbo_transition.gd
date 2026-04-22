extends Node2D

const ARM_SCENE = preload("res://Game Elements/Objects/tentacle.tscn")

# 3 color pairs matching Arm's light_color / dark_color exports
const COLOR_SETS = [
	{ "light": Color("ce7eff"), "dark": Color("bd39ff") },
	{ "light": Color("ff5e60"), "dark": Color("f00032") },
	{ "light": Color("89ffa9"), "dark": Color("00a650") },
]

const ARM_COUNT = 128          # total arms around the perimeter
const OVERSHOOT = 200.0       # how far outside screen targets start

var arms: Array[Node2D] = []
var targets: Array[Marker2D] = []
var screen_center: Vector2
var vp_size: Vector2

func _ready() -> void:
	vp_size = Vector2(1920/4,1080/4)
	screen_center = Vector2.ZERO
	_spawn_arms()
	_run_sequence()

func get_perimeter_point(t: float) -> Dictionary:
	var W = vp_size.x
	var H = vp_size.y
	var perimeter = 2.0 * (W + H)
	var dist = t * perimeter

	var pos: Vector2
	var normal: Vector2  # points OUTWARD from screen

	if dist < W:
		# Top edge, left to right
		pos = Vector2(dist, 0)
		normal = Vector2(0, -1)
	elif dist < W + H:
		# Right edge, top to bottom
		pos = Vector2(W, dist - W)
		normal = Vector2(1, 0)
	elif dist < 2.0 * W + H:
		# Bottom edge, right to left
		pos = Vector2(W - (dist - W - H), H)
		normal = Vector2(0, 1)
	else:
		# Left edge, bottom to top
		pos = Vector2(0, H - (dist - 2.0 * W - H))
		normal = Vector2(-1, 0)

	return { "pos": pos-vp_size/2.0, "normal": normal }


func _spawn_arms() -> void:
	for i in range(ARM_COUNT):
		var t_val = float(i) / float(ARM_COUNT)
		var edge = get_perimeter_point(t_val)

		var edge_pos: Vector2 = edge["pos"]
		var outward: Vector2 = edge["normal"]
		var inward: Vector2 = -outward

		# --- Spawn the Marker2D target ---
		var target_marker = Marker2D.new()
		# Start position: outside the screen along the outward normal
		target_marker.global_position = edge_pos + outward * OVERSHOOT
		add_child(target_marker)
		targets.append(target_marker)

		# --- Spawn the Arm ---
		var arm: Node2D = ARM_SCENE.instantiate()
		arm.uses_sdf=false
		# Assign colors cycling through 3 sets
		var colors = COLOR_SETS[i % COLOR_SETS.size()]
		arm.light_color = colors["light"]
		arm.dark_color  = colors["dark"]
		$ArmContainer.add_child(arm)

		arm.global_position = edge_pos

		# Rotate arm so its local X axis points inward
		arm.rotation = inward.angle()

		#arm.get_node("SubViewportContainer").material.enabled_hole = false

		# Assign the live target — IK will track it every physics frame
		arm.target = target_marker
		arms.append(arm)


func _run_sequence() -> void:
	var tween = create_tween().set_parallel(false)

	# Phase 1 — arms reach inward (targets move to center)
	tween.tween_callback(_animate_targets_to_center.bind(1.4))
	tween.tween_interval(1.6)   # wait for IK to fully converge

	# Phase 2 — fade everything to white
	tween.tween_callback(_fade_to_white.bind(0.6))
	tween.tween_interval(0.7)

	# Phase 3 — text appears
	tween.tween_callback(_show_text.bind(0.4))
	tween.tween_interval(2.5)

	# Phase 4 — text fades
	tween.tween_callback(_fade_text_out.bind(0.4))
	tween.tween_interval(0.5)

	# Phase 5 — outlines reappear
	tween.tween_callback(_restore_outlines.bind(0.3))
	tween.tween_interval(0.4)

	# Phase 6 — targets pull back out, arms retract
	tween.tween_callback(_animate_targets_outward.bind(1.0))
	tween.tween_interval(1.2)
	
	

# --- Fade to white: modulate the Line2D color + shader params ---
func _fade_to_white(duration: float) -> void:
	var ft = create_tween()
	ft.tween_property($WhiteFlash, "modulate:a", 1.0, duration).set_ease(Tween.EASE_IN_OUT)

	# Fade each arm's Line2D to white
	for arm in arms:
		var line: Line2D = arm.base_node
		var at = create_tween()
		at.tween_property(line, "default_color", Color.WHITE, duration)


# --- Text ---
func _show_text(duration: float) -> void:
	var label = $Label
	label.modulate.a = 0.0
	label.visible = true
	var t = create_tween()
	t.tween_property(label, "modulate:a", 1.0, duration).set_ease(Tween.EASE_OUT)

func _fade_text_out(duration: float) -> void:
	var label = $TextLayer/Label
	var t = create_tween()
	t.tween_property(label, "modulate:a", 0.0, duration)


# --- Restore outlines only (keep fill white) ---
func _restore_outlines(duration: float) -> void:
	# Lower the white flash so arm outlines show through
	var flash = $WhiteFlash
	var ft = create_tween()
	ft.tween_property(flash, "color:a", 0.0, duration)


# --- Open rotation ---
func _start_open_rotation(angle: float, duration: float) -> void:
	for arm in arms:
		var target_rot = arm.rotation - angle
		var t = create_tween()
		t.tween_property(arm, "rotation", target_rot, duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _animate_targets_to_center(duration: float) -> void:
	for i in range(targets.size()):
		var target_marker = targets[i]
		var t = create_tween()
		t.tween_property(
			target_marker,
			"global_position",
			screen_center,
			duration
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _animate_targets_outward(duration: float) -> void:
	var edge_data: Array = []
	for i in range(ARM_COUNT):
		edge_data.append(get_perimeter_point(float(i) / float(ARM_COUNT)))

	for i in range(targets.size()):
		var outward: Vector2 = edge_data[i]["normal"]
		var edge_pos: Vector2 = edge_data[i]["pos"]
		var end_pos = edge_pos + outward * OVERSHOOT

		var t = create_tween()
		t.tween_property(
			targets[i],
			"global_position",
			end_pos,
			duration
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
