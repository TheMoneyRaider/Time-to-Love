extends Node2D

@export var speed: float = 0
@export var wave_amplitude: float = 0
@export var wave_frequency: float = 0
@export var base_spacing: float = 15.0
@export var min_length: int = 5
@export var max_length: int = 20
var digit_string: String = ""

@export var binary_character_scene := preload("res://Game Elements/Objects/binary_character.tscn")

# Optional: assign your own monospace font here (if available)
@export var mono_font: Font

var glyphs: Array = []
var time_passed: float = 0.0

func _ready():
	randomize()
	time_passed = randf_range(0.0, 100.0)

	# Random binary string
	var length := randi_range(min_length, max_length)
	for i in range(length):
		digit_string += str(randi() % 2)

	speed = randf_range(40.0, 100.0)
	wave_amplitude = randf_range(1.0, 6.0)
	wave_frequency = randf_range(3.0, 5.0)
	base_spacing = randf_range(14.0, 17.0)

	create_digit_chain(digit_string)

func get_char_spacing(in_char: String) -> float:
	# Assign spacing per character (customize as needed)
	match in_char:
		"1": return base_spacing * 1
		"0": return base_spacing * 1
		"2","3","4","5","6","7","8","9": return base_spacing * 0.9
		_: return base_spacing


func create_digit_chain(text: String):
	var x_offset := 0.0

	for char_in in text:
		var glyph := binary_character_scene.instantiate()
		add_child(glyph)
		glyph.current_color = Color(0.0, 1.0, 0.0)
		glyph.new_color = Color(0.0, 1.0, 0.0)
		glyph.position = Vector2(x_offset, 0.0)
		glyph.set_character_data(char_in)

		x_offset += get_char_spacing(char_in) * 0.5
		glyphs.append(glyph)


func _process(delta: float):
	time_passed += delta

	# Move forward
	position.x += speed * delta
	if glyphs.size() == 0:
		queue_free()
	for i in range(glyphs.size()):
		glyphs[i].position.y = sin(time_passed * wave_frequency + float(i)) * wave_amplitude
