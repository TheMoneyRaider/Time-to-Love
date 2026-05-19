extends Node

## glyph_manager.gd
## Autoload singleton: GlyphManager
##
## Maps a device type + input action name (from project.godot) to the
## corresponding glyph character from the icomoon icon font (icon.ttf).
##
## Usage:
##   var g: String = GlyphManager.get_glyph("xbox", "attack_0")
##   var g: String = GlyphManager.get_glyph("ps4", "activate_0")
##   var g: String = GlyphManager.get_glyph("keyboard", "up_key")
##   var g: String = GlyphManager.get_glyph("switch", "swap_0")
##
## Drop the returned string into any Label/RichTextLabel using icon.ttf.
##
## Supported device strings (case-insensitive):
##   "keyboard" | "mouse"
##   "xbox" | "xbox360" | "xboxone" | "xboxseries"
##   "ps" | "ps4" | "ps5" | "playstation"
##   "switch" | "nintendo"
##
## Action names match your project.godot input map exactly.
## glyph_manager.gd
## Autoload singleton: GlyphManager
##
## Returns the icon name string for a given device + action.
## Assign icon.ttf as the font on your Label and set its text to the result.
##
## Usage:
##   my_label.text = GlyphManager.get_glyph("xbox", "attack_0")  # → "xbox_button_x"
##   my_label.text = GlyphManager.get_glyph("keyboard", "up_key") # → "keyboard_w"

const KEYBOARD_GLYPHS: Dictionary = {
	"right_key":    "keyboard_d",
	"left_key":     "keyboard_a",
	"up_key":       "keyboard_w",
	"down_key":     "keyboard_s",
	"activate_key": "keyboard_e",
	"attack_key":   "mouse_left",
	"swap_key":     "keyboard_space",
	"special_key":  "keyboard_f",
	"mouse_clamp":  "keyboard_c",
	"pause":        "keyboard_escape",
	"ui_accept":    "keyboard_enter",
	"ui_select":    "keyboard_space",
	"ui_left":      "keyboard_arrow_left",
	"ui_right":     "keyboard_arrow_right",
	"ui_up":        "keyboard_arrow_up",
	"ui_down":      "keyboard_arrow_down",
}

const XBOX_GLYPHS: Dictionary = {
	"activate_0":   "xbox_button_a",
	"attack_0":     "xbox_button_x",
	"special_0":    "xbox_button_y",
	"swap_0":       "xbox_lt",
	"right_0":      "xbox_stick_l_right",
	"left_0":       "xbox_stick_l_left",
	"up_0":         "xbox_stick_l_up",
	"down_0":       "xbox_stick_l_down",
	"look_right_0": "xbox_stick_r_right",
	"look_left_0":  "xbox_stick_r_left",
	"look_up_0":    "xbox_stick_r_up",
	"look_down_0":  "xbox_stick_r_down",
	"menu_right_0": "xbox_dpad_right",
	"menu_left_0":  "xbox_dpad_left",
	"menu_up_0":    "xbox_dpad_up",
	"menu_down_0":  "xbox_dpad_down",
	"quick_swap_0": "xbox_rs",
	"pause":        "xbox_button_menu",
	"ui_accept":    "xbox_button_a",
	"ui_select":    "xbox_button_a",
	"ui_left":      "xbox_dpad_left",
	"ui_right":     "xbox_dpad_right",
	"ui_up":        "xbox_dpad_up",
	"ui_down":      "xbox_dpad_down",
	"activate_1":   "xbox_button_a",
	"attack_1":     "xbox_button_x",
	"special_1":    "xbox_button_y",
	"swap_1":       "xbox_lt",
	"right_1":      "xbox_stick_l_right",
	"left_1":       "xbox_stick_l_left",
	"up_1":         "xbox_stick_l_up",
	"down_1":       "xbox_stick_l_down",
	"look_right_1": "xbox_stick_r_right",
	"look_left_1":  "xbox_stick_r_left",
	"look_up_1":    "xbox_stick_r_up",
	"look_down_1":  "xbox_stick_r_down",
	"menu_right_1": "xbox_dpad_right",
	"menu_left_1":  "xbox_dpad_left",
	"menu_up_1":    "xbox_dpad_up",
	"menu_down_1":  "xbox_dpad_down",
	"quick_swap_1": "xbox_rs",
}

