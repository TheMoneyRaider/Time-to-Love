extends CanvasLayer

var is_multiplayer : bool = true
var debug_mode : bool = false
var menu_indicator : bool = false
var display_paths : bool = false
var toggle_invulnerability : bool = false 
var mouse_clamping : bool = false
@onready var health_bar_1 = $RootControl/Left_Bottom_Corner/HealthBar
@onready var health_bar_2 = $RootControl/Right_Bottom_Corner/HealthBar
@onready var TimeFabric = $RootControl/VBoxContainer/HorizontalSlice/TimeFabric
@onready var LeftCooldownBar = $RootControl/Left_Bottom_Corner/CooldownBar
@onready var RightCooldownBar = $RootControl/Right_Bottom_Corner/CooldownBar
@onready var IconSlotScene = preload("res://Game Elements/ui/remnant_icon.tscn")
const HIGHLIGHT_SHADER := preload("res://Game Elements/ui/highlight.gdshader")
@onready var combo1 = $RootControl/Left_Bottom_Corner/Combo
@onready var combo2 = $RootControl/Right_Bottom_Corner/Combo
var pause_menu : Node = null
var player1
var player2
var player1_max_time = 1.0
var player1_time = 0.0
var player1_combo = 1.0
var player1_combo_inc = 1.0
var player1_combo_max = 1.0
var player2_max_time = 1.0
var player2_time = 0.0
var player2_combo = 1.0
var player2_combo_inc = 1.0
var player2_combo_max = 1.0

func _ready():
	$RootControl/VBoxContainer/Noti.modulate.a = 0.0
	combo1.visible = false
	combo2.visible = false
	LeftCooldownBar.get_node("CooldownBar").material =LeftCooldownBar.get_node("CooldownBar").material.duplicate(true)
	RightCooldownBar.get_node("CooldownBar").material =RightCooldownBar.get_node("CooldownBar").material.duplicate(true)
	load_settings()
	display_debug_setting_header()
	

func set_timefabric_amount(timefabric_collected : int):
	$RootControl/VBoxContainer/HorizontalSlice/TimeFabric/HBoxContainer/Label.text = str(timefabric_collected)

func set_remnant_icons(player1_remnants: Array, player2_remnants: Array, ranked_up1: Array[String] = [], ranked_up2: Array[String] = []):
	for child in $RootControl/VBoxContainer/HorizontalSlice/RemnantIcons/LeftRemnants.get_children():
		child.queue_free()
	for child in $RootControl/VBoxContainer/HorizontalSlice/RemnantIcons/RightRemnants.get_children():
		child.queue_free()
	await get_tree().process_frame
	for remnant in player1_remnants:
		if ranked_up1.has(remnant.remnant_name):
			_add_slot($RootControl/VBoxContainer/HorizontalSlice/RemnantIcons/LeftRemnants, remnant,true,true)
		else:
			_add_slot($RootControl/VBoxContainer/HorizontalSlice/RemnantIcons/LeftRemnants, remnant,false,true)
			
	# --- Populate RIGHT (R->L per row with padding) ---
	var right_grid = $RootControl/VBoxContainer/HorizontalSlice/RemnantIcons/RightRemnants
	var columns = right_grid.columns
	var total_icons = player2_remnants.size()

	for row_start in range(0, total_icons, columns):
		var row := player2_remnants.slice(row_start, row_start + columns)

		var padding = columns - row.size()  # number of empty slots for incomplete row
		var visual_row := []  # final order of things to add (with dummies)
		# Add invisible placeholders first
		for i in range(padding):
			var dummy = Control.new()
			visual_row.append(dummy)

		# Add real remnants, reversed for right->left fill
		row.reverse()
		for remnant in row:
			visual_row.append(remnant)
			# Add to grid
		for item in visual_row:
			if item is Remnant:  # normal remnant
				if ranked_up2.has(item.remnant_name):
					_add_slot(right_grid, item,true,false)
				else:
					_add_slot(right_grid, item,false,false)
			else:  # dummy Control
				right_grid.add_child(item)

	# --- Setup pause menu & focus ---
	if !pause_menu:
		pause_menu = get_node_or_null("../PauseMenu")
	if pause_menu:
		pause_menu.setup($RootControl/VBoxContainer/HorizontalSlice/RemnantIcons/LeftRemnants.get_children())
		pause_menu.setup($RootControl/VBoxContainer/HorizontalSlice/RemnantIcons/RightRemnants.get_children())
	await get_tree().process_frame
	if pause_menu:
		_setup_focus_connections()
	
