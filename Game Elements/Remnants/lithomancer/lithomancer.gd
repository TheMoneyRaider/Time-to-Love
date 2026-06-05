extends Area2D

var areas_in_range = {}
var litho_value = 0
var lifetime = 1
var duration = 0.0
var fade_in = .125
var fade_out = .25

var fading : bool = false
func _process(delta) -> void:
	duration += delta
	for area in areas_in_range:
		if "attack_type" in area and area.attack_type=="shield": continue
		if("c_owner" in area and is_instance_valid(area.c_owner) and !area.c_owner.is_in_group("player")):
			area.scale *= 1 - (litho_value  * .2 * delta)
			area.damage *= 1 - (litho_value  * .2 * delta)
		elif("c_owner" in area and is_instance_valid(area.c_owner) and area.c_owner.is_in_group("player")):
			#print("area.scale : ", area.scale)
			area.scale *= 1 + (litho_value  * .2 * delta)
			#print("area.damage : ", area.damage)
			area.damage *= 1 + (litho_value * .2 * delta)
	
	if duration +fade_out > lifetime and !fading:
		var tween =create_tween()
		tween.tween_property($Roots, "modulate:a", 0.0, fade_out)
	if duration > lifetime:
		for body in get_overlapping_bodies():
			_on_body_exited(body)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if(area.is_in_group("attack")):
		areas_in_range.get_or_add(area)

func _on_area_exited(area: Area2D) -> void:
	if(area.is_in_group("attack")):
		areas_in_range.erase(area)


func _on_body_entered(body: Node2D) -> void:
	if(body.is_in_group("player") or body.is_in_group("enemy")):
		body.move_speed *= .8


func _on_body_exited(body: Node2D) -> void:
	if(body.is_in_group("player") or body.is_in_group("enemy")):
		body.move_speed /= .8
		

func _ready() -> void:
	$Roots.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property($Roots,"modulate:a", 1.0, fade_in)