const PS4_GLYPHS: Dictionary = {
	"activate_0":   "playstation_button_cross",
	"attack_0":     "playstation_button_square",
	"special_0":    "playstation_button_triangle",
	"swap_0":       "playstation_trigger_l2",
	"right_0":      "playstation_stick_l_right",
	"left_0":       "playstation_stick_l_left",
	"up_0":         "playstation_stick_l_up",
	"down_0":       "playstation_stick_l_down",
	"look_right_0": "playstation_stick_r_right",
	"look_left_0":  "playstation_stick_r_left",
	"look_up_0":    "playstation_stick_r_up",
	"look_down_0":  "playstation_stick_r_down",
	"menu_right_0": "playstation_dpad_right",
	"menu_left_0":  "playstation_dpad_left",
	"menu_up_0":    "playstation_dpad_up",
	"menu_down_0":  "playstation_dpad_down",
	"quick_swap_0": "playstation_button_r3",
	"pause":        "playstation4_button_options",
	"ui_accept":    "playstation_button_cross",
	"ui_select":    "playstation_button_cross",
	"ui_left":      "playstation_dpad_left",
	"ui_right":     "playstation_dpad_right",
	"ui_up":        "playstation_dpad_up",
	"ui_down":      "playstation_dpad_down",
	"activate_1":   "playstation_button_cross",
	"attack_1":     "playstation_button_square",
	"special_1":    "playstation_button_triangle",
	"swap_1":       "playstation_trigger_l2",
	"right_1":      "playstation_stick_l_right",
	"left_1":       "playstation_stick_l_left",
	"up_1":         "playstation_stick_l_up",
	"down_1":       "playstation_stick_l_down",
	"look_right_1": "playstation_stick_r_right",
	"look_left_1":  "playstation_stick_r_left",
	"look_up_1":    "playstation_stick_r_up",
	"look_down_1":  "playstation_stick_r_down",
	"menu_right_1": "playstation_dpad_right",
	"menu_left_1":  "playstation_dpad_left",
	"menu_up_1":    "playstation_dpad_up",
	"menu_down_1":  "playstation_dpad_down",
	"quick_swap_1": "playstation_button_r3",
}

const PS5_GLYPHS: Dictionary = {
	"activate_0":   "playstation_button_cross",
	"attack_0":     "playstation_button_square",
	"special_0":    "playstation_button_triangle",
	"swap_0":       "playstation_trigger_l2",
	"right_0":      "playstation_stick_l_right",
	"left_0":       "playstation_stick_l_left",
	"up_0":         "playstation_stick_l_up",
	"down_0":       "playstation_stick_l_down",
	"look_right_0": "playstation_stick_r_right",
	"look_left_0":  "playstation_stick_r_left",
	"look_up_0":    "playstation_stick_r_up",
	"look_down_0":  "playstation_stick_r_down",
	"menu_right_0": "playstation_dpad_right",
	"menu_left_0":  "playstation_dpad_left",
	"menu_up_0":    "playstation_dpad_up",
	"menu_down_0":  "playstation_dpad_down",
	"quick_swap_0": "playstation_button_r3",
	"pause":        "playstation5_button_options",
	"ui_accept":    "playstation_button_cross",
	"ui_select":    "playstation_button_cross",
	"ui_left":      "playstation_dpad_left",
	"ui_right":     "playstation_dpad_right",
	"ui_up":        "playstation_dpad_up",
	"ui_down":      "playstation_dpad_down",
	"activate_1":   "playstation_button_cross",
	"attack_1":     "playstation_button_square",
	"special_1":    "playstation_button_triangle",
	"swap_1":       "playstation_trigger_l2",
	"right_1":      "playstation_stick_l_right",
	"left_1":       "playstation_stick_l_left",
	"up_1":         "playstation_stick_l_up",
	"down_1":       "playstation_stick_l_down",
	"look_right_1": "playstation_stick_r_right",
	"look_left_1":  "playstation_stick_r_left",
	"look_up_1":    "playstation_stick_r_up",
	"look_down_1":  "playstation_stick_r_down",
	"menu_right_1": "playstation_dpad_right",
	"menu_left_1":  "playstation_dpad_left",
	"menu_up_1":    "playstation_dpad_up",
	"menu_down_1":  "playstation_dpad_down",
	"quick_swap_1": "playstation_button_r3",
}

