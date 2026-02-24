extends Label

@export var mono_font: Font
@export var current_color := Color(0.0, 0.373, 0.067, 1.0)
var new_color := current_color
@export var outline_size := 2
@export var font_size := 64
@export var char_scale := 0.125
@export var variation = .1
var change_time = 1.0
var current_time = 0.0

var lum_offset := 0.0
var cached_scale := Vector2.ZERO

func _ready():
	# Set static properties once
	add_theme_constant_override("outline_size", outline_size)
	add_theme_font_override("font", mono_font)
	add_theme_font_size_override("font_size", font_size)
	
	cached_scale = Vector2(char_scale, char_scale)
	scale = cached_scale

	_update_visuals()
	
	# Center pivot after visuals update
	await get_tree().process_frame
	reset_size()
	pivot_offset = -get_combined_minimum_size() * scale * 0.5


func set_character_data(glyph: String):
	text = glyph
	lum_offset = randf_range(-variation, variation)
	_update_visuals()

func _process(delta: float) -> void:
	if current_time <= 0.0:
		return
	current_time = max(0.0, current_time - delta)
	_update_color()
		
	

func _change_color(color : Color, time : float = 1.0, delay : float = 0.0):
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	change_time = time
	current_time = time
	current_color = new_color
	new_color = color
	_update_color()
	
func _change_char(char : String, delay : float = 0.0):
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	text = char




# Separate function for color interpolation only
func _update_color():
	var t := 1.0
	if change_time > 0.0:
		t = clamp((change_time - current_time) / change_time, 0.0, 1.0)

	var v1 : float= clamp(current_color.v + lum_offset, 0.0, 1.0)
	var v2 : float= clamp(new_color.v + lum_offset, 0.0, 1.0)

	var col1 := Color.from_hsv(current_color.h, current_color.s, v1, current_color.a)
	var col2 := Color.from_hsv(new_color.h, new_color.s, v2, new_color.a)

	# GPU-friendly: apply directly with modulate
	modulate = col1.lerp(col2, t)

# Only call this once during _ready() and when char_scale changes
func _update_visuals():
	scale = cached_scale
	_update_color()
