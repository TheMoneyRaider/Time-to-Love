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
	# --- Determine which axes are locked based on complexity ---
	# Axes unlock in reverse as complexity grows:
	#   body color locks at 2+, tentacle color locks at 4+, frame locks at 6+
	var lock_tent_frame   := complexity_level >= 2
	var lock_tent_color   := complexity_level >= 4
	var lock_body_color   := complexity_level >= 6

	# --- Reserve one exclusive trait for the hiding node ---
	# We always reserve from the first axis that is still free,
	# falling back down the chain so the hiding node always has something.
	# At max complexity (all locked), body color is still the tell —
	# the hiding node gets a different shared color than the decoys.
	var hiding_body_color:   Color
	var hiding_tent_color:   Color
	var hiding_tent_frame:   int
	var decoy_body_colors:   Array
	var decoy_tent_colors:   Array
	var decoy_tent_frames:   Array

	if !lock_tent_frame:
		# Pick hiding body color, give decoys the remaining pool
		hiding_body_color = BODY_COLORS[randi() % BODY_COLORS.size()]
		decoy_body_colors = BODY_COLORS.filter(func(c): return c != hiding_body_color)
		hiding_tent_color = TENTACLE_COLORS[randi() % TENTACLE_COLORS.size()]
		decoy_tent_colors = TENTACLE_COLORS.duplicate()
		hiding_tent_frame = TENTACLE_FRAMES[randi() % TENTACLE_FRAMES.size()]
		decoy_tent_frames = TENTACLE_FRAMES.duplicate()
	elif !lock_tent_color:
		# Tent frame is shared — reserve a tentacle color for hiding node
		hiding_body_color = BODY_COLORS[randi() % BODY_COLORS.size()]
		decoy_body_colors = BODY_COLORS.duplicate()
		hiding_tent_color = TENTACLE_COLORS[randi() % TENTACLE_COLORS.size()]
		decoy_tent_colors = TENTACLE_COLORS.filter(func(c): return c != hiding_tent_color)
		var shared_tent_frame = TENTACLE_FRAMES[randi() % TENTACLE_FRAMES.size()]
		hiding_tent_frame = shared_tent_frame
		decoy_tent_frames = [shared_tent_frame]
	elif !lock_body_color:
		#  tentacle color + tent frame both shared — reserve a body color for the hiding node
		hiding_body_color = BODY_COLORS[randi() % BODY_COLORS.size()]
		decoy_body_colors = BODY_COLORS.filter(func(c): return c != hiding_body_color)
		var shared_tent = TENTACLE_COLORS[randi() % TENTACLE_COLORS.size()]
		hiding_tent_color = shared_tent
		decoy_tent_colors = [shared_tent]
		var shared_tent_frame = TENTACLE_FRAMES[randi() % TENTACLE_FRAMES.size()]
		hiding_tent_frame = shared_tent_frame
		decoy_tent_frames = [shared_tent_frame]
	else:
		# Everything locked — hiding node gets a different shared body color
		var decoy_body = BODY_COLORS[randi() % BODY_COLORS.size()]
		var remaining = BODY_COLORS.filter(func(c): return c != decoy_body)
		hiding_body_color = remaining[randi() % remaining.size()]
		decoy_body_colors = [decoy_body]
		var shared_tent = TENTACLE_COLORS[randi() % TENTACLE_COLORS.size()]
		hiding_tent_color = shared_tent
		decoy_tent_colors = [shared_tent]
		var shared_frame = TENTACLE_FRAMES[randi() % TENTACLE_FRAMES.size()]
		hiding_tent_frame = shared_frame
		decoy_tent_frames = [shared_frame]

	# --- Set hiding node values ---
	_apply_visage(Hiding_Node, hiding_body_color, hiding_tent_color, hiding_tent_frame)

	# --- Set decoy clone values ---
	for node in nodes:
		var b_color: Color
		var t_color: Color
		var t_frame: int

		if lock_body_color:
			b_color = decoy_body_colors[0]
		else:
			b_color = decoy_body_colors[randi() % decoy_body_colors.size()]

		if lock_tent_color:
			t_color = decoy_tent_colors[0]
		else:
			t_color = decoy_tent_colors[randi() % decoy_tent_colors.size()]

		if lock_tent_frame:
			t_frame = decoy_tent_frames[0]
		else:
			t_frame = decoy_tent_frames[randi() % decoy_tent_frames.size()]

		_apply_visage(node, b_color, t_color, t_frame)


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
			
