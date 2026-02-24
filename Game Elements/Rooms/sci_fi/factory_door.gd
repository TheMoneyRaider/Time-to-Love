extends Node2D

@onready var player_area := $Area2D

var tracked_bodies1: Array = []
func _ready():
	player_area.connect("body_entered", Callable(self, "_on_body_entered"))
	player_area.connect("body_exited", Callable(self, "_on_body_exited"))


func _on_body_entered(body):
	if body.is_in_group("player"):
		tracked_bodies1.append(body)
		open()
func _on_body_exited(body):
	if body in tracked_bodies1:
		tracked_bodies1.erase(body)
	if len(tracked_bodies1) == 0:
		close()
		

	
func open():
	$TileMapLayer.set_cell(Vector2(0,0),3,Vector2(4,5))
	$StaticBody2D.process_mode = Node.PROCESS_MODE_DISABLED
func close():
	$TileMapLayer.set_cell(Vector2(0,0),3,Vector2(4,4))
	$StaticBody2D.process_mode = Node.PROCESS_MODE_INHERIT
