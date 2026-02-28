extends Node2D

var lifetime = .25

func _ready() -> void:
	$Sprite2D.scale *= randf_range(.9,1.3)
	var delay = randf_range(0.0,.2)
	lifetime+= delay
	await get_tree().create_timer(delay).timeout
	$AnimationPlayer.play("explode")

func _process(delta: float) -> void:
	lifetime-=delta
	if lifetime <=0.0:
		queue_free()
