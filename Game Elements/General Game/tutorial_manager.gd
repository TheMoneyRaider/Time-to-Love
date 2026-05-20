extends Node

var display : Node
var phase = -1

var requirements : Array[float] = [5.0, 5.0, 4.0, 6.0, 2.0]
var player_req : Array[Array] = [[0.0,0.0,0.0,0.0,0.0],[0.0,0.0,0.0,0.0,0.0]]
#Move, tether, slow_tether, attack, special

func activate(display_in : Node):
	display = display_in
	phase=0

func player_moves(is_purple : bool,amount : float):
	if phase!=0: return
	player_req[is_purple as int][phase]+=amount
	update_display()
	if player_req[0][phase] > requirements[phase] and player_req[1][phase] > requirements[phase]:
		phase_transition(0,1)
	pass
	
func player_tethers(is_purple : bool,amount : float):
	if phase!=1: return
	player_req[is_purple as int][phase]+=amount
	update_display()
	if player_req[0][phase] > requirements[phase] and player_req[1][phase] > requirements[phase]:
		phase_transition(0,1)
	pass
	
func player_tethers_short(is_purple : bool,amount : float):
	if phase!=2: return
	player_req[is_purple as int][phase]+=amount
	update_display()
	if player_req[0][phase] > requirements[phase] and player_req[1][phase] > requirements[phase]:
		phase_transition(0,1)
	pass
	
func player_attacks(is_purple : bool,amount : float):
	if phase!=3: return
	player_req[is_purple as int][phase]+=amount
	update_display()
	if player_req[0][phase] > requirements[phase] and player_req[1][phase] > requirements[phase]:
		phase_transition(0,1)
	pass
func player_specials(is_purple : bool,amount : float):
	if phase!=4: return
	player_req[is_purple as int][phase]+=amount
	update_display()
	if player_req[0][phase] > requirements[phase] and player_req[1][phase] > requirements[phase]:
		phase_transition(0,1)
	pass
	
func update_display():
	var requriement = requirements[phase]
	pass
	
func phase_transition(phase1 : int,phase2 : int):
	
	phase+=1
	#Fade out
	#
	#
	##Switch
	#match phase2:
		#0:
		#1:
		#2:
		#3:
			#display.text = "
#
#
#[font=res://addons/input_prompt_icon_font/icon.ttf]mouse_left_outline[/font] / [font=res://addons/input_prompt_icon_font/icon.ttf]playstation_trigger_r2[/font] / [font=res://addons/input_prompt_icon_font/icon.ttf]xbox_rt[/font]
#[code]Attack[/code]"
		#_:
			#display.text = "
			#
			#
			#[font=res://addons/input_prompt_icon_font/icon.ttf]mouse_right_outline[/font] / [font=res://addons/input_prompt_icon_font/icon.ttf]playstation_trigger_r1[/font] / [font=res://addons/input_prompt_icon_font/icon.ttf]xbox_rb[/font]\n[code]Special(Charged)[/code]\n[font_size=48]Hit enemies to build charge"
		#
	#
	
	if phase2 > requirements.size()-1:
		Globals.has_gotten_tutorial =true
		get_tree().get_root().get_node("LayerManager")._enable_pathways()
		return

	#Fade in
	
	
	pass
