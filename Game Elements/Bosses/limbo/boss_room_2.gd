extends Node2D

var trap_cells := []
var blocked_cells := []
var liquid_cells : Array[Array]= [[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[]]

var camera : Node = null
var player1 : Node = null
var player2 : Node = null
var LayerManager : Node = null
var Hud : Node = null
var screen : Node = null
var active : bool = false
var is_multiplayer : bool = false

@export var boss_splash_art : Texture2D
@export var healthbar_underlays : Array[Texture2D]
@export var healthbar_overlays : Array[Texture2D]
@export var boss_names : Array[String]
@export var boss_name_settings : Array[LabelSettings]
@export var boss : Node
@export var boss_name : String
@export var boss_font : Font
#This is what values the bossbar shader is looking for
@export var phase_overlay_index : Array[int]
@export var boss_type : String =""
var animation : String = ""


func activate():
	LayerManager = get_tree().get_root().get_node("LayerManager")
	player1 = LayerManager.player1
	player2 = LayerManager.player2
	player1.move_speed *= 2.0
	if is_multiplayer:
		player2.move_speed *= 2.0
	is_multiplayer = LayerManager.is_multiplayer
	Hud =LayerManager.hud
	print("boss room activate")
	active = true
	Hud.show_boss_bar(healthbar_underlays[0],healthbar_overlays[0],boss_names[0],boss_name_settings[0],phase_overlay_index[0])
	Hud.update_bossbar(1.0)
	Hud.update_bossbar2(0.0)
	Hud.get_node("RootControl/VBoxContainer/HorizontalSlice/TimeFabric").visible = false
