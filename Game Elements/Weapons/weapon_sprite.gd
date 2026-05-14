extends Node2D

@onready var player = $".."
var weapon_direction = Vector2(1,0)
var weapon_type = ""
var flip = 1

var last_weapon_type = ""

var crowbar_angle = PI/3

func _process(_delta: float):
	if last_weapon_type != weapon_type:
		update_weapon_location()
	if player.is_in_group("player"):
		match weapon_type:
			"Mace":
				rotation = (flip * weapon_direction).angle()
			"Laser_Sword":
				rotation = weapon_direction.angle()+ PI / 2 - TAU* _cubic_bezier(0,.42, .58, 1.0,(player.cooldowns[player.is_purple as int] / .3))
			"Crowbar":
				rotation = weapon_direction.angle() + flip * ( -crowbar_angle + (2*crowbar_angle) * _cubic_bezier(0,.42,.58,1.0,(clamp(player.cooldowns[player.is_purple as int] -.1,0,.2) / .2)))
			"Railgun":
				rotation = weapon_direction.angle()+ PI / 2
			"Crossbow":
				rotation = weapon_direction.angle() + PI/2
			"Shotgun":
				rotation = weapon_direction.angle()
			_:
				rotation = weapon_direction.angle() + PI / 2
	else:
		match weapon_type:
			"Mace":
				rotation = (flip * weapon_direction).angle()
			"Laser_Sword":
				rotation = weapon_direction.angle()+ PI / 2
			"Crowbar":
				rotation = weapon_direction.angle() +5*PI/4
			"Railgun":
				rotation = weapon_direction.angle()+ PI / 2
			"Crossbow":
				rotation = weapon_direction.angle() + PI/2
			"Shotgun":
				rotation = weapon_direction.angle() + PI*7/4
			_:
				rotation = weapon_direction.angle() + PI / 2

func _cubic_bezier(p0: float, p1: float, p2: float, p3: float, t: float):
	var q0 = lerp(p0, p1, t)
	var q1 = lerp(p2,p1, t)
	var q2 = lerp(p2,p3, t)

	var r0 = lerp(q0, q1, t)
	var r1 = lerp(q1, q2, t)

	var s = lerp(r0, r1, t)
	return s


func _ready() -> void:
	$Sprite2D.material = $Sprite2D.material.duplicate(true)

func flip_direction():
	flip *= -1
	
func update_weapon_location():
	last_weapon_type = weapon_type
	if player.is_in_group("player"):
		match weapon_type:
			"Mace":
				$Sprite2D.position = Vector2(-8,-27) * $Sprite2D.scale
			"Laser_Sword":
				$Sprite2D.position = Vector2(-16,-28) * $Sprite2D.scale
			"Railgun":
				$Sprite2D.position = Vector2(-11,-48) * $Sprite2D.scale
			"Crowbar":
				$Sprite2D.position = Vector2(-2,-9) * $Sprite2D.scale
			"Crossbow":
				$Sprite2D.position = Vector2(-16,-24) * $Sprite2D.scale
			"Shotgun":
				$Sprite2D.position = Vector2(-3,-10) * $Sprite2D.scale
			_:
				$Sprite2D.position = Vector2(0,0) * $Sprite2D.scale
	else:
		match weapon_type:
			"Mace":
				$Sprite2D.position = Vector2(12,-16) * $Sprite2D.scale
			"Laser_Sword":
				$Sprite2D.position = Vector2(-16,-38) * $Sprite2D.scale
			"Railgun":
				$Sprite2D.position = Vector2(-11,-48) * $Sprite2D.scale
			"Crowbar":
				$Sprite2D.position = Vector2(-30,2) * $Sprite2D.scale
			"Crossbow":
				$Sprite2D.position = Vector2(-12,-36) * $Sprite2D.scale
			"Shotgun":
				$Sprite2D.position = Vector2(2,8) * $Sprite2D.scale
	