func _add_slot(grid: Node, remnant: Resource, has_ranked : bool = false, is_purple_icon : bool = false):
	var slot := IconSlotScene.instantiate()
	var label := slot.get_node("Label")
	if has_ranked:
		label.text = _num_to_roman(remnant.rank-1)
	else:
		label.text = _num_to_roman(remnant.rank)
	grid.add_child(slot)
	slot.setup(remnant,is_purple_icon)
	if has_ranked:
		var mat := ShaderMaterial.new()
		mat.shader = HIGHLIGHT_SHADER
		mat.set_shader_parameter("start_time", Time.get_ticks_msec() / 1000.0)
		slot.get_node("TextureRect").material = mat
		await get_tree().create_timer(.5, false).timeout
		label.text = _num_to_roman(remnant.rank)

func _setup_focus_connections():
	var left_grid = $RootControl/VBoxContainer/HorizontalSlice/RemnantIcons/LeftRemnants
	var right_grid = $RootControl/VBoxContainer/HorizontalSlice/RemnantIcons/RightRemnants
	var pause_button = pause_menu.get_node("Control/VBoxContainer/Return")

	_setup_grid_focus(left_grid, left_grid.columns, false)
	_setup_grid_focus(right_grid, right_grid.columns, true)

	_connect_bottom_row_to_pause(left_grid, left_grid.columns, pause_button,true)
	_connect_bottom_row_to_pause(right_grid, right_grid.columns, pause_button,false)
	_connect_grids_horizontally(left_grid, right_grid)

func _setup_grid_focus(grid: GridContainer, columns: int, is_reversed: bool):
	var children = grid.get_children()

	for i in range(children.size()):
		if "remnant" not in children[i]:
			continue
		var btn = children[i].button
		btn.focus_mode = Control.FOCUS_ALL

		var row = i / columns
		var col = i % columns

		# Horizontal neighbors
		if is_reversed:
			# Right grid (R→L visually), so left/right are inverted
			if col > 0:
				if "remnant" in children[i-1]:
					btn.focus_neighbor_left = children[i - 1].button.get_path()
			if col < columns - 1 and i + 1 < children.size():
				if "remnant" in children[i+1]:
					btn.focus_neighbor_right = children[i + 1].button.get_path()
		else:
			# Left grid (L→R normal)
			if col > 0:
				if "remnant" in children[i-1]:
					btn.focus_neighbor_left = children[i - 1].button.get_path()
			if col < columns - 1 and i + 1 < children.size():
				if "remnant" in children[i+1]:
					btn.focus_neighbor_right = children[i + 1].button.get_path()

		# Vertical neighbors (up/down stay normal)
		if row > 0:
			var up_index = (row - 1) * columns + col
			if up_index < children.size():
				if "remnant" in children[up_index]:
					btn.focus_neighbor_top = children[up_index].button.get_path()

		var down_index = (row + 1) * columns + col
		if down_index < children.size():
			if "remnant" in children[down_index]:
				btn.focus_neighbor_bottom = children[down_index].button.get_path()

func _connect_bottom_row_to_pause(grid: GridContainer, columns: int, pause_button: Control, connect_pause : bool):
	var children = grid.get_children()

	# Filter out invisible placeholders
	var visible_children := []
	for child in children:
		if child is Control and "remnant" in child:
			visible_children.append(child)
	if visible_children.is_empty():
		return

	var last_index = visible_children.size() - 1
	var last_row = last_index / columns

	for i in range(visible_children.size()):
		var row = i / columns
		if row == last_row:
			visible_children[i].button.focus_neighbor_bottom = pause_button.get_path()
	if connect_pause:
		pause_button.focus_neighbor_top = visible_children[-1].button.get_path()

