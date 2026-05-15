extends Area2D

const SPEED_EFFECT   = preload("res://Game Elements/Effects/speed.tres")
const CRAFTER        = preload("res://Game Elements/Remnants/crafter.tres")
const CRAFTER_FX     = preload("res://Game Elements/Particles/crafter_particles.tscn")
const TICK_INTERVAL  = 0.21

@onready var anim   : AnimationPlayer    = $AnimationPlayer
@onready var hitbox : CollisionShape2D    = $CollisionShape2D

var active          : bool  = false
var tracked_bodies  : Array = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


# ── Activation ────────────────────────────────────────────────────────────────

func activate() -> void:
	active = true
	anim.play("Extend")
	_apply_slow_to_all()
	await _tick()
	anim.play("Retract")
	active = false
	await anim.animation_finished


func _tick() -> void:
	# Repeats every TICK_INTERVAL while bodies remain in range.
	while !tracked_bodies.is_empty():
		await get_tree().create_timer(TICK_INTERVAL, false).timeout
		_apply_slow_to_all()


# ── Effect helpers ────────────────────────────────────────────────────────────

func _apply_slow_to_all() -> void:
	for body in tracked_bodies:
		_try_apply_slow(body)


func _try_apply_slow(body: Node, cooldown: float = 0.2) -> void:
	if !_crafter_chance(body):
		return
	if body.effects.any(func(e): return e.type == "speed"):
		return
	var effect        = SPEED_EFFECT.duplicate(true)
	effect.cooldown   = cooldown
	effect.value1     = -0.8
	effect.gained(body)
	body.effects.append(effect)


# ── Body tracking ─────────────────────────────────────────────────────────────

func _on_body_entered(body: Node) -> void:
	if !body.has_method("take_damage"):
		return
	tracked_bodies.append(body)
	if active:
		_try_apply_slow(body, 1.0)  # longer cooldown for mid-active arrivals
	else:
		activate()


func _on_body_exited(body: Node) -> void:
	tracked_bodies.erase(body)


# ── Crafter remnant check ─────────────────────────────────────────────────────

func _crafter_chance(node: Node) -> bool:
	if !node.is_in_group("player"):
		return true

	var layer_mgr = get_tree().get_root().get_node("LayerManager")
	var remnants  = layer_mgr.player_1_remnants if node.is_purple else layer_mgr.player_2_remnants

	for rem in remnants:
		if rem.remnant_name == CRAFTER.remnant_name && rem.active:
			if rem.variable_1_values[rem.rank - 1] > randf() * 100:
				var fx          = CRAFTER_FX.instantiate()
				fx.position     = position
				get_parent().add_child(fx)
				return false

	return true
