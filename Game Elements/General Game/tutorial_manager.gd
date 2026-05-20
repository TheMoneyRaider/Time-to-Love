extends Node

var display : Node
var phase = -1

var requirements : Array[float] = [3.0, 3.0, 4.0, 2.0]
var player_req : Array[Array] = [[0.0,0.0,0.0,0.0],[0.0,0.0,0.0,0.0]]
#slow_tether, Move, tether,  attack, special
func deactivate():
	display = null
	phase = -1
	if display: display.visible = false

var player : Node

func activate(display_in : Node):
	player = get_tree().get_root().get_node("LayerManager").player1
	if phase!=0:
		display = display_in
		display.visible = true
		display.modulate.a = 0.0
		phase=0
		phase_transition(-1,0)

func player_tethers(is_purple : bool,amount : float):
	if phase!=0: return
	player_req[is_purple as int][phase]+=amount
	if !Globals.is_multiplayer: player_req[!is_purple as int][phase]+=amount
	update_display()
	if player_req[0][phase] >= requirements[phase] and player_req[1][phase] >= requirements[phase]:
		phase_transition(0,1)
	pass
	
func player_tethers_short(is_purple : bool,amount : float):
	if phase!=1: return
	player_req[is_purple as int][phase]+=amount
	if !Globals.is_multiplayer: player_req[!is_purple as int][phase]+=amount
	update_display()
	if player_req[0][phase] >= requirements[phase] and player_req[1][phase] >= requirements[phase]:
		phase_transition(1,2)
	pass

func player_attacks(is_purple : bool,amount : float):
	if phase!=2: return
	player_req[is_purple as int][phase]+=amount
	if !Globals.is_multiplayer: player_req[!is_purple as int][phase]+=amount
	update_display()
	if player_req[0][phase] >= requirements[phase] and player_req[1][phase] >= requirements[phase]:
		phase_transition(2,3)
	pass
func player_specials(is_purple : bool,amount : float):
	if phase!=3: return
	player_req[is_purple as int][phase]+=amount
	if !Globals.is_multiplayer: player_req[!is_purple as int][phase]+=amount
	update_display()
	if player_req[0][phase] >= requirements[phase] and player_req[1][phase] >= requirements[phase]:
		phase_transition(3,4)
	pass
	
func update_display():
	var requirement = requirements[phase]
	var p0 = player_req[0][phase]
	var p1 = player_req[1][phase]

	var p0_done = p0 >= requirement
	var p1_done = p1 >= requirement

	# Format values: phase 0 keeps floats, all others cast to int
	var p0_str : String
	var p1_str : String
	var req_str : String
	if phase == 0:
		p0_str = "%.1f" % minf(p0, requirement)
		p1_str = "%.1f" % minf(p1, requirement)
		req_str = "%.1f" % requirement
	else:
		p0_str = str(mini(int(p0), int(requirement)))
		p1_str = str(mini(int(p1), int(requirement)))
		req_str = str(int(requirement))

	# Gold color tag for completed, white otherwise
	const GOLD = "ffcc00"
	const PURPLE = "a002a8"
	const ORANGE = "a85b02"

	var p0_color = GOLD if p0_done else ORANGE
	var p1_color = GOLD if p1_done else PURPLE
	var req_color_0 = GOLD if p0_done else ORANGE
	var req_color_1 = GOLD if p1_done else PURPLE

	# Build the progress string appended after the instruction text
	# Format:  P1: X/Y    P2: X/Y
	var progress_text
	if Globals.is_multiplayer:
		progress_text = (
			"  [color=#%s]%s[/color][color=#%s]/%s[/color]" % [p1_color, p1_str, req_color_1, req_str]
			+ "   [color=#%s]%s[/color][color=#%s]/%s[/color]" % [p0_color, p0_str, req_color_0, req_str]
		)
	else:
		progress_text = (
			"  [color=WHITE]%s[/color][color=WHITE]/%s[/color]" % [p1_str, req_str]
		)

	# Rebuild full display text from instruction + progress
	get_1st_text()  # this sets display.text to the instruction portion
	display.text += progress_text