func _connect_grids_horizontally(left_grid: GridContainer, right_grid: GridContainer):
	var left_children = left_grid.get_children()
	var right_children = right_grid.get_children()

	var columns = left_grid.columns
	var rows = int(ceil(left_children.size() / float(columns)))

	for row in range(rows):
		for col in range(columns):
			var index = row * columns + col
			
			if index >= left_children.size():
				continue

			var left_btn = left_children[index].button
			var visual_col = col  # left grid is NOT reversed
			
			# RIGHTMOST column of LEFT grid
			if visual_col == columns - 1:
				var right_index = row * columns + (columns - 1 - col)
				
				if right_index < right_children.size():
					var right_btn = right_children[right_index].button
					
					left_btn.focus_neighbor_right = right_btn.get_path()
					right_btn.focus_neighbor_left = left_btn.get_path()

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

func set_players(player1_node : Node, player2_node : Node = null):
	player1 = player1_node
	player2 = player2_node
	if(player2_node == null):
		is_multiplayer = false
		RightCooldownBar.cover_cooldown()
	set_cooldown_icons()
	set_max_cooldowns()

func connect_signals(player_node : Node):
	player_node.player_took_damage.connect(_on_player_take_damage)
	player_node.swapped_color.connect(_on_player_swap)
	player_node.max_health_changed.connect(_on_max_health_changed)
	player_node.special_changed.connect(_on_special_changed)
	player_node.special_reset.connect(_on_special_reset)

func set_max_cooldowns():
	LeftCooldownBar.set_max_cooldown(player1.weapons[1].cooldown)
	RightCooldownBar.set_max_cooldown(player1.weapons[0].cooldown)

func set_cooldowns():
	if is_multiplayer:
		LeftCooldownBar.set_current_cooldown(player1.cooldowns[1])
		RightCooldownBar.set_current_cooldown(player2.cooldowns[0])
	else:
		LeftCooldownBar.set_current_cooldown(player1.cooldowns[1])
		RightCooldownBar.set_current_cooldown(player1.cooldowns[0])

func set_cooldown_icons():
	if is_multiplayer:
		LeftCooldownBar.set_cooldown_icon(player1.weapons[1].cooldown_icon)
		RightCooldownBar.set_cooldown_icon(player2.weapons[0].cooldown_icon)
	else:
		LeftCooldownBar.set_cooldown_icon(player1.weapons[1].cooldown_icon)
		RightCooldownBar.set_cooldown_icon(player1.weapons[0].cooldown_icon)	

func set_cross_position():
	if is_multiplayer:
		RightCooldownBar.offset_left = 1838
		RightCooldownBar.offset_right = 1956
	else:
		RightCooldownBar.offset_left = 94
		RightCooldownBar.offset_right = 212
	
func combo(remnant: Remnant, is_purple : bool):
	if is_purple:
		combo1.visible = true
		player1_max_time = remnant.variable_3_values[remnant.rank-1]
		player1_combo_inc = remnant.variable_1_values[remnant.rank-1]/100.0
		player1_combo_max = 1.0+remnant.variable_2_values[remnant.rank-1]/100.0
		combo1.get_node("TextureProgressBar").max_value = player1_max_time
		combo1.get_node("TextureProgressBar").value = player1_time
		combo1.get_node("TextureProgressBar/Label").text = str(player1_combo)+"x"
	else:
		combo2.visible = true
		player2_max_time = remnant.variable_3_values[remnant.rank-1]
		player2_combo_inc = remnant.variable_1_values[remnant.rank-1]/100.0
		player2_combo_max = 1.0+remnant.variable_2_values[remnant.rank-1]/100.0
		combo2.get_node("TextureProgressBar").max_value = player2_max_time
		combo2.get_node("TextureProgressBar").value = player2_time
		combo2.get_node("TextureProgressBar/Label").text = str(player2_combo)+"x"
	
