extends Node2D

# ============================================================
# CONFIGURATION
# ============================================================
var GlyphLabel = preload("res://Game Elements/Objects/binary_character.tscn")

####Melee Paramters
# Melee attack states
enum MeleePhase { NONE, SHRINK, LUNGE, DECEL, EXPAND }

var melee_phase : int = MeleePhase.NONE
var melee_timer : float = 0.0
var melee_duration : float = 0.25
var tracked_player_pos : Vector2
var lunge_velocity : Vector2 = Vector2.ZERO
var target_vector : Vector2 = Vector2.ZERO
var friction : float = 10.0
var track_strength := 6.0
var melee_tween : Tween


####Physics parameters
@export var spring_strength := 1000.0      # pulls each glyph toward the core center
@export var damping := 10.0               # slows velocity
@export var repulsion_force := 2000.0    # prevents collapsing
@export var repulsion_radius := 18.0     # min distance between characters
var particles = []   # Each entry: { label, pos, vel }
var attack_direct = 1
@export var mono_font: Font
var last_position : Vector2
# Characters 
@export var core_char_count := 36
@export var segment_char_count := 4   # chars per leg segment
@export var glyph_choices := "10"
@export var damage_glyph_choices := "@#%*&?"

# Visual jitter
@export var jitter_strength := 3.0
var tracked_player : Node = null
var tracked_wave : Node = null
@export var damage_noise : NoiseTexture2D
var noise_offset : Vector2


# Internal
var attack_cooldown := 0.0

func _ready():
	noise_offset = Vector2(randf_range(-300,300),randf_range(-300,300))
	get_node("../Attack").c_owner = get_parent()
	get_node("../Attack/CollisionShape2D").disabled=true
	get_node("../CollisionShape2D").disabled=true
	last_position = global_position
	var instance = load("res://Game Elements/Rooms/sci_fi/binary_string.tscn").instantiate()
	instance.position = Vector2(-640, 0)
	instance.min_length = core_char_count
	instance.max_length = core_char_count
	add_child(instance)
	tracked_wave = instance
	tracked_wave.z_index += 20 


# CHARACTER SPAWNING
func _random_glyph() -> String:
	return glyph_choices[randi() % glyph_choices.length()]


func change_color(label_to_change : Label, time_step : float, og_color : Color, new_color : Color, lum : float):
	var time = clamp(time_step,0.0,1.0)
	# Convert to HSV
	var h = og_color.h
	var s = og_color.s
	var v = clamp(og_color.v + lum, 0.0, 1.0)
	var base_color = Color.from_hsv(h, s, v, og_color.a)
	h = new_color.h
	s = new_color.s
	v = clamp(new_color.v + lum, 0.0, 1.0)
	var roof_color = Color.from_hsv(h, s, v, new_color.a)
	var time_color = lerp(base_color,roof_color,time)
	label_to_change.add_theme_color_override("font_color", time_color)

func _make_char_label(parent : Node) -> Label:
	var lbl: Label = GlyphLabel.instantiate()
	var glyph = _random_glyph()
	lbl.set_character_data(glyph)
	parent.add_child(lbl)
	lbl.position = Vector2(0,0)
	return lbl

# PROCESS LOOP
func _process(delta):
	var bt_player = get_node("../BTPlayer")
	var board = bt_player.blackboard
	if board:
		var attack_mode = board.get_var("attack_mode")
		if attack_mode == "SPAWNING":
			if !tracked_wave:
				board.set_var("attack_mode","MELEE")
				get_parent().get_node("CollisionShape2D").disabled=false
			else:
				var labels = tracked_wave.glyphs
				for lbl in labels:
					if lbl.global_position.distance_to(global_position) < 12 or lbl.global_position.x > global_position.x:
						var temp_position = lbl.global_position + Vector2(0,randf_range(-5,5))
						lbl.get_parent().glyphs.erase(lbl)
						lbl.get_parent().remove_child(lbl)
						add_child(lbl)
						lbl.global_position = temp_position
						particles.append({
							"label": lbl,
							"pos": lbl.position,
							"vel": Vector2.ZERO
						})

		var attack_status = board.get_var("attack_status")
		if attack_status == " STARTING" and attack_mode == "MELEE":
			board.set_var("attack_status"," RUNNING")
			_start_melee_attack()
		if melee_phase != MeleePhase.NONE:
			_process_melee_attack(delta)
			if attack_mode != "MELEE":
				melee_phase=MeleePhase.NONE
		
	attack_cooldown = max(0.0, attack_cooldown - delta)

	_update_physics(delta)
	#_process_leg_ik(delta)

func _return_glyph_locations() -> Array[Vector2]:
	var locations: Array[Vector2] = []
	for p in particles:
		var label: Label = p["label"]
		if is_instance_valid(label):
			locations.append(label.global_position)

	return locations
	
func _change_glyph_colors(color : Color, time : float, delay : float):
	for p in particles:
		var label: Label = p["label"]
		if is_instance_valid(label):
			label._change_color(color, time, delay)
	

func _deflect_melee_attack():
	attack_direct = -1

