extends Node

var remnant_pool: Array[Resource] = []

func _ready():
	randomize()
	_load_all_remnants()

#Loads all resources from res://remnants/
func _load_all_remnants() -> void:
	#var dir = DirAccess.open("res://Game Elements/Remnants/")
	var dir = ResourceLoader.list_directory("res://Game Elements/Remnants/")

	if dir == null:
		push_error("Remnants folder not found: rres://Game Elements/Remnants/")
		return
	#dir.list_dir_begin()
	#var file_name = dir.get_next()
	
	for file in dir:
		if file.ends_with(".tres"):
			var res = ResourceLoader.load("res://Game Elements/Remnants/" + file)
			if res:
				remnant_pool.append(res)
		#if not dir.current_is_dir() and file_name.ends_with(".tres"):
		#	var res = ResourceLoader.load("res://Game Elements/Remnants/" + file_name)
		#	if res:
		#		remnant_pool.append(res)
		#file_name = dir.get_next()
	#dir.list_dir_end()

#Returns an array of up to `num` unique random remnants from the pool.
func get_random_remnants(num: int = 4, player1_remnants: Array = [], player2_remnants : Array = []) -> Array[Resource]:
	var result: Array[Resource] = []
	if remnant_pool.is_empty():
		return result

	#Split the count
	@warning_ignore("integer_division")
	var half := int(num / 2)
	#Filter pools
	var pool_for_p1: Array = []
	var pool_for_p2: Array = []

	#Arrays of remnant names
	var p1_names: Array = []
	var p2_names: Array = []
	for r in player1_remnants:
		p1_names.append(r.remnant_name)
	for r in player2_remnants:
		p2_names.append(r.remnant_name)
	for rem in remnant_pool:
		if rem.remnant_name not in p1_names and meets_requirements(rem,p1_names):
			pool_for_p1.append(rem)
		if rem.remnant_name not in p2_names and meets_requirements(rem,p2_names):
			pool_for_p2.append(rem)
	# Pick half from each
	_pick_random_unique(pool_for_p1, half, result)
	_pick_random_unique(pool_for_p2, half, result)
	
	var extra := (half * 2) -result.size()
	if extra <= 0:
		return result
	# If we need more remnants
	var combined := (pool_for_p1 + pool_for_p2).duplicate()
	combined.shuffle()
	for rem in combined:
		if rem not in result:
			result.append(rem)
			extra-=1
			if extra <= 0:
				break
	print("Result "+str(result))
	return result
	
func meets_requirements(remnant : Remnant,names : Array[String]):
	for rm in remnant.required_remnants:
		if rm.remnant_name not in names:
			return false
	return true



#Returns an array of up to `num` unique remnants from the two players pools that can be upgraded
func get_remnant_upgrades(num: int = 4, player1_remnants: Array = [], player2_remnants : Array = []) -> Array[Resource]:
	var result: Array[Resource] = []

	#Split the count
	var half := int(num / 2)

	# Pick half from each
	print("Check player 1 remnants")
	_pick_random_upgradable(player1_remnants, half, result)
	print("Check player 2 remnants")
	_pick_random_upgradable(player2_remnants, half, result)
	# If num is odd, pick one more at random from the union without duplicating
	var extra := (half * 2) -result.size()
	if extra <= 0:
		print("Viewable remnants")
		for rem in result:
			print("Name: "+str(rem.remnant_name)+" Rank: "+str(rem.rank))
		return result
	# If we need more remnants
	var combined := (player1_remnants + player2_remnants).duplicate()
	combined.shuffle()
	for rem in combined:
		if rem not in result and rem.rank <= 4:
			result.append(rem)
			extra-=1
			if extra <= 0:
				break
	print("Result "+str(result))
	return result
	

func _pick_random_upgradable(from_pool: Array, amount: int, into: Array):
	var temp = from_pool.duplicate()
	temp.shuffle()
	var am = 0
	for i in range(temp.size()):
		if temp[i] not in into and temp[i].rank <= 4:
			into.append(temp[i])
			am+=1
		if am >= amount:
			for rem in temp:
				print("Name: "+str(rem.remnant_name)+" Rank: "+str(rem.rank))
			break
	
	
func _pick_random_unique(from_pool: Array, amount: int, into: Array):
	var temp = from_pool.duplicate()
	temp.shuffle()
	var am = 0
	for i in range(temp.size()):
		if temp[i] not in into:
			into.append(temp[i])
			am+=1
		if am >= amount:
			break
