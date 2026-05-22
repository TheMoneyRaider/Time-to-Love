extends BTAction
class_name BTPlaySound

@export var sounds: Array[AudioStream]
@export var volume_db: float = 0.0
@export var bus: String = "SFX"

func _tick(_delta: float) -> Status:
	if sounds.size() > 0:
		SFXManager.play(sounds[randi() % sounds.size()], volume_db, bus, agent.global_position)
	return SUCCESS
