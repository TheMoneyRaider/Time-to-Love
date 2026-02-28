extends BTAction
class_name LaserAttack

var started : bool = false
var laser_out : bool = false
var valid : bool = true
var time : float = 0.0
var opening_time : float =1.0
var closing_time : float =1.0
var min_time : float =4.0
var max_time : float =6.0
var min_cool : float =1
var max_cool : float =1.6
var total_time : float =5.0
var y_axis : bool = false
var killed : bool = false
var first_time : bool = true

var killed_damage : int
var killed_direction : Vector2



func cast_axis_ray(origin: Vector2, direction: Vector2, distance: float) -> Dictionary:
	var space = agent.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(origin - direction, origin + direction * distance)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 1 << 0
	return space.intersect_ray(query)


func kill(damage : int, direction : Vector2) -> void:
	killed = true
	killed_damage = damage
	killed_direction = direction
	time = total_time-closing_time
	agent.current_health -= damage
	
func die():
	agent.emit_signal("enemy_took_damage",killed_damage,agent.current_health,agent,killed_direction)

func start()->void:
	randomize()
	total_time = randf_range(min_time,max_time)
	started = true
	var valid_X = false
	var valid_Y = false
	var check_right = cast_axis_ray(agent.global_position, Vector2.RIGHT, 1600)
	var check_left = cast_axis_ray(agent.global_position, Vector2.LEFT, 1600)
	var check_up = cast_axis_ray(agent.global_position, Vector2.UP, 1600)
	var check_down = cast_axis_ray(agent.global_position, Vector2.DOWN, 1600)
	
	##REMOVE UNVALID LOCATIONS THAT HAVE OTHER LASER SPOTS
	for node in agent.get_tree().get_nodes_in_group("enemy"):
		if node.name=="Segment1" or node.name=="Segment2":
			if check_right:
				if node.global_position.distance_to(check_right.position) < 8:
					check_right = null
			if check_left:
				if node.global_position.distance_to(check_left.position) < 8:
					check_left = null
			if check_up:
				if node.global_position.distance_to(check_up.position) < 8:
					check_up = null
			if check_down:
				if node.global_position.distance_to(check_down.position) < 8:
					check_down = null
	##
	if check_right and check_left:
		valid_X = true
	if check_up and check_down:
		valid_Y = true
	if !valid_X and !valid_Y:
		valid=false
		return
		
	var choice = 0
		
	if valid_X and !valid_Y:
		choice = 1
	if !valid_X and valid_Y:
		choice = 2
	if choice ==0:
		randomize()
		choice = randi()%2+1
	var seg1 = agent.get_node("Segment1")
	var seg2 = agent.get_node("Segment2")
	match choice:
		0:
			pass
		1:
			seg2.global_position = check_right.position
			seg1.global_position = check_left.position
			seg2.rotation = deg_to_rad(180)
			seg1.rotation = deg_to_rad(0)
		2:
			y_axis = true
			seg1.global_position = check_up.position
			seg2.global_position = check_down.position
			seg1.rotation = deg_to_rad(90)
			seg2.rotation = deg_to_rad(-90)

func _tick(delta: float) -> Status:
	if first_time:   #Added so they don't all fire simultaniously. Maybe keep?
		first_time=false
		agent.weapon_cooldowns[0] = randf_range(min_cool/3, max_cool/3)
		return proc_finish(FAILURE)
		
	if blackboard.get_var("kill_laser") and !killed:
		kill(blackboard.get_var("kill_damage"), blackboard.get_var("kill_direction"))
	if !started:
		if agent.weapon_cooldowns[0] > 0.0:
			return FAILURE
		start()
		if !valid:
			return proc_finish(FAILURE)
	time+=delta
	var seg1 = agent.get_node("Segment1")
	var seg2 = agent.get_node("Segment2")
	if time < opening_time:
		seg1.modulate.a = lerp(0,1,time)
		seg2.modulate.a = lerp(0,1,time)
	if !laser_out and time >= opening_time-agent.get_node("SubViewportContainer/SubViewport/LaserBeam").power_time and time <= opening_time:
		agent.get_node("SubViewportContainer/SubViewport/LaserBeam").fire_laser(seg1.position,seg2.position,y_axis)
		laser_out =true
	if laser_out and time >= total_time-closing_time-agent.get_node("SubViewportContainer/SubViewport/LaserBeam").decay_time:
		agent.get_node("SubViewportContainer/SubViewport/LaserBeam").stop_laser()
		laser_out = false
	if time > total_time-closing_time:
		if !killed:
			seg1.modulate.a = lerp(1,0,(time-total_time+closing_time)/closing_time)
			seg2.modulate.a = lerp(1,0,(time-total_time+closing_time)/closing_time)
	if time >= total_time:
		if killed:
			die()
		seg1.global_position = Vector2(1000,1000)
		seg2.global_position = Vector2(1000,1000)
		return proc_finish(SUCCESS)
		
	
	
	return RUNNING

func proc_finish(r_status: Status) -> Status:
	if r_status != FAILURE:
		agent.weapon_cooldowns[0] = randf_range(min_cool, max_cool)
	else:
		agent.weapon_cooldowns[0] = min_cool
	started = false
	laser_out = false
	valid = true
	time = 0.0
	y_axis = false
	return r_status
