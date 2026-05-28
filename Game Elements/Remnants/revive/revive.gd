extends Node2D

var player : Node
var health_percent : float

@export var feather_count := 20
@export var particle_count := 60

var time := 0.0
var camera
func _ready() -> void:
	SFXManager.play(preload("res://Game Elements/sfx/remnants/revive.ogg"),0.0,"SFX")
	player.get_tree().paused = true
	camera = player.LayerManager.camera
	player.visible = false
	if player.is_purple:
		$PlayerSprite.texture = load("res://art/Sprout Lands - Sprites - Basic pack/Characters/dead_purple.png")
	else:
		$PlayerSprite.texture = load("res://art/Sprout Lands - Sprites - Basic pack/Characters/dead_orange.png")
	$FeatherParticles.emitting = true
	$FeatherParticles.restart()
	$AnimationPlayer.play("main")
var duration = 4.0
func _process(delta: float) -> void:
	if time <= duration * 3.5/4.0: player.change_health(player.max_health*health_percent* delta/3.5)
	time+=delta
	camera.position = $PlayerSprite.global_position
	var ground = player.LayerManager.room_instance.get_node("Ground")
	if ground.get_node_or_null("GrassAddon"):
		ground.get_node_or_null("GrassAddon").start_override($PlayerSprite.global_position)
	if time >= duration:
		player.get_tree().paused = false
		player.visible = true
		player.global_position = $PlayerSprite.global_position
		player.change_health(0,player.max_health*health_percent -player.max_health)
		ground = player.LayerManager.room_instance.get_node("Ground")
		if ground.get_node_or_null("GrassAddon"):
			ground.get_node_or_null("GrassAddon").override = false
		queue_free()
