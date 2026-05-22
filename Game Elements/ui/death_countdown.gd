extends Label



var counting : bool = false

var ticks = [
	preload("res://Game Elements/sfx/UI/deathclock/ti1.ogg"),
	preload("res://Game Elements/sfx/UI/deathclock/ti2.ogg"),
	preload("res://Game Elements/sfx/UI/deathclock/ti3.ogg")
]

var tocks = [
	preload("res://Game Elements/sfx/UI/deathclock/to1.ogg"),
	preload("res://Game Elements/sfx/UI/deathclock/to2.ogg"),
	preload("res://Game Elements/sfx/UI/deathclock/to3.ogg"),
	preload("res://Game Elements/sfx/UI/deathclock/to4.ogg")
]

func _ready() -> void:
	label_settings.font_color = Color(0.0,0.0,0.0,0.0)
	
	
var total_duration =0.0
var duration =0.0
var last_tick_number: int = -1
var use_tick: bool = true
var pitch_interval: float = 0.05


func start_countdown(time: float, player: Node):
	if player.is_purple:
		label_settings.font_color = Color(1.0, 0.208, 0.792, label_settings.font_color.a)
		label_settings.font = preload("res://fonts/OldEnglishFive.ttf")
	else:
		label_settings.font_color = Color(0.945, 0.443, 0.0, label_settings.font_color.a)
		label_settings.font = preload("res://fonts/Orbitron-Bold.ttf")
	duration = time
	total_duration = time
	counting = true
	use_tick = true
	last_tick_number = int(ceil(time))
	# play first tick immediately
	var pitch = 1.0 - (last_tick_number - 1) * pitch_interval
	var sounds = ticks if use_tick else tocks
	SFXManager.play(sounds[randi() % sounds.size()], 0.0, "SFX", Vector2(-99999,-99999), 1.0, pitch)
	use_tick = !use_tick
	
var max_font_size = 400
var min_font_size = 100
var max_opacity = 1.25
var min_opacity = .125

func stop_countdown():
	min_font_size=-1
	counting = false
	label_settings.font_color = Color(0.0,0.0,0.0,0.0)


func _process(delta: float) -> void:
	if counting:
		duration -= delta
		if duration <= 0:
			counting = false
			label_settings.font_color = Color(label_settings.font_color.r, label_settings.font_color.g, label_settings.font_color.b, 0.0)
		else:
			text = str(int(ceil(duration)))
			var current_tick = int(ceil(duration))
			if current_tick != last_tick_number:
				last_tick_number = current_tick
				var pitch = 1.0 - (current_tick - 1) * pitch_interval
				var sounds = ticks if use_tick else tocks
				SFXManager.play(sounds[randi() % sounds.size()], 7, "SFX", Vector2(-99999,-99999), 1.0, pitch)
				use_tick = !use_tick
			var t = 1.0 - duration / total_duration
			label_settings.font_color = Color(label_settings.font_color.r, label_settings.font_color.g, label_settings.font_color.b, lerp(min_opacity, max_opacity, t))
			label_settings.font_size = lerp(max_font_size, min_font_size, t)
