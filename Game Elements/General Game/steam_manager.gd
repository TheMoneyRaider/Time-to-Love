extends Node

func _ready():
	var init = Steam.steamInitEx()
	print(init)
	if init["status"] != 0:
		print("Steam failed to initialize: ", init["verbal"])
		return
	print("Steam initialized. App ID: ", Steam.getAppID())

func unlock_achievement(achievement_name: String):
	if Steam.isSteamRunning():
		Steam.setAchievement(achievement_name)
		Steam.storeStats()


func clear_all_achievements():
	if !Steam.isSteamRunning():
		print("Steam not available, cannot clear achievements")
		return

	var achievements = [
		"LETTER_1",
		"LETTER_ALL",
		"SHOP",
		"RAND",
		"BIG_T",
		"SIGNUL",
		"VISION",
		"MANCER",
		"MANCER_ALL",
		"FISTS",
		"FISTS_NO_DYING"
	]

	for achievement in achievements:
		Steam.clearAchievement(achievement)

	Steam.storeStats()
	print("All achievements cleared")
