extends Control
class_name RemnantIcon

@export var remnant : Remnant
@export var is_purple : bool = false

signal icon_selected(rmenant: Remnant, is_purple : bool)

@onready var btn_select: Button = $Button
@export var button: Button

@onready var art = $TextureRect



func setup(remnant_in : Remnant, is_purple_in : bool):
	remnant = remnant_in
	is_purple = is_purple_in
	art.texture = remnant.icon


func _on_button_pressed():
	emit_signal("icon_selected", remnant, is_purple)
