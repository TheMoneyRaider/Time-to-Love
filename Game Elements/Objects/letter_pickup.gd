extends Node2D


@export var interact_key := "activate"
@onready var prompt1 := $Prompt1
@onready var player_area := $Area2D
var tracked_bodies: Array = []

var letter_id : int = -1

func _ready():
	prompt1.visible = false
	player_area.connect("body_entered", Callable(self, "_on_body_entered"))
	player_area.connect("body_exited", Callable(self, "_on_body_exited"))


func disable(variant : Globals.RoomVariant):
	match variant:
		Globals.RoomVariant.MedOut:
			choose_random("res://art/objects/letter_fragments/MedOut")
		Globals.RoomVariant.MedIn:
			choose_random("res://art/objects/letter_fragments/MedIn")
		Globals.RoomVariant.WesternCanyon:
			choose_random("res://art/objects/letter_fragments/WesternCanyon")
			$PathwayIcon1.scale *= .5
		Globals.RoomVariant.WesternTown:
			choose_random("res://art/objects/letter_fragments/WesternCanyon")
			$PathwayIcon1.scale *= .5
		Globals.RoomVariant.SciFiCyberspace:
			choose_random("res://art/objects/letter_fragments/SciFiCyberspace")
		Globals.RoomVariant.SciFiFactory:
			choose_random("res://art/objects/letter_fragments/SciFiFactory")
			
func choose_random(path : String):
	var dir = ResourceLoader.list_directory(path)
	var art_pool = []
	if dir == null:
		push_error("Letters art folder not found: "+path)
		return
	for file in dir:
		if file.ends_with(".png"):
			var res = ResourceLoader.load(path+"/" + file)
			if res:
				art_pool.append(res)
	randomize()
	$PathwayIcon1.texture = art_pool[int(randf()*art_pool.size())]
	


func spawn_letter():
	SteamManager.unlock_achievement("LETTER_1")
	var LayerManager = get_tree().get_root().get_node("LayerManager")
	var letter = preload("res://Game Elements/Objects/letter_animation/letter_animation.tscn").instantiate()
	LayerManager.camera.add_child(letter)
	letter.position = (global_position - LayerManager.camera.global_position) / LayerManager.camera.scale
	letter.launch(Vector2.UP * -(global_position - LayerManager.camera.global_position).normalized().y)
	
	
	Globals.save_state.letter_progress[letter_id]=true
	Globals.num_letters_collected= min(Globals.num_letters_collected+1,Globals.num_letters)
	Globals.letter_percentage = Globals.num_letters_collected/float(Globals.num_letters)
	if Globals.letter_percentage >= .99:
		SteamManager.unlock_achievement("LETTER_ALL")
	queue_free()


func _on_body_entered(body):
	if body.is_in_group("player"):
		tracked_bodies.append(body)
		prompt1.visible = true
		_set_display(tracked_bodies[0])
func _on_body_exited(body):
	if body in tracked_bodies:
		tracked_bodies.erase(body)
	if len(tracked_bodies) == 0:
		prompt1.visible = false
	else:
		_set_display(tracked_bodies[0])

func _set_display(body : Node):
	var glyph_key = "activate_"+body.input_device
	var sym = GlyphManager.get_glyph(GlyphManager.get_device_type(body.input_device),glyph_key)
	prompt1.get_child(0).bbcode_text = "Pickup Letter: "+sym
