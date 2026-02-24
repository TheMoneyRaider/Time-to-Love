# AfterImage.gd
extends Sprite2D

@export var lifetime: float = 0.3            # Total duration of after-image
@export var start_alpha: float = 1.0         # Starting transparency
@export var end_alpha: float = 0.0           # Ending transparency
@export var mono: bool = false          # Mono colored

# Optional color shading
@export var start_color: Color = Color(1,1,1,1)
@export var start_color_strength: float = 0.0  # 0 = no effect, 1 = full color
@export var end_color: Color = Color(1,1,1,1)
@export var end_color_strength: float = 0.0

# Internal timer
var _time_passed: float = 0.0
var _initial_scale: Vector2

func _ready():
	_time_passed = 0.0
	_initial_scale = scale
	
	# Initialize alpha
	modulate.a = start_alpha
	# Apply initial color tint
	modulate = modulate.lerp(start_color, start_color_strength)
	
	set_process(true)
	if mono:
		material.set_shader_parameter("shader_mono",mono)

func _process(delta):
	_time_passed += delta
	var t : float = clamp(_time_passed / lifetime, 0.0, 1.0)  # normalized 0→1 over lifetime
	# Interpolate alpha
	modulate.a = lerp(start_alpha, end_alpha, t)
	
	# Interpolate color shading
	var strength = lerp(start_color_strength, end_color_strength, t)
	var target_color = lerp(start_color, end_color, t)
	
	# Blend modulate color while preserving alpha
	var current_alpha = modulate.a
	modulate = lerp(Color(1.0,1.0,1.0,1.0), target_color, strength)
	modulate.a = current_alpha
	
	# Remove node when lifetime exceeded
	if _time_passed >= lifetime:
		queue_free()
