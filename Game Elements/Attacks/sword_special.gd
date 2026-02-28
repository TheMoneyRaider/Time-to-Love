extends MultiMeshInstance2D

func _ready():
	_setup_mesh()


func _setup_mesh():
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	
	# create quad mesh that displays the texture
	var quad := QuadMesh.new()
	quad.size = texture.get_size()
	multimesh.mesh = quad
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	get_tree().create_tween().tween_property(self,"modulate", Color(1.0, 1.0, 1.0, 1.0),.5)
			
func kill():
	var tween = get_tree().create_tween().tween_property(self,"modulate", Color(1.0, 1.0, 1.0, 0.0),.35)
	await tween.finished
	queue_free()

func draw_path(points: PackedVector2Array):
	if points.size() < 2:
		multimesh.instance_count = 0
		return

	
	var transforms : Array[Transform2D] = []
	var tile_width = texture.get_size().x
	var half_width = tile_width * 0.5

	for i in range(points.size() - 1):
		var a = points[i]
		var b = points[i + 1]

		var dir = b - a
		var length = dir.length()
		var angle = dir.angle()
		dir = dir.normalized()


		var dist = half_width
		while dist < length:
			var pos = a + dir * dist
			transforms.append(Transform2D(angle, pos))
			dist += tile_width

	multimesh.instance_count = transforms.size()

	for i in transforms.size():
		multimesh.set_instance_transform_2d(i, transforms[i])
