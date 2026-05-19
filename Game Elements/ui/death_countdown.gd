extends Label



var counting : bool = false

func _ready() -> void:
	label_settings.font_color = Color(0.0,0.0,0.0,0.0)
	
	
var total_duration =0.0
var duration =0.0
func start_countdown(time: float, player : Node):
	if player.is_purple:
		label_settings.font_color = Color(1.0, 0.208, 0.792,label_settings.font_color.a)
		label_settings.font = preload("res://fonts/OldEnglishFive.ttf")
	else:
		label_settings.font_color = Color(0.945, 0.443, 0.0,label_settings.font_color.a)
		label_settings.font = preload("res://fonts/Orbitron-Bold.ttf")
	duration=time
	total_duration=time
	counting= true

var max_font_size = 400
var min_font_size = 100
var max_opacity = 1.0
var min_opacity = .125

func stop_countdown():
	min_font_size=-1
	counting = false
	label_settings.font_color = Color(0.0,0.0,0.0,0.0)


func _process(delta: float) -> void:
	if counting:
		duration-=delta
		if duration<=0:
			counting = false
			label_settings.font_color = Color(label_settings.font_color.r,label_settings.font_color.g,label_settings.font_color.b,0.0)
		else:
			text = str(int(ceil(duration)))
			var t = 1.0-duration/total_duration
			label_settings.font_color = Color(label_settings.font_color.r,label_settings.font_color.g,label_settings.font_color.b,lerp(min_opacity,max_opacity,t))
			label_settings.font_size = lerp(max_font_size,min_font_size,t)
	
