extends Control
class_name RemnantSlot

@export var index: int = 0

signal slot_selected(index: int)

@onready var btn_select: Button = $btn_select
@onready var name_label: Label = $btn_select/container/name_label
@onready var desc_label: RichTextLabel = $btn_select/container/description_label
@onready var rank_label: Label = $btn_select/container/rank_label

@onready var art = $btn_select/art

var remnant : Remnant = null

func _ready():
	art.material = art.material.duplicate(true)
	randomize()
	btn_select.focus_mode = Control.FOCUS_NONE  # Prevents keyboard focus

	# Intercept input via signal
	btn_select.gui_input.connect(_on_btn_gui_input)


func _on_btn_gui_input(event):
	if event is InputEventKey:
		if event.keycode == Key.KEY_SPACE or event.keycode == Key.KEY_ENTER:
			event.accept()  # Prevents space/enter from clicking the button

func set_remnant(remnant_in: Resource, is_upgrade : bool) -> void:
	remnant = remnant_in
	if remnant == null:
		art.texture = null
		name_label.text = "—"
		desc_label.text = ""
		return
	name_label.text = remnant_in.remnant_name
	desc_label.text = remnant_in.description
	if remnant_in.art:
		art.texture = remnant_in.art
	else:
		art.texture = null
	rank_label.text = "Rank " + _num_to_roman(remnant_in.rank) if !is_upgrade else "Rank " + _num_to_roman(remnant_in.rank) +"->" + _num_to_roman(remnant_in.rank+1)
	
	_update_description(remnant_in, desc_label, remnant_in.rank, is_upgrade)

func outline_remnant(color: Color = Color.ORANGE, alpha : float = 0.0):
	art.material.set_shader_parameter("outline_color", color)
	art.material.set_shader_parameter("outline_opacity", alpha)


func _on_button_pressed():
	emit_signal("slot_selected", index)
	#outline_remnant($btn_select/TextureRect, Color.PURPLE)
	
func _num_to_roman(input : int) -> String:
	match input:
		1:
			return "I"
		2:
			return "II"
		3:
			return "III"
		4:
			return "IV"
		5:
			return "V"
	return "error"

func _update_description(remnant: Resource, desc_label_up: RichTextLabel, rank: int, is_upgrade : bool) -> void:
	var new_text := desc_label.text

	for i in remnant.variable_names.size():
		var rem_name : String = remnant.variable_names[i]
		var value := str(remnant["variable_%d_values" % (i + 1)][rank - 1])
		var colored_value := "[color=white]" + value
		if is_upgrade:
			var new_value := str(remnant["variable_%d_values" % (i + 1)][rank])
			var colored_new_value := "[color=white]" + new_value
			
			#Color a trailing % sign if present
			if new_text.find(rem_name + "%") != -1:
				colored_value += "%->"+colored_new_value+"%[/color]"
				new_text = new_text.replace(rem_name + "%", colored_value)
			else:
				colored_value += "->"+colored_new_value+"[/color]"
				new_text = new_text.replace(rem_name, colored_value)
		else:
			#Color a trailing % sign if present
			if new_text.find(rem_name + "%") != -1:
				colored_value += "%[/color]"
				new_text = new_text.replace(rem_name + "%", colored_value)
			else:
				colored_value += "[/color]"
				new_text = new_text.replace(rem_name, colored_value)

	desc_label_up.text = new_text


func hide_visuals(enabled: bool):
	if enabled:
		btn_select.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	modulate.a = !enabled as float

func set_enabled(enabled: bool):
	btn_select.disabled = !enabled
	btn_select.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
