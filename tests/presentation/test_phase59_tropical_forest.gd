extends GdUnitTestSuite
## Fase 59: a folhosa tropical gerada no código (TreeModel.Species.TROPICAL_BROADLEAF) — tronco nu e copa em
## guarda-chuva, no tamanho e no orçamento, com malha de longe — e a mata das ilhas tropicais misturando-a aos coqueiros:
## mais coqueiro na terra baixa, mais folhosa no alto, e nenhuma das duas nas ilhas temperadas.

const KIND := TreeModel.Species.TROPICAL_BROADLEAF


func _triangles(mesh: ArrayMesh) -> int:
	var points: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	return points.size() / 3


func _lowest_leaf(mesh: ArrayMesh) -> float:
	var arrays := mesh.surface_get_arrays(0)
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var lowest := INF
	for i: int in points.size():
		if colors[i].g > colors[i].r * 1.4:
			lowest = minf(lowest, points[i].y)
	return lowest


func test_the_tropical_tree_is_an_umbrella_on_a_bare_trunk() -> void:
	for variant: int in TreeView.TROPICAL.size():
		var mesh := TreeModel.mesh(KIND, variant)
		var box := mesh.get_aabb()
		var label := "folhosa tropical %d" % variant
		assert_float(box.position.y).override_failure_message(label).is_between(-0.06, 0.01)
		assert_float(box.end.y).override_failure_message(label).is_between(7.5, 11.5)
		# copa em guarda-chuva: mais larga que alta e só no alto do tronco
		assert_float(minf(box.size.x, box.size.z)).override_failure_message(label).is_greater(box.size.y * 0.6)
		assert_float(_lowest_leaf(mesh)).override_failure_message(label).is_greater(box.end.y * 0.5)
		assert_int(_triangles(mesh)).override_failure_message(label).is_between(300, 800)
		var far := TreeModel.mesh(KIND, variant, TreeModel.DETAIL_FAR)
		assert_int(_triangles(far)).override_failure_message(label).is_less(_triangles(mesh) / 3)
		assert_float(far.get_aabb().end.y).override_failure_message(label).is_equal_approx(box.end.y, box.end.y * 0.1)
	var a := TreeModel.mesh(KIND, 0).get_aabb()
	assert_bool(a.is_equal_approx(TreeModel.mesh(KIND, 1).get_aabb())).is_false()


func test_the_tropical_forest_mixes_palms_low_and_broadleaves_high() -> void:
	var config := GameConfig.get_default()
	var data := GameData.get_default()
	var world := ArchipelagoGenerator.new_world(1840, config, data)
	var view: TreeView = auto_free(TreeView.new())
	add_child(view)
	view.setup(world, data, config)
	var palms := 0
	var broadleaves := 0
	for index: int in world.islands.size():
		if world.is_tropical(index, data):
			palms += view.palm_count(index)
			broadleaves += view.tropical_count(index)
		else:
			assert_int(view.palm_count(index) + view.tropical_count(index)).is_equal(0)
	print("ilhas tropicais: %d coqueiros, %d folhosas" % [palms, broadleaves])
	assert_int(palms).is_greater(0)
	assert_int(broadleaves).is_greater(0)
	# a parte de coqueiros na terra baixa é maior que no alto
	var low := Vector2i.ZERO
	var high := Vector2i.ZERO
	for node: Node in view.get_children():
		var layer := node as MultiMeshInstance3D
		if layer == null or layer.visibility_range_begin > 0.0:
			continue
		var palm := String(layer.name).contains("Palm")
		if not palm and not String(layer.name).contains("Tropical"):
			continue
		for i: int in layer.multimesh.instance_count:
			var origin := layer.multimesh.get_instance_transform(i).origin
			var ground := world.surface_height(origin.x, origin.z)
			var counts := Vector2i(1 if palm else 0, 1)
			if ground < TreeView.PALM_HEIGHT_M:
				low += counts
			else:
				high += counts
	print("coqueiros: %d de %d na terra baixa, %d de %d no alto" % [low.x, low.y, high.x, high.y])
	assert_int(low.y).is_greater(0)
	assert_int(high.y).is_greater(0)
	assert_float(float(low.x) / low.y).is_greater(float(high.x) / high.y + 0.2)
	remove_child(view)
