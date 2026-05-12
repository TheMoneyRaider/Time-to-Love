extends Control

@export var timeline1 : Node2D
@export var timeline2 : Node2D
@export var timeline3 : Node2D

@onready var color_rect = $ColorRect
@onready var main = $Main

var coalese_time = 10.0
var end_scale = Vector2(.48, .48)

func _ready() -> void:
	# Start state
	color_rect.modulate.a = 0.0
	main.visible = false

	var tween = create_tween()

	#ColorRect fades in
	tween.tween_property(color_rect, "modulate:a", 1.0, 2.0)

	#Main becomes visible
	tween.tween_callback(func(): main.visible = true)

	#ColorRect fades out
	tween.tween_property(color_rect, "modulate:a", 0.0, 2.0)
	tween.tween_property(main.get_node("ColorRect"), "modulate:a", 0.0, 1.0)
	
	

	#Timeline animations
	tween.tween_callback(func():
		var t = create_tween()
		t.tween_property(timeline1, "rotation", deg_to_rad(-90), coalese_time)
		t.parallel().tween_property(timeline3, "rotation", deg_to_rad(-90), coalese_time)
		t.parallel().tween_property(timeline1, "scale", end_scale, coalese_time)
		t.parallel().tween_property(timeline2, "scale", end_scale, coalese_time)
		t.parallel().tween_property(timeline3, "scale", end_scale, coalese_time)
		
		t.tween_interval(2.0)
		t.tween_property(timeline1, "rotation", deg_to_rad(-89), .0625)
		t.parallel().tween_property(timeline3, "rotation", deg_to_rad(-91), .0625)
		t.tween_property(color_rect, "modulate:a", 1.0, .125))  # 5. Fade back in after timelines
