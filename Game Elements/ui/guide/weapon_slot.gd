extends Control
class_name WeaponSlot

@export var index: int = 0

signal slot_selected(index: int)

@onready var btn_select: Button = $btn_select
@onready var name_label: Label = $btn_select/container/name_label
@onready var desc_label: RichTextLabel = $btn_select/container/description_label

@onready var art = $btn_select/art

var weapon : Weapon = null

func _ready():
	randomize()
	btn_select.focus_mode = Control.FOCUS_NONE  # Prevents keyboard focus

	# Intercept input via signal
	btn_select.gui_input.connect(_on_btn_gui_input)


func _on_btn_gui_input(event):
	if event is InputEventKey:
		if event.keycode == Key.KEY_SPACE or event.keycode == Key.KEY_ENTER:
			event.accept()  # Prevents space/enter from clicking the button

func set_weapon(weapon_in: Resource) -> void:
	weapon = weapon_in
	if weapon == null:
		name_label.text = "—"
		desc_label.text = ""
		return
	name_label.text = weapon_in.name
	desc_label.text = weapon_in.description
	var f_weapon_node = $btn_select/container/WeaponSprite
	f_weapon_node.weapon_direction = Vector2(0.70710678118,0.70710678118)
	var w_sprite = $btn_select/container/WeaponSprite/Sprite2D
	w_sprite.texture = weapon.weapon_sprite
	f_weapon_node.weapon_type = weapon.type
	w_sprite.hframes = weapon.sprite_hframes
	w_sprite.vframes = weapon.sprite_vframes
	if weapon.has_animation:
		f_weapon_node.get_node("AnimationPlayer").play(weapon.sprite_animation)
	else:
		f_weapon_node.get_node("AnimationPlayer").play("RESET")
	f_weapon_node.get_node("Sprite2D").scale = Vector2(6.0,6.0)
	
	if weapon.description_font:
		desc_label.add_theme_font_override("normal_font",weapon.description_font)
	if weapon.name_font:
		name_label.label_settings = name_label.label_settings.duplicate(true)
		name_label.label_settings.font = weapon.name_font
	


func _on_button_pressed():
	emit_signal("slot_selected", index)

func hide_visuals(enabled: bool):
	if enabled:
		btn_select.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	modulate.a = !enabled as float

func set_enabled(enabled: bool):
	btn_select.disabled = !enabled
	btn_select.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
