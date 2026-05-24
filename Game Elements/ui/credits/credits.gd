extends CanvasLayer

@export var timeline1 : Node2D
@export var timeline2 : Node2D
@export var timeline3 : Node2D

@onready var color_rect = $ColorRect
@onready var main = $Main

var coalese_time = 10.0
var fade_time = 2.25
var end_scale = Vector2(.48, .48)

func _ready() -> void:
	color_rect.modulate.a = 0.0
	main.visible = false
	color_rect.visible = true

func activate():
	# Start state

	var tween = create_tween()

	#ColorRect fades in
	tween.tween_property(color_rect, "modulate:a", 1.0, 2.0)

	#Main becomes visible
	tween.tween_callback(func(): main.visible = true)

	#ColorRect fades out
	tween.tween_property(color_rect, "modulate:a", 0.0, 1.0)
	tween.tween_property(main.get_node("ColorRect"), "modulate:a", 0.0, 1.0)
	tween.tween_interval(1.0)
	tween.tween_property(timeline1, "modulate:a", .01, fade_time)
	tween.parallel().tween_property(timeline2, "modulate:a", .01, fade_time)
	tween.parallel().tween_property(timeline3, "modulate:a", .01, fade_time)
	
	

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
		t.tween_property(color_rect, "modulate:a", 1.0, .125)  # 5. Fade back in after timelines
		t.tween_callback(start_credits))



func _on_skip() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	RoomManager.reset()
	get_tree().paused = false
	Globals.save_config()
	get_tree().call_deferred("change_scene_to_file", "res://Game Elements/ui/main_menu/main_menu.tscn")

	


func start_credits():
	$Credits/AnimationPlayer.play("main")
	MusicManager.play_theme("main")
	$Credits/Skip.active = true
	$Credits/Skip.skip_requested.connect(_on_skip)
	await $Credits/AnimationPlayer.animation_finished
	_on_skip()
