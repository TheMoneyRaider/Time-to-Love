extends CanvasLayer

var mouse_mode = null
var active = false
@export var scroller : Control

var current_focus_index := -2  # -1 means return focused
@export var joystick_deadzone := 0.5  # adjust for your joystick sensitivity
var last_input_dir := 0  # prevent repeated triggers
var last_input_dirv := 0  # prevent repeated triggers
var letter_pool: Array[Letter] = []

var LayerManager : Node
func _ready():
	LayerManager = get_tree().get_root().get_node("LayerManager")
	hide()

func _load_all_letters() -> void:
	#var dir = DirAccess.open("res://Game Elements/Remnants/")
	var dir = ResourceLoader.list_directory("res://Game Elements/ui/guide/letters/")
	if dir == null:
		push_error("Letters folder not found: res://Game Elements/ui/guide/letters/")
		return
	for file in dir:
		if file.ends_with(".tres"):
			var res = ResourceLoader.load("res://Game Elements/ui/guide/letters/" + file)
			if res:
				letter_pool.append(res)


func activate():
	active = true
	show()
	#populate_weapons()
	$Control/Return.grab_focus()
var wep_snapped = false



func _on_return_pressed():
	active = false
	hide()
	current_focus_index = -2
	$Control/Return.grab_focus()
	get_parent().get_node("PauseMenu").activate()
	
