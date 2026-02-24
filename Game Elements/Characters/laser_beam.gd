extends Line2D

@export var power_curve : Curve      # organic fade in/out
@export var power_time := 0.75        # seconds to fully charge
@export var decay_time := 0.75        # seconds to fully turn off

@export var laser_width := 8.0
var light_width : float = (16.0/256)*5
@export var color := Color(1, 0, 0)


var powering := 0.0        # 0–1 (power up)
var powering_down := 0.0   # 0–1 (power down)
var active := false

var laser_attack : Node



func _ready():
	default_color = color
	hide_laser()


func fire_laser(from_point : Vector2, to_point : Vector2, y_axis : bool):
	var laser_enemy = get_parent().get_parent().get_parent()
	clear_points()
	if y_axis:
		add_point(from_point-get_parent().get_parent().position+Vector2(0,3))
		add_point(to_point-get_parent().get_parent().position+Vector2(0,-3))
	else:
		add_point(from_point-get_parent().get_parent().position+Vector2(3,0))
		add_point(to_point-get_parent().get_parent().position+Vector2(-3,0))
	active = true
	powering = 0.0
	powering_down = -1.0
	show_laser()
	var global_pos_1 = laser_enemy.to_global(from_point)
	var global_pos_2 = laser_enemy.to_global(to_point)
	var instance = load("res://Game Elements/Attacks/laser.tscn").instantiate()
	instance.c_owner = laser_enemy
	laser_attack = instance
	laser_attack.global_position = (global_pos_1+global_pos_2)/2.0
	laser_enemy.get_node("Light").global_position = (global_pos_1+global_pos_2)/2.0
	var new_shape = RectangleShape2D.new()
	if y_axis:
		new_shape.size.y = 8
		new_shape.size.x = (global_pos_2.y-global_pos_1.y)
		laser_enemy.get_node("Light").scale.y =  ((global_pos_2.y-global_pos_1.y)/256)*1.25
		laser_enemy.get_node("Light").rotation = deg_to_rad(0)
	else:
		new_shape.size.x = 8
		new_shape.size.y = (global_pos_2.x-global_pos_1.x)
		laser_enemy.get_node("Light").scale.y =  ((global_pos_2.x-global_pos_1.x)/256)*1.25
		laser_enemy.get_node("Light").rotation = deg_to_rad(90)
	laser_attack.get_child(0).shape = new_shape
	get_tree().get_root().get_node("LayerManager").room_instance.add_child(instance)

func stop_laser():
	powering_down = 0.0
	laser_attack.queue_free()

func _process(delta):
	if !active:
		return

	# Powering up
	if powering < 1.0:
		powering += delta / power_time
		powering = min(powering, 1.0)
	# idle until stop_laser() is called
	if powering >= 1.0 and powering_down < 0.0:
		pass
	# Powering down
	if powering_down >= 0.0:
		powering_down += delta / decay_time
		if powering_down > 1.0:
			hide_laser()
			active = false
			return

	# Final power factor (organic)
	var p := powering
	if powering_down > 0.0:
		p = 1.0 - powering_down

	p = power_curve.sample(p)  # organic shaping

	width=(p*laser_width)
	get_parent().get_parent().get_parent().get_node("Light").scale.x = (p*light_width)


func show_laser():
	visible = true
	get_parent().get_parent().get_parent().get_node("Light").visible = true
func hide_laser():
	visible = false
	get_parent().get_parent().get_parent().get_node("Light").visible = false
