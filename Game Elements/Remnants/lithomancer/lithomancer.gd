extends Area2D

var areas_in_range = {}
var litho_value = 0
var lifetime = 1

func _process(_delta) -> void:
	lifetime -= _delta
	for area in areas_in_range:
		if("c_owner" in area and is_instance_valid(area.c_owner) and !area.c_owner.is_in_group("player")):
			area.scale *= 1 - (litho_value  * .2 * _delta)
			area.damage *= 1 - (litho_value  * .2 * _delta)
		elif("c_owner" in area and is_instance_valid(area.c_owner) and area.c_owner.is_in_group("player")):
			print("area.scale : ", area.scale)
			area.scale *= 1 + (litho_value  * .2 * _delta)
			print("area.damage : ", area.damage)
			area.damage *= 1 + (litho_value * .2 * _delta)
	if(lifetime < 0):
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
