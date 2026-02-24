extends Area2D


func dmg_indicate(damage : int, dmg_owner : Node, direction = Vector2(0,-1), attack_body : Node = null):
	if get_parent().current_health >= 0:
		get_tree().get_root().get_node("LayerManager")._damage_indicator(damage, dmg_owner,direction, attack_body,self)

func take_damage(damage : int, dmg_owner : Node, direction = Vector2(0,-1), attack_body : Node = null, i_frames : int = 0,creates_indicators : bool = true):
	if creates_indicators:
		dmg_indicate(damage, dmg_owner, direction, attack_body)
	get_parent().take_damage(damage, dmg_owner, direction, attack_body,i_frames, creates_indicators)
