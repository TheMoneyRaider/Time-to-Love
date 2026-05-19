extends Label



var counting : bool = false

func _ready() -> void:
	label_settings.color = Color()
	
	
var total_duration =0.0
var duration =0.0
func start_countdown(time: float, player : Node):
	if player.is_purple:
		label_settings.color = Color(1.0, 0.208, 0.792,label_settings.color.a)
	else:
		label_settings.color = Color(0.945, 0.443, 0.0,label_settings.color.a)
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


func _process(delta: float) -> void:
	if counting:
		duration-=delta
		if duration<=0:
			counting = false
			label_settings.color = Color(label_settings.color.rgb,0.0)
		else:
			var t = duration/total_duration
			label_settings.color = Color(label_settings.color.rgb,min_opacity.lerp(max_opacity,t))
			label_settings.font_size = max_font_size.lerp(min_font_size,t)
	