const SWITCH_GLYPHS: Dictionary = {
	"activate_0":   "switch_button_a",
	"attack_0":     "switch_button_x",
	"special_0":    "switch_button_y",
	"swap_0":       "switch_button_zl",
	"right_0":      "switch_stick_l_right",
	"left_0":       "switch_stick_l_left",
	"up_0":         "switch_stick_l_up",
	"down_0":       "switch_stick_l_down",
	"look_right_0": "switch_stick_r_right",
	"look_left_0":  "switch_stick_r_left",
	"look_up_0":    "switch_stick_r_up",
	"look_down_0":  "switch_stick_r_down",
	"menu_right_0": "switch_dpad_right",
	"menu_left_0":  "switch_dpad_left",
	"menu_up_0":    "switch_dpad_up",
	"menu_down_0":  "switch_dpad_down",
	"quick_swap_0": "switch_stick_r_press",
	"pause":        "switch_button_plus",
	"ui_accept":    "switch_button_a",
	"ui_select":    "switch_button_a",
	"ui_left":      "switch_dpad_left",
	"ui_right":     "switch_dpad_right",
	"ui_up":        "switch_dpad_up",
	"ui_down":      "switch_dpad_down",
	"activate_1":   "switch_button_a",
	"attack_1":     "switch_button_x",
	"special_1":    "switch_button_y",
	"swap_1":       "switch_button_zl",
	"right_1":      "switch_stick_l_right",
	"left_1":       "switch_stick_l_left",
	"up_1":         "switch_stick_l_up",
	"down_1":       "switch_stick_l_down",
	"look_right_1": "switch_stick_r_right",
	"look_left_1":  "switch_stick_r_left",
	"look_up_1":    "switch_stick_r_up",
	"look_down_1":  "switch_stick_r_down",
	"menu_right_1": "switch_dpad_right",
	"menu_left_1":  "switch_dpad_left",
	"menu_up_1":    "switch_dpad_up",
	"menu_down_1":  "switch_dpad_down",
	"quick_swap_1": "switch_stick_r_press",
}

const FALLBACK_GLYPH := "flair_disabled"
# ---------------------------------------------------------------------------
# Device routing
# ---------------------------------------------------------------------------
func _get_table(device: String) -> Dictionary:
	match device.to_lower():
		"keyboard", "mouse":
			return KEYBOARD_GLYPHS
		"xbox", "xbox360", "xboxone", "xboxseries":
			return XBOX_GLYPHS
		"ps4", "playstation4", "ps", "playstation":
			return PS4_GLYPHS
		"ps5", "playstation5":
			return PS5_GLYPHS
		"switch", "nintendo":
			return SWITCH_GLYPHS
		_:
			push_warning("GlyphManager: unknown device '%s', falling back to keyboard." % device)
			return KEYBOARD_GLYPHS

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Returns the glyph character for [param device] + [param action].
## Assign icon.ttf as the font on your Label/RichTextLabel and insert directly.
func get_glyph(device: String, action: String) -> String:
	print(device)
	print(action)
	var table := _get_table(device)
	print(table[action])
	if table.has(action):
		return "[font=res://addons/input_prompt_icon_font/icon.ttf]"+table[action]+"[/font]"
	push_warning("GlyphManager: no glyph for device='%s' action='%s'" % [device, action])
	return "[font=res://addons/input_prompt_icon_font/icon.ttf]"+FALLBACK_GLYPH+"[/font]"

