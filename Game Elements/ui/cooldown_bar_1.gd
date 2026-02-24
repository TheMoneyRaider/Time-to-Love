extends Control

@onready var cooldown_bar = $CooldownBar

var max_cooldown = .5
var current_cooldown = 0
var is_covered = false

func _ready() -> void:
	cooldown_bar.step = max_cooldown/100
	
func set_max_cooldown(cooldown_value : float) -> void:
	max_cooldown = cooldown_value
	cooldown_bar.max_value = max_cooldown
	cooldown_bar.step = max_cooldown/100

func set_current_cooldown(cooldown_value : float) -> void:
	current_cooldown = cooldown_value
	cooldown_bar.value = max_cooldown - current_cooldown

func set_cooldown_icon(cooldown_icon : Resource):
	cooldown_bar.texture_under = cooldown_icon
	cooldown_bar.texture_over = cooldown_icon
	cooldown_bar.texture_progress = cooldown_icon

func cover_cooldown():
	if(is_covered):
		cooldown_bar.tint_over = Color(0.443, 0.443, 0.443, 0.0)
		is_covered = false
	else:
		cooldown_bar.tint_over = Color(0.443, 0.443, 0.443, 0.8)
		is_covered = true

func set_color(is_purple : bool) -> void:
	if is_purple:
		cooldown_bar.tint_progress = Color(0.627, 0.125, 0.941)
	else:
		cooldown_bar.tint_progress = Color(1.0, 0.647, 0.0)
