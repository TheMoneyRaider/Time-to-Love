extends Node2D

var trap_cells := []
var blocked_cells := []
var liquid_cells : Array[Array]= [[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[]]

var camera : Node = null
var player1 : Node = null
var player2 : Node = null
var LayerManager : Node = null
var Hud : Node = null
var screen : Node = null
var active : bool = false
var is_multiplayer : bool = false

@export var boss_splash_art : Texture2D
@export var healthbar_underlays : Array[Texture2D]
@export var healthbar_overlays : Array[Texture2D]
@export var boss_names : Array[String]
@export var boss_name_settings : Array[LabelSettings]
@export var boss : Node
@export var boss_name : String
@export var boss_font : Font
#This is what values the bossbar shader is looking for
@export var phase_overlay_index : Array[int]
@export var boss_type : String =""
var animation : String = ""

@export var rocks : Array[Node]

var Hiding_Node : Node = null
var hiding_node_position : Vector2
var hiding : bool = false

func activate():
	LayerManager = get_tree().get_root().get_node("LayerManager")
	player1 = LayerManager.player1
	player2 = LayerManager.player2
	player1.move_speed *= 2.0
	if is_multiplayer:
		player2.move_speed *= 2.0
	is_multiplayer = LayerManager.is_multiplayer
	Hud =LayerManager.hud
	print("boss room activate")
	Hud.show_boss_bar(healthbar_underlays[0],healthbar_overlays[0],boss_names[0],boss_name_settings[0],phase_overlay_index[0])
	Hud.update_bossbar(1.0)
	Hud.update_bossbar2(0.0)
	Hud.get_node("RootControl/VBoxContainer/HorizontalSlice/TimeFabric").visible = false
	
	await get_tree().create_timer(7.0, false).timeout
	active = true
	
var ability_progress = 0.0
func _process(delta: float) -> void:
	if !active:
		return
	if !hiding:
		ability_progress+=delta/4.0
	if hiding:
		if !Hiding_Node:
			reveal_boss()
		else:
			hiding_node_position = Hiding_Node.global_position
		ability_progress-=delta/4.0
	ability_progress = clamp(ability_progress,0.0,1.0)
	Hud.update_bossbar2(ability_progress)
	
	if ability_progress >= 1.0 and !hiding:
		hide_boss()
	if ability_progress <= 0.0 and hiding:
		reveal_boss()
	
	

var complexity_level : int = 0

func hide_boss():
	hiding = true
	var inst
	var tiles = get_node("Ground").get_used_cells()
	var index = randi() % 20
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	boss.hitable = false
	boss.get_node("Area2D").push_strength = 0.0
	
	# Pre-calculate targets and distances
	var targets = []
	var travel_times = []
	for i in range(0, 21):
		var target = Vector2(tiles[randi() % tiles.size()]) * Vector2(16.0, 16.0)
		targets.append(target)
		var dist = (boss.global_position - target).length()
		travel_times.append(3.0 / 700 * dist)
	
	# Find the longest travel time so all clones arrive together
	var max_travel_time = travel_times.max()
	var clones : Array[Node]= []
	for i in range(0, 21):
		inst = load("res://Game Elements/Characters/vision_clone.tscn").instantiate()
		inst.global_position = boss.global_position
		inst.enemy_took_damage.connect(LayerManager._on_enemy_take_damage)
		if i == index:
			Hiding_Node = inst
		else:
			clones.append(inst)
		
		add_child(inst)
		
		# Delay = difference between max time and this clone's travel time
		var wait_time = max_travel_time - travel_times[i]
		var tween = inst.create_tween()
		tween.tween_interval(wait_time)
		tween.tween_property(inst, "global_position", targets[i], travel_times[i])
		var arrived_inst = inst
		inst.get_node("Area2D").push_strength = 0.0
		inst.get_node("BTPlayer").active = true
		tween.tween_callback(func():
			if on_clone_arrived.is_valid():
				on_clone_arrived.call(arrived_inst)
		)
	
	var tween2 = create_tween()
	tween2.parallel().tween_property(boss, "modulate:a", 0.0, 2.0)
	tween2.parallel().tween_property(boss, "scale", Vector2(.5, .5), 2.0)
	complexity_level+=1
	_set_clone_visage(clones)



const BODY_COLORS := [
	Color(0.557, 0.382, 0.0, 1.0),   # Gold
	Color("2933e1"),    # Blue
	Color("f00032"),    # Red
	Color("00a650"),    # Green
	Color("bd39ff"),    # Purple
]
const TENTACLE_COLORS := [
	Color(1.0, 1.0, 1.0),    # White
	Color("ff5e60"),    # Red
	Color("89ffa9"),    # Green
	Color("ce7eff"),    # Purple
]
const TENTACLE_FRAMES := [0, 1, 2]

func _set_clone_visage(nodes: Array[Node]) -> void:
	# Chaos shrinks from 1.0 → 0.0 as complexity rises.
	# Each trait axis has a threshold below which it locks.
	# Frame locks first (cheapest), then tent color, then body color.
	var chaos : float= 1.0 - clamp(complexity_level / 10.0, 0.0, 1.0)
	var frame_free  := chaos > 0.15
	var tent_free   := chaos > 0.40
	var body_free   := chaos > 0.65

	# Build the pool of axes that are still free.
	# The hiding node's distinguishing axis is picked from free axes,
	# weighted toward whichever is cheapest (frame > tent > body).
	# If nothing is free, body color is always the fallback.
	var free_axes: Array[String] = []
	if frame_free: free_axes.append("frame")
	if tent_free:  free_axes.append("tent")
	if body_free:  free_axes.append("body")

	var distinct_axis: String
	if free_axes.is_empty():
		# All locked — pick randomly among all three so body isn't always the tell
		var all_axes: Array[String] = ["frame", "tent", "body"]
		distinct_axis = all_axes[randi() % all_axes.size()]
	else:
		# Weight toward cheapest free axis: frame=3, tent=2, body=1
		var weights := {"frame": 3, "tent": 2, "body": 1}
		var pool: Array[String] = []
		for axis in free_axes:
			for _w in range(weights[axis]):
				pool.append(axis)
		distinct_axis = pool[randi() % pool.size()]

	# --- Pick shared/decoy values for each axis ---
	var shared_body  : Color= BODY_COLORS[randi() % BODY_COLORS.size()]
	var shared_tent  : Color= TENTACLE_COLORS[randi() % TENTACLE_COLORS.size()]
	var shared_frame : int= TENTACLE_FRAMES[randi() % TENTACLE_FRAMES.size()]

	# --- Derive hiding node's exclusive value on the distinct axis ---
	var hiding_body  := shared_body
	var hiding_tent  := shared_tent
	var hiding_frame := shared_frame
	var decoy_bodies := [shared_body] if !body_free else BODY_COLORS.duplicate()
	var decoy_tents  := [shared_tent] if !tent_free else TENTACLE_COLORS.duplicate()
	var decoy_frames := [shared_frame] if !frame_free else TENTACLE_FRAMES.duplicate()

	match distinct_axis:
		"body":
			var remaining_bodies := BODY_COLORS.filter(func(c): return c != shared_body)
			hiding_body = remaining_bodies[randi() % remaining_bodies.size()]
			# Decoys cannot use hiding_body
			decoy_bodies = BODY_COLORS.filter(func(c): return c != hiding_body) if body_free else [shared_body]
		"tent":
			var remaining_tents := TENTACLE_COLORS.filter(func(c): return c != shared_tent)
			hiding_tent = remaining_tents[randi() % remaining_tents.size()]
			decoy_tents = TENTACLE_COLORS.filter(func(c): return c != hiding_tent) if tent_free else [shared_tent]
		"frame":
			var remaining_frames := TENTACLE_FRAMES.filter(func(f): return f != shared_frame)
			hiding_frame = remaining_frames[randi() % remaining_frames.size()]
			decoy_frames = TENTACLE_FRAMES.filter(func(f): return f != hiding_frame) if frame_free else [shared_frame]

	# --- Apply to hiding node ---
	_apply_visage(Hiding_Node, hiding_body, hiding_tent, hiding_frame)

	# --- Apply to decoys with per-axis chaos roll ---
	for node in nodes:
		# Each axis independently rolls whether it uses its shared value
		# or picks freely from the decoy pool. Higher chaos = more variance.
		var b: Color
		var t: Color
		var f: int

		if body_free and randf() < chaos:
			b = decoy_bodies[randi() % decoy_bodies.size()]
		else:
			b = decoy_bodies[0]

		if tent_free and randf() < chaos:
			t = decoy_tents[randi() % decoy_tents.size()]
		else:
			t = decoy_tents[0]

		if frame_free and randf() < chaos:
			f = decoy_frames[randi() % decoy_frames.size()]
		else:
			f = decoy_frames[0]

		_apply_visage(node, b, t, f)


func _apply_visage(node: Node, body_color: Color, tent_color: Color, tent_frame: int) -> void:
	var sprite := node.get_node("Sprite2D") as Sprite2D
	var tentacle := sprite.get_node("Sprite2D") as Sprite2D
	sprite.modulate = body_color
	tentacle.modulate = tent_color
	tentacle.frame = tent_frame


func on_clone_arrived(clone: Node):
	clone.get_node("Area2D").push_strength = 1.0
	
	await get_tree().create_timer(randf() * float(randi() % 3)).timeout
	if clone:
		clone.get_node("BTPlayer").active = true

func reveal_boss():
	var tween = create_tween()
	tween.parallel().tween_property(boss, "modulate:a", 1.0, .5)
	tween.parallel().tween_property(boss, "scale", Vector2(1.0,1.0), .5)
	boss.hitable = true
	boss.get_node("Area2D").push_strength = 1.0
	boss.global_position = hiding_node_position
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if "is_boss" in enemy and !enemy.is_boss:
			var tween2 = enemy.create_tween()
			tween2.parallel().tween_property(enemy, "global_position", boss.global_position, 2.0 / 700 * (boss.global_position-enemy.global_position).length())
			tween2.parallel().tween_property(enemy, "modulate:a", 0.0, 1.0)
	
	await get_tree().create_timer(.5).timeout
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if "is_boss" in enemy and !enemy.is_boss:
			enemy.queue_free()
	hiding = false
	boss.process_mode = Node.PROCESS_MODE_PAUSABLE
			
