extends Node2D

var killed : bool = false

func kill(dmg_owner : Node, damage : float, current_health : float, direction : Vector2):
	if killed:
		return
	killed = true
	var mat0 = get_parent().get_node("Tentacle/SubViewportContainer/SubViewport/TwoToneCanvasGroup").material
	var mat = mat0.duplicate(true)
	get_parent().get_node("Tentacle/SubViewportContainer/SubViewport/TwoToneCanvasGroup").material = mat
	var tween = create_tween()
	var col1 = mat.get_shader_parameter("light_color")
	var col2 = mat.get_shader_parameter("dark_color")
	tween.tween_method(
		func(value: Color): mat.set_shader_parameter("light_color", value),
		col1,
		Color(1.0,1.0,1.0,0.25),
		1.4
	)
	tween.parallel().tween_method(
		func(value: Color): mat.set_shader_parameter("dark_color", value),
		col2,
		Color(0.0, 0.0, 0.0, 0.15),
		1.4
	)
	await tween.finished
	
	if dmg_owner != null && dmg_owner.is_in_group("player"):
		dmg_owner.kill_enemy(get_parent())
	get_parent().emit_signal("enemy_took_damage",damage,current_health,get_parent(),direction)
	#$Tentacle/SubViewportContainer/SubViewport/TwoToneCanvasGroup.material.set_shader_parameter("light_color",light_color)
	#$Tentacle/SubViewportContainer/SubViewport/TwoToneCanvasGroup.material.set_shader_parameter("dark_color",dark_color)