func get_1st_text():
	var text = ""
	#Switch
	if Globals.is_multiplayer:
		match phase:
			0:
				display.text = "[font=res://addons/input_prompt_icon_font/icon.ttf]

	[code]Hold[/code] keyboard_space / playstation_trigger_l1 / xbox_lb
	[code]Tether"
			1:
				display.text = "[font=res://addons/input_prompt_icon_font/icon.ttf]

	[code]Tap[/code] keyboard_space / playstation_trigger_l1 / xbox_lb
	[code]Quick Swap"
			2:
				display.text = "[font=res://addons/input_prompt_icon_font/icon.ttf]
	mouse_left_outline / playstation_trigger_r2 / xbox_rt
	[code]Attack"
			3:
				display.text = "[font=res://addons/input_prompt_icon_font/icon.ttf]

	mouse_right_outline / playstation_trigger_r1 / xbox_rb[/font]
	Special(Charged)
	[font_size=48]Hit enemies to build charge"
	else:
		match phase:
			0:
				var device_type := GlyphManager.get_device_type(player.input_device)
				var sym= ""
				match device_type.to_lower():
					"keyboard", "mouse":
						sym = "swap_key"
					"xbox", "xbox360", "xboxone", "xboxseries":
						sym = "swap_0"
					"ps4", "playstation4", "ps", "playstation":
						sym = "swap_0"
					"ps5", "playstation5":
						sym = "swap_0"
					"switch", "nintendo":
						sym = "swap_0"
				
				sym = GlyphManager.get_glyph(device_type, sym)
				display.text = "[font=res://addons/input_prompt_icon_font/icon.ttf]

	[code]Hold[/code] "+sym+"[/font]
	[code]Tether"
			1:
				var glyph_key : String= "swap_" + player.input_device
				var device_type := GlyphManager.get_device_type(player.input_device)
				var sym := GlyphManager.get_glyph(device_type, glyph_key)
				display.text = "[font=res://addons/input_prompt_icon_font/icon.ttf]

	[code]Tap[/code] "+sym+"[/font]
	[code]Quick Swap"
			2:
				var glyph_key : String= "attack_" + player.input_device
				var device_type := GlyphManager.get_device_type(player.input_device)
				var sym := GlyphManager.get_glyph(device_type, glyph_key)
				display.text = "[font=res://addons/input_prompt_icon_font/icon.ttf]

	"+sym+"[/font]
	[code]Attack"
			3:
				var glyph_key : String= "special_" + player.input_device
				var sym
				if glyph_key == "special_key":
					sym = "mouse_right_outline"
				else:
					var device_type := GlyphManager.get_device_type(player.input_device)
					sym = GlyphManager.get_glyph(device_type, glyph_key)
				display.text = "[font=res://addons/input_prompt_icon_font/icon.ttf]

	"+sym+"[/font]
	Special(Charged)
	[font_size=48]Hit enemies to build charge"
		
	
	return text


var transitioning : bool = false
func phase_transition(_phase1 : int,phase2 : int):
	if transitioning: return
	transitioning = true
	if phase2 > requirements.size() - 1:
		phase=-1
		var tween = create_tween()
		tween.tween_property(display, "modulate:a", 0.0, 0.4)
		await tween.finished
		player_req = [[0.0,0.0,0.0,0.0,0.0],[0.0,0.0,0.0,0.0,0.0]]
		transitioning = false
		Globals.has_gotten_tutorial = true
		get_tree().get_root().get_node("LayerManager")._enable_pathways()
		return

	phase = phase2

	# Fade out then fade in
	var tween = create_tween()
	tween.tween_property(display, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func():
		get_1st_text()
		update_display()
	)
	tween.tween_property(display, "modulate:a", 1.0, 0.4)
	transitioning = false