func _get_player_position() -> Vector2:
	var players = get_tree().get_nodes_in_group("player")
	var positions_array = []
	for player in players: 
		positions_array.append(player.global_position)

	var board = get_node("../BTPlayer").blackboard
	
	tracked_player =players[board.get_var("player_idx")]
	return positions_array[board.get_var("player_idx")]

func _start_melee_attack():
	if melee_phase != MeleePhase.NONE:
		return # already attacking

	tracked_player_pos = _get_player_position()
	attack_direct = 1
	attack_cooldown = 1.2
	melee_phase = MeleePhase.SHRINK
	melee_timer = 0.0

	melee_tween = create_tween()
	melee_tween.tween_property(self, "repulsion_force", repulsion_force / 8.0, 0.5)
	_change_glyph_colors(Color(0.487, 0.496, 0.157, 1.0), 0.5, 0.0)

func _process_melee_attack(delta):
	if not is_instance_valid(tracked_player):
		melee_phase = MeleePhase.NONE
		var board = get_node("../BTPlayer").blackboard
		if is_instance_valid(board):
			board.set_var("attack_status", " DONE")
		return

	match melee_phase:
		MeleePhase.SHRINK:
			# Track the player
			tracked_player_pos = tracked_player_pos.lerp(
				tracked_player.global_position,
				1.0 - exp(-track_strength * delta)
			)

			# Wait for tween to finish
			if !melee_tween.is_running():
				melee_phase = MeleePhase.LUNGE
				melee_timer = 0.0
				get_node("../Attack/CollisionShape2D").disabled = false

		MeleePhase.LUNGE:
			# Compute target on first frame
			if melee_timer == 0.0:
				var movement_vector = tracked_player_pos - global_position
				if movement_vector.length() < 32:
					movement_vector = movement_vector.normalized() * 32
				target_vector = movement_vector.normalized() * clamp(movement_vector.length() * 1.5,0,30)
				_change_glyph_colors(Color(0.743, 0.247, 0.148, 1.0), 0.125, 0.0)

			melee_timer += delta
			var t = delta / melee_duration
			lunge_velocity = target_vector * t * attack_direct * 60
			get_parent().apply_velocity(lunge_velocity)

			if melee_timer >= melee_duration:
				melee_phase = MeleePhase.DECEL

		MeleePhase.DECEL:
			lunge_velocity = lunge_velocity.move_toward(Vector2.ZERO, friction * delta * 100)
			get_parent().apply_velocity(lunge_velocity)
			if lunge_velocity.length() <= 5.0:
				var board = get_node("../BTPlayer").blackboard
				board.set_var("attack_status"," FINISHING")
				get_parent().apply_velocity(Vector2.ZERO)
				get_node("../Attack/CollisionShape2D").disabled = true
				melee_phase = MeleePhase.EXPAND
				melee_timer = -randf_range(0,2)
				_change_glyph_colors(Color(0.0, 0.373, 0.067, 1.0), 2.0, 0.0)
				melee_tween = create_tween()
				melee_tween.tween_property(self, "repulsion_force", repulsion_force * 8.0, 1.0)
		MeleePhase.EXPAND:
				
			
			melee_timer += delta
			# Wait 3 seconds then finish
			if melee_timer >= 3.0:
				var board = get_node("../BTPlayer").blackboard
				if is_instance_valid(board):
					board.set_var("attack_status", " DONE")
				melee_phase = MeleePhase.NONE

func damage_glyphs():
	var delay
	var n_scale = 1000
	var time_step = .5
	for p in particles:
		var label: Label = p["label"]
		if is_instance_valid(label):
			delay = damage_noise.noise.get_noise_2d(label.global_position.x*n_scale, label.global_position.y*n_scale) * 0.5 + 0.5
			label._change_char(damage_glyph_choices[randi() % damage_glyph_choices.length()], delay* time_step)
			label._change_char(glyph_choices[randi() % glyph_choices.length()], delay* time_step+2*time_step)

func _update_physics(delta):
	var internal_delta = min(delta,0.01666666666)
	#return
	var pos_difference = last_position - global_position
	last_position = global_position
	var center = Vector2.ZERO   # relative to parent

	# --- First, compute forces for each particle ---
	for i in range(particles.size()):
		var p = particles[i]
		var pos = p.pos + pos_difference
		var vel = p.vel

		# 1) Spring toward center
		var to_center = (center - pos)
		var force = to_center * spring_strength

		# 2) Repulsion from other particles
		for j in range(particles.size()):
			if i == j:
				continue
			var other = particles[j]
			var offset = pos - other.pos
			var dist = offset.length()
			if dist > 0 and dist < repulsion_radius:
				var push = (repulsion_radius - dist) / repulsion_radius
				force += offset.normalized() * repulsion_force * push

		# 3) Damping
		force -= vel * damping

		# 4) Integrate motion
		vel += force * internal_delta
		pos += vel * internal_delta

		# Store updated
		p.pos = pos
		p.vel = vel

	# --- Update visual label positions ---
	for p in particles:
		p["label"].position = p.pos
