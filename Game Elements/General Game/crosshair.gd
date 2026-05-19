extends Node2D

const DEFAULT_SPEED = 20.0
@onready var player = $".."
var crosshair_direction = Vector2(1,0)
var player_input_device = "key"
var mouse_sensitivity = 1.0
var debug_mode = false
var mouse_clamping_enabled = true
var input_direction = Vector2.ZERO
var glide = true
var joystick_acceleration = 7.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	player_input_device = player.input_device
	load_settings()
	Globals.config_changed.connect(load_settings)
	
func _input(event):
	if event.is_action_pressed("mouse_clamp") and debug_mode:
		mouse_clamping_enabled = !mouse_clamping_enabled
		if mouse_clamping_enabled:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func load_settings():
	mouse_sensitivity = Globals.config.get_value("controls", "mouse_sensitivity", 1.0)
	joystick_acceleration = Globals.config.get_value("controls","joystick_acceleration",7.0)
	glide = Globals.config.get_value("controls","controller_mode", true)
	debug_mode = Globals.config.get_value("debug", 'enabled', false)

func _process(_delta: float) -> void:
	if(player_input_device != "key"):
		input_direction = Input.get_vector("look_left_" + player_input_device, "look_right_" + player_input_device, "look_up_" + player_input_device, "look_down_" + player_input_device).normalized()
		if(input_direction != Vector2(0,0)):
			if(!glide):
				crosshair_direction = input_direction
			else:
				crosshair_direction = crosshair_direction.lerp(input_direction, joystick_acceleration * _delta).normalized()
	
	var camera = get_viewport().get_camera_2d()
	var mouse_coords = camera.get_global_mouse_position()
	var direction  = (mouse_coords - player.global_position).normalized()
	
	var CIRCLE_RADIUS = 70
	
	if player_input_device == "key":
		
		global_position = mouse_coords
		
		#var effective_clamping_radius = CIRCLE_RADIUS / mouse_sensitivity
		#
		#if((mouse_coords - player.global_position).length() < effective_clamping_radius ):
			#var mouse_offset = mouse_coords - player.global_position
			#var scaled_offset = mouse_offset * mouse_sensitivity
			#global_position = player.global_position + scaled_offset
		#else:
			#var clamped_offset = direction * CIRCLE_RADIUS
			#global_position = player.global_position + clamped_offset
			#
			#if mouse_clamping_enabled:
				#var unscaled_offset = clamped_offset / mouse_sensitivity
				#var target_mouse_world = player.global_position + unscaled_offset
				#var screen_pos = camera.get_viewport().get_screen_transform() * camera.get_canvas_transform() * target_mouse_world
				#Input.warp_mouse(screen_pos)
	else:
		if(player.weapons[player.is_purple as int].type == "Laser_Sword"):
			position = (crosshair_direction * 35)
		elif(player.weapons[player.is_purple as int].type == "Mace" or player.weapons[player.is_purple as int].type == "Crowbar"):
			position = (crosshair_direction * 25)
		else:
			position = (crosshair_direction * 50)
