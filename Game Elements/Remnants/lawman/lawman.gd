extends Area2D

@onready var player = $".."
var LayerManager : Node

func _ready():
	LayerManager = player.LayerManager

func _on_area_entered(area: Area2D) -> void:
	var remnants : Array[Remnant]
	if player.is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	var lawman = preload("res://Game Elements/Remnants/lawman.tres")
	for rem in remnants:
		if rem.active:
			if rem.remnant_name == lawman.remnant_name:
				if("c_owner" in area and area and !area.c_owner.is_in_group("player")):
					area.speed = area.speed * (1.0-rem.variable_1_values[rem.rank-1]/100.0)
					area.lifespan = area.lifespan / (1.0-rem.variable_1_values[rem.rank-1]/100.0)


func _on_area_exited(area: Area2D) -> void:
	var remnants : Array[Remnant]
	if player.is_purple:
		remnants = LayerManager.player_1_remnants
	else:
		remnants = LayerManager.player_2_remnants
	var lawman = preload("res://Game Elements/Remnants/lawman.tres")
	for rem in remnants:
		if rem.active:
			if rem.remnant_name == lawman.remnant_name:
				if("c_owner" in area and is_instance_valid(area) and !area.c_owner.is_in_group("player")):
					area.speed = area.speed / (1.0-rem.variable_1_values[rem.rank-1]/100.0)
					area.life = area.life * (1.0-rem.variable_1_values[rem.rank-1]/100.0)
					area.lifespan = area.lifespan * (1.0-rem.variable_1_values[rem.rank-1]/100.0)
					
