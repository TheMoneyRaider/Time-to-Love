extends Area2D

@export var interact_key := "activate"
@onready var prompt1 := $Prompt1
@export var weapon_type = ""
var tracked_bodies: Array = []
var cost : int = 0
var enabled : bool = true
@export var required_progress : float = 0.0

func set_cost(in_cost : int):
	cost = in_cost
	if cost!= 0:
		$Prompt1/TextureRect.visible = true
	else:
		$Prompt1/TextureRect.visible = false
var time_offset
func _ready():
	time_offset = randf()*50
	prompt1.visible = false
	var prog = max(Globals.total_progress,RoomManager.current_progress)
	if(prog < required_progress):
		enabled = false
		$Image.material = $Image.material.duplicate()
		var mat := $Image.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("desaturate", 0.0 if enabled else 1.0)
	var weapon_resource = load("res://Game Elements/Weapons/" + weapon_type + ".tres")
	var sprite = weapon_resource.weapon_sprite
	if weapon_type == "Railgun":
		$Image.hframes= 13
	$Image.texture = sprite
	self.connect("body_entered", Callable(self, "_on_body_entered"))
	self.connect("body_exited", Callable(self, "_on_body_exited"))
	if cost!= 0:
		$Prompt1/TextureRect.visible = true
	else:
		$Prompt1/TextureRect.visible = false

var time = 0.0
func _process(delta: float) -> void:
	time+=delta
	$Image.position.y = sin(time/2+time_offset)*1.5-16.0
	$Image.rotation = sin(time/2+2*time_offset) / 3
	if weapon_type == "Railgun" or weapon_type == "Laser Sword":
		$Image.rotation+=PI/2.0

func _on_body_entered(body):
	if body.is_in_group("player"):
		tracked_bodies.append(body)
		if enabled:
			prompt1.visible = true
		if len(tracked_bodies) == 1:
			_set_display(tracked_bodies[0])
func _on_body_exited(body):
	if body in tracked_bodies:
		tracked_bodies.erase(body)
	if len(tracked_bodies) == 0:
		if enabled:
			prompt1.visible = false
	else:
		_set_display(tracked_bodies[0])
		
		
func _set_display(body : Node):
	
	var glyph_key = "activate_"+body.input_device
	var sym = GlyphManager.get_glyph(GlyphManager.get_device_type(body.input_device),glyph_key)
	
	
	if cost != 0:
		prompt1.get_child(0).bbcode_text = ""+str(cost)+" to buy   "+sym
		return
	if weapon_type == "Fist":
		prompt1.get_child(0).bbcode_text = sym+": Unequip Weapon"
		return
		
	prompt1.get_child(0).bbcode_text = sym+": Equip "+weapon_type