## Returns the raw Unicode codepoint integer.
func get_codepoint(device: String, action: String) -> int:
	var table := _get_table(device)
	return table.get(action, FALLBACK_GLYPH)

## Returns true if a glyph exists for this device + action combination.
func has_glyph(device: String, action: String) -> bool:
	return _get_table(device).has(action)

## Returns all recognised action names for a given device.
func get_actions_for_device(device: String) -> Array:
	return _get_table(device).keys()

## Convenience: returns the icon name string for a given icon,
## useful for debugging (e.g. to cross-reference with the icon browser).
## Example: GlyphManager.icon_name_for(0xECB9) → "xbox_button_a"
func icon_name_for(codepoint: int) -> String:
	var idx: int = codepoint - 0xE900
	# icon list mirrors the icomoon export order exactly
	const ICON_NAMES := ["controller_battery_empty","controller_battery_full","controller_battery_half","controller_connecting_a","controller_connecting_b","controller_disconnected","controller_generic","controller_icon_battery_empty","controller_icon_battery_full","controller_icon_battery_half","controller_icon_connecting_a","controller_icon_connecting_b","controller_icon_disconnected","controller_playstation1","controller_playstation2","controller_playstation3","controller_playstation4","controller_playstation5","controller_steam","controller_steamdeck","controller_switch","controller_switch_joycon_down","controller_switch_joycon_up","controller_switch_pro","controller_wii_classic","controller_wii_classic_pro","controller_wiiu_pro","controller_xbox360","controller_xbox_adaptive","controller_xboxone","controller_xboxseries","flair_arrow_0","flair_arrow_1","flair_arrow_2","flair_arrow_3","flair_arrow_backforth","flair_arrow_center_0","flair_arrow_center_1","flair_arrow_center_2","flair_arrow_center_3","flair_arrow_long","flair_arrow_short","flair_arrow_z","flair_arrows_all","flair_arrows_diagonal_all","flair_arrows_diagonal_left","flair_arrows_diagonal_right","flair_arrows_down","flair_arrows_horizontal","flair_arrows_left","flair_arrows_right","flair_arrows_up","flair_arrows_vertical","flair_circle_0","flair_circle_1","flair_circle_2","flair_circle_3","flair_circle_4","flair_circle_5","flair_circle_6","flair_circle_7","flair_circle_8","flair_circle_red_0","flair_circle_red_1","flair_circle_red_2","flair_circle_red_3","flair_circle_red_4","flair_circle_red_5","flair_circle_red_6","flair_circle_red_7","flair_circle_red_8","flair_circle_target_a","flair_circle_target_b","flair_cross","flair_disabled","flair_disabled_cross","flair_disabled_cross_outline","flair_disabled_line","flair_disabled_line_outline","flair_disabled_outline","flair_number_0","flair_number_0_outline","flair_number_1","flair_number_1_outline","flair_number_2","flair_number_2_outline","flair_number_3","flair_number_3_outline","flair_number_4","flair_number_4_outline","flair_number_5","flair_number_5_outline","flair_number_6","flair_number_6_outline","flair_number_7","flair_number_7_outline","flair_number_8","flair_number_8_outline","flair_number_9","flair_number_9_outline","flair_plus","flair_small_check","flair_small_check_outline","flair_small_cross","flair_small_cross_outline","flair_small_disabled","flair_small_disabled_outline","flair_small_info","flair_small_info_outline","flair_small_rotate","flair_small_rotate_outline","generic_button","generic_button_circle","generic_button_circle_fill","generic_button_circle_outline","generic_button_finger","generic_button_finger_pressed","generic_button_pressed","generic_button_square","generic_button_square_fill","generic_button_square_outline","generic_button_trigger_a","generic_button_trigger_a_fill","generic_button_trigger_a_outline","generic_button_trigger_b","generic_button_trigger_b_fill","generic_button_trigger_b_outline","generic_button_trigger_c","generic_button_trigger_c_fill","generic_button_trigger_c_outline","generic_joystick","generic_joystick_horizontal","generic_joystick_left","generic_joystick_red","generic_joystick_red_horizontal","generic_joystick_red_left","generic_joystick_red_right","generic_joystick_right","generic_stick","generic_stick_down","generic_stick_horizontal","generic_stick_left","generic_stick_press","generic_stick_right","generic_stick_side","generic_stick_up","generic_stick_vertical","keyboard_0","keyboard_0_outline","keyboard_1","keyboard_1_outline","keyboard_2","keyboard_2_outline","keyboard_3","keyboard_3_outline","keyboard_4","keyboard_4_outline","keyboard_5","keyboard_5_outline","keyboard_6","keyboard_6_outline","keyboard_7","keyboard_7_outline","keyboard_8","keyboard_8_outline","keyboard_9","keyboard_9_outline","keyboard_a","keyboard_a_outline","keyboard_alt","keyboard_alt_outline","keyboard_any","keyboard_any_outline","keyboard_apostrophe","keyboard_apostrophe_outline","keyboard_arrow_down","keyboard_arrow_down_outline","keyboard_arrow_left","keyboard_arrow_left_outline","keyboard_arrow_right","keyboard_arrow_right_outline","keyboard_arrow_up","keyboard_arrow_up_outline","keyboard_arrows","keyboard_arrows_all","keyboard_arrows_down","keyboard_arrows_down_outline","keyboard_arrows_horizontal","keyboard_arrows_horizontal_outline","keyboard_arrows_left","keyboard_arrows_left_outline","keyboard_arrows_none","keyboard_arrows_right","keyboard_arrows_right_outline","keyboard_arrows_up","keyboard_arrows_up_outline","keyboard_arrows_vertical","keyboard_arrows_vertical_outline","keyboard_asterisk","keyboard_asterisk_outline","keyboard_b","keyboard_b_outline","keyboard_backspace","keyboard_backspace_icon","keyboard_backspace_icon_alternative","keyboard_backspace_icon_alternative_outline","keyboard_backspace_icon_outline","keyboard_backspace_outline","keyboard_bracket_close","keyboard_bracket_close_outline","keyboard_bracket_greater","keyboard_bracket_greater_outline","keyboard_bracket_less","keyboard_bracket_less_outline","keyboard_bracket_open","keyboard_bracket_open_outline","keyboard_c","keyboard_c_outline","keyboard_capslock","keyboard_capslock_icon","keyboard_capslock_icon_outline","keyboard_capslock_outline","keyboard_caret","keyboard_caret_outline","keyboard_colon","keyboard_colon_outline","keyboard_comma","keyboard_comma_outline","keyboard_command","keyboard_command_outline","keyboard_ctrl","keyboard_ctrl_outline","keyboard_d","keyboard_d_outline","keyboard_delete","keyboard_delete_outline","keyboard_e","keyboard_e_outline","keyboard_end","keyboard_end_outline","keyboard_enter","keyboard_enter_outline","keyboard_equals","keyboard_equals_outline","keyboard_escape","keyboard_escape_outline","keyboard_exclamation","keyboard_exclamation_outline","keyboard_f","keyboard_f1","keyboard_f10","keyboard_f10_outline","keyboard_f11","keyboard_f11_outline","keyboard_f12","keyboard_f12_outline","keyboard_f1_outline","keyboard_f2","keyboard_f2_outline","keyboard_f3","keyboard_f3_outline","keyboard_f4","keyboard_f4_outline","keyboard_f5","keyboard_f5_outline","keyboard_f6","keyboard_f6_outline","keyboard_f7","keyboard_f7_outline","keyboard_f8","keyboard_f8_outline","keyboard_f9","keyboard_f9_outline","keyboard_f_outline","keyboard_function","keyboard_function_outline","keyboard_g","keyboard_g_outline","keyboard_h","keyboard_h_outline","keyboard_home","keyboard_home_outline","keyboard_i","keyboard_i_outline","keyboard_insert","keyboard_insert_outline","keyboard_j","keyboard_j_outline","keyboard_k","keyboard_k_outline","keyboard_l","keyboard_l_outline","keyboard_m","keyboard_m_outline","keyboard_minus","keyboard_minus_outline","keyboard_n","keyboard_n_outline","keyboard_numlock","keyboard_numlock_outline","keyboard_numpad_enter","keyboard_numpad_enter_outline","keyboard_numpad_plus","keyboard_numpad_plus_outline","keyboard_o","keyboard_o_outline","keyboard_option","keyboard_option_outline","keyboard_p","keyboard_p_outline","keyboard_page_down","keyboard_page_down_outline","keyboard_page_up","keyboard_page_up_outline","keyboard_period","keyboard_period_outline","keyboard_plus","keyboard_plus_outline","keyboard_printscreen","keyboard_printscreen_outline","keyboard_q","keyboard_q_outline","keyboard_question","keyboard_question_outline","keyboard_quote","keyboard_quote_outline","keyboard_r","keyboard_r_outline","keyboard_return","keyboard_return_outline","keyboard_s","keyboard_s_outline","keyboard_semicolon","keyboard_semicolon_outline","keyboard_shift","keyboard_shift_icon","keyboard_shift_icon_outline","keyboard_shift_outline","keyboard_slash_back","keyboard_slash_back_outline","keyboard_slash_forward","keyboard_slash_forward_outline","keyboard_space","keyboard_space_icon","keyboard_space_icon_outline","keyboard_space_outline","keyboard_t","keyboard_t_outline","keyboard_tab","keyboard_tab_icon","keyboard_tab_icon_alternative","keyboard_tab_icon_alternative_outline","keyboard_tab_icon_outline","keyboard_tab_outline","keyboard_tilde","keyboard_tilde_outline","keyboard_u","keyboard_u_outline","keyboard_v","keyboard_v_outline","keyboard_w","keyboard_w_outline","keyboard_win","keyboard_win_outline","keyboard_x","keyboard_x_outline","keyboard_y","keyboard_y_outline","keyboard_z","keyboard_z_outline","mouse","mouse_horizontal","mouse_left","mouse_left_outline","mouse_move","mouse_outline","mouse_right","mouse_right_outline","mouse_scroll","mouse_scroll_down","mouse_scroll_down_outline","mouse_scroll_outline","mouse_scroll_up","mouse_scroll_up_outline","mouse_scroll_vertical","mouse_scroll_vertical_outline","mouse_small","mouse_vertical"]
	if idx >= 0 and idx < ICON_NAMES.size():
		return ICON_NAMES[idx]
	return "unknown"

func get_device_type(device_id: String) -> String:
	if device_id=="key":
		return "keyboard"
		
	var joy_name := Input.get_joy_name(int(device_id)).to_lower()
	print(joy_name)
	if "xbox" in joy_name:
		if "series" in joy_name:
			return "xboxseries"
		elif "one" in joy_name:
			return "xboxone"
		else:
			return "xbox360"
	elif "playstation" in joy_name or "dualshock" in joy_name or "dualsense" in joy_name or "ps":
		if "5" in joy_name or "dualsense" in joy_name:
			return "ps5"
		else:
			return "ps4"
	elif "switch" in joy_name or "nintendo" in joy_name or "joy-con" in joy_name:
		return "switch"
	else:
		return "xbox"  # sensible default for unknown controllers
