extends SubViewportContainer

@export var power_speed := 500.0       # pixels per second for powering up
@export var decay_speed := 800.0       # pixels per second for powering down

var powering_distance := 0.0        # 0–1 (power up)
var powering_down_distance := -1.0   # 0–1 (power down)
var active := false

@onready var laser_attack : Node
@onready var line = $SubViewport/LaserBeam
@onready var light = $Light

var point1  = Vector2.ZERO
var point2  = Vector2.ZERO

func update_points(from_point : Vector2, to_point : Vector2):
	# Save previous total distance and powered fraction
	var old_distance = point1.distance_to(point2)
	var powered_fraction = 0.0
	if old_distance > 0:
		powered_fraction = powering_distance / old_distance

	var powered_down_fraction = 0.0
	if old_distance > 0 and powering_down_distance >= 0:
		powered_down_fraction = powering_down_distance / old_distance

	# Update points
	point1 = from_point
	point2 = to_point
	var new_distance = point1.distance_to(point2)

	# Update powering distances proportionally to new distance
	powering_distance = powered_fraction * new_distance
	if powering_down_distance >= 0:
		powering_down_distance = powered_down_fraction * new_distance

func fire_laser(from_point : Vector2, to_point : Vector2,node : Node):
	point1 = from_point
	point2 = to_point
	active = true
	powering_distance = 0.0
	powering_down_distance = -1.0
	line.clear_points()
	light.scale.y = .25
	
	var instance = load("res://Game Elements/Attacks/laser.tscn").instantiate()
	instance.c_owner = node
	get_parent().add_child(instance)
	laser_attack = instance
	laser_attack.deflectable = false
	laser_attack.i_frames = 4
	var new_shape = RectangleShape2D.new()
	new_shape.size.x = 0
	laser_attack.get_child(0).shape = new_shape
	laser_attack.get_child(0).shape.size.y = 8

func kill():
	powering_down_distance = 0.0
	laser_attack.queue_free()

func _process(delta):
	if !active:
		return

	var total_distance = point1.distance_to(point2)

		# Powering up
	if powering_distance < total_distance:
		powering_distance += power_speed * delta
		powering_distance = min(powering_distance, total_distance)

	# Powering down
	if powering_down_distance >= 0.0:
		powering_down_distance += decay_speed * delta
		if powering_down_distance > total_distance:
			if laser_attack:
				laser_attack.queue_free()
			queue_free()
			return


	# Compute effective powered distance
	var powered_length := powering_distance
	var start_pos : Vector2= point1
	var end_pos : Vector2= point1 + (point2 - point1).normalized() * powered_length

	
	var sparks = preload("res://Game Elements/Particles/sparks.tscn").instantiate()
	sparks.range_choice = 1
	get_parent().add_child(sparks)
	sparks.global_position = point2
	
	if powering_down_distance > 0.0:
		powered_length = total_distance - powering_down_distance
		start_pos = point2 - (point2 - point1).normalized() * powered_length
		end_pos = point2

	# Update line points
	line.clear_points()
	line.add_point(start_pos + size/2 - point1)
	line.add_point(end_pos + size/2 - point1)
	if laser_attack:
		# Update laser_attack position
		laser_attack.global_position = (start_pos + end_pos) / 2.0

		# Update laser shape
		laser_attack.get_child(0).shape.size.x = powered_length
		laser_attack.rotation = (point2 - point1).angle()

	# Update light
	light.global_position = (start_pos + end_pos) / 2.0
	light.rotation = (point2 - point1).angle()
	light.scale.x = (powered_length / 256) * 1.25