func combo_change(player_value : bool, increase_value : bool):
	if player_value:
		#Player1
		if increase_value:
			player1_combo = min(player1_combo+player1_combo_inc, player1_combo_max)
			var tween = create_tween()
			var scale_val = (1.0+(player1_combo-1.0)/2.0)*.125
			tween.tween_property(combo1.get_node("TextureProgressBar/Label"), "scale", Vector2(scale_val, scale_val), 0.15)
			tween.tween_property(combo1.get_node("TextureProgressBar/Label"), "scale", Vector2(.125, .125), 0.2)
		else:
			player1_combo = max(player1_combo-player1_combo_inc, 1.0)
		player1_time = player1_max_time
		combo1.get_node("TextureProgressBar/Label").text = str(player1_combo)+"x"
	else:
		#Player2
		if increase_value:
			player2_combo = min(player2_combo+player2_combo_inc, player2_combo_max)
			var tween = create_tween()
			var scale_val = (1.0+(player2_combo-1.0)/2.0)*.125
			tween.tween_property(combo2.get_node("TextureProgressBar/Label"), "scale", Vector2(scale_val, scale_val), 0.15)
			tween.tween_property(combo2.get_node("TextureProgressBar/Label"), "scale", Vector2(.125, .125), 0.2)
		else:
			player2_combo = max(player2_combo-player2_combo_inc, 1.0)
		player2_time = player2_max_time
		combo2.get_node("TextureProgressBar/Label").text = str(player2_combo)+"x"

func _process(delta: float) -> void:
	if !get_tree().paused:
		if is_multiplayer or player1.is_purple:
			player1_time = max(player1_time-delta, 0.0)
		if is_multiplayer or !player1.is_purple:
			player2_time = max(player2_time-delta, 0.0)
		if player1_time != 0.0:
			combo1.get_node("TextureProgressBar").value = player1_time
		if player1_time == 0.0:
			if player1_combo > 1.0:
				combo_change(true, false)
		if player2_time != 0.0:
			combo2.get_node("TextureProgressBar").value = player2_time
		if player2_time == 0.0:
			if player2_combo > 1.0:
				combo_change(false, false)

func _on_player_swap(player_node : Node):
	if player1 == player_node:
		if(!is_multiplayer):
			LeftCooldownBar.cover_cooldown()
			RightCooldownBar.cover_cooldown()

func _on_player_take_damage(_damage_amount : float, current_health : int, player_node : Node, _direction = Vector2(0,-1)):
	if current_health < 0:
		current_health = 0
	if(player_node == player1):
		health_bar_1.set_current_health(current_health)
		if(!is_multiplayer):
			health_bar_2.set_current_health(current_health)
	else:
		health_bar_2.set_current_health(current_health)

func _on_max_health_changed(max_health : int, current_health : int,player_node : Node):
	if(player_node == player1):
		health_bar_1.set_max_health(max_health)
		health_bar_1.set_current_health(current_health)
		if(!is_multiplayer):
			health_bar_2.set_max_health(max_health)
			health_bar_2.set_current_health(current_health)
	else:
		health_bar_2.set_max_health(max_health)
		health_bar_2.set_current_health(current_health)
		
func load_settings():
	if Globals.config_safe:
		debug_mode = Globals.config.get_value("debug", "enabled", false)
		
func display_debug_setting_header():
	$RootControl/DebugMenu/GridContainer.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	if debug_mode == true: 
		$RootControl/DebugMenu/GridContainer.visible = true
		$RootControl/DebugMenu/GridContainer/MenuIndicator.text = "debug menu: H"
		
func _input(event):
	if debug_mode:
		if event.is_action_pressed("display_debug_settings"):
			menu_indicator = !menu_indicator
		
		if event.is_action_pressed("display_paths"):
			display_paths = !display_paths
			if menu_indicator:  
				update_display_paths()
			
		if event.is_action_pressed("toggle_invulnerability"):
			toggle_invulnerability = !toggle_invulnerability
			if menu_indicator:  
				update_invulnerability()
			
		if event.is_action_pressed("mouse_clamp"):
			mouse_clamping = !mouse_clamping
			if menu_indicator:  
				update_clamping()
				
		update_menu_indicator()
	return

# all of these have to be signals. settings menu items don't make sense because individual components 
# update settings at different periods, mostly on load, 

func update_menu_indicator() -> void:
	var paths_string = "  paths: | P | "
	var invul_string = "  invuln: | I | "
	var clamp_string = "  clamp: | C | "
	
	if menu_indicator:
		$RootControl/DebugMenu/GridContainer/Paths.text = paths_string
		update_display_paths()
		$RootControl/DebugMenu/GridContainer/Invulnerability.text = invul_string
		update_invulnerability()
		$RootControl/DebugMenu/GridContainer/Clamping.text = clamp_string
		update_clamping()
	else:
		$RootControl/DebugMenu/GridContainer/Paths.text = ""
		$RootControl/DebugMenu/GridContainer/Invulnerability.text = ""
		$RootControl/DebugMenu/GridContainer/Clamping.text = ""
	return

