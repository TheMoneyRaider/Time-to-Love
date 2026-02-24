extends Area2D

var original_global_position = Vector2(0,0)
var velocity : Vector2 = Vector2.ZERO
var tracked_bodies: Array = []

func _ready() -> void:
	original_global_position = global_position
	self.connect("body_entered", Callable(self, "_on_body_entered"))
	self.connect("body_exited", Callable(self, "_on_body_exited"))


func _process(delta: float) -> void:
	
	var players : Array[Vector2] = []
	if Globals.is_multiplayer:
		players.append(get_tree().get_root().get_node("LayerManager").player2.global_position)
	else:
		players.append(get_tree().get_root().get_node("LayerManager").player1.global_position)
	var closest_player_global_position = Vector2(100000000,10000000)
	for player in players:
		if global_position.distance_to(closest_player_global_position) > global_position.distance_to(player):
			closest_player_global_position = player
	if original_global_position.distance_to(closest_player_global_position) < 90 and global_position.distance_to(original_global_position) < 30:
		velocity -= (global_position - closest_player_global_position).normalized()*delta
	elif global_position.distance_to(original_global_position) > 5:
		velocity -= (global_position - original_global_position).normalized()*delta
	global_position += velocity
	velocity = velocity*.95

func activate() -> void:
	get_parent().open_shop()


func _on_body_entered(body):
	if body.is_in_group("player"):
		tracked_bodies.append(body)
func _on_body_exited(body):
	if body in tracked_bodies:
		tracked_bodies.erase(body)
		
