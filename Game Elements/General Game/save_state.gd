extends Resource
class_name SaveState

@export var picture : Texture2D = preload("res://ui_captures/p1_none_hover_p2_none_hover.png")
@export var total_progress : float = 0.0
@export var remnant_progress : Dictionary = {}
@export var viewed_letter_progress : Dictionary = {}
@export var letter_progress : Dictionary = {}
@export var time_spent : float = 0.0
@export var weapon1 : String = "res://Game Elements/Weapons/Fist.tres"
@export var weapon2 : String = "res://Game Elements/Weapons/Fist.tres"