func update_display_paths() -> void:
	if display_paths:
		$RootControl/DebugMenu/GridContainer/Paths.text += "ON"
	else:
		$RootControl/DebugMenu/GridContainer/Paths.text += "OFF"

func update_invulnerability():
	if toggle_invulnerability:
		$RootControl/DebugMenu/GridContainer/Invulnerability.text += "ON"
	else:
		$RootControl/DebugMenu/GridContainer/Invulnerability.text += "OFF"

func update_clamping():
	if mouse_clamping:
		$RootControl/DebugMenu/GridContainer/Clamping.text += "ON"
	else:
		$RootControl/DebugMenu/GridContainer/Clamping.text += "OFF"

func _on_special_reset(is_purple : bool):
	if is_purple:
		update_shader(LeftCooldownBar.get_node("CooldownBar").material,0.0, true)
		return
	update_shader(RightCooldownBar.get_node("CooldownBar").material,0.0, true)

func _on_special_changed(is_purple : bool, new_progress):
	if is_purple:
		update_shader(LeftCooldownBar.get_node("CooldownBar").material,new_progress)
		return
	update_shader(RightCooldownBar.get_node("CooldownBar").material,new_progress)

func update_shader(material: ShaderMaterial, new_prog : float, reset : bool = false):
	if reset:
		material.set_shader_parameter("prev_progress", 0.0)
		material.set_shader_parameter("progress",  0.0)
		material.set_shader_parameter("time_offset", Time.get_ticks_msec() / 1000.0+material.get_shader_parameter("interp_time"))
		return
		
	
	var t = clamp((Time.get_ticks_msec() / 1000.0 - material.get_shader_parameter("time_offset")) / material.get_shader_parameter("interp_time"), 0.0, 1.0);
	if t >= .98:
		material.set_shader_parameter("prev_progress", material.get_shader_parameter("progress"))
		material.set_shader_parameter("progress", new_prog)
		material.set_shader_parameter("time_offset", Time.get_ticks_msec() / 1000.0-1)
	else:
		var current_progress = lerp(material.get_shader_parameter("prev_progress"), material.get_shader_parameter("progress"), t);
		material.set_shader_parameter("prev_progress", current_progress)
		material.set_shader_parameter("progress", new_prog)
		material.set_shader_parameter("time_offset", Time.get_ticks_msec() / 1000.0-1)
		
func display_notification(text : String, fade_in : float = 1.0, hold : float= 1.0, fade_out : float= 1.0):
	var hud_notification := $RootControl/Notification
	var label := $RootControl/Notification/Noti/RichTextLabel

	label.text = text
	hud_notification.modulate.a = 0.0
	hud_notification.visible = true
	if hud_notification.has_meta("tween"):
		hud_notification.get_meta("tween").kill()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(hud_notification, "modulate:a", 1.0, fade_in)
	tween.tween_interval(hold)
	tween.tween_property(hud_notification, "modulate:a", 0.0, fade_out)

func hide_boss_bar():
	var bossbar = $RootControl/VBoxContainer/BossBar
	var tween = create_tween()
	tween.tween_property(bossbar,"modulate",Color(1.0,1.0,1.0,0.0),1.0)
	await tween.finished
	bossbar.modulate.a = 1.0
	bossbar.visible = false
	

func update_bossbar(prog : float):
	$RootControl/VBoxContainer/BossBar/Overlay.material.set_shader_parameter("progress",prog)

func show_boss_bar(underlay : Texture2D = null,overlay : Texture2D = null, boss_string : String = "", settings : LabelSettings = null,index : int = -1, prog : float = 1.0):
	var bossbar = $RootControl/VBoxContainer/BossBar
	bossbar.visible = true
	var overlay_node = bossbar.get_node("Overlay")
	var boss_name = bossbar.get_node("Label")
	boss_name.label_settings = settings
	boss_name.text = boss_string
	bossbar.get_node("Underlay").texture = underlay
	overlay_node.texture = overlay
	overlay_node.material.set_shader_parameter("effect_index",index)
	overlay_node.material.set_shader_parameter("progress",prog)
	overlay_node.material.set_shader_parameter("image_size",overlay.get_size())
