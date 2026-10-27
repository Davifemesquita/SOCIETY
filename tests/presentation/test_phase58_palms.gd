extends GdUnitTestSuite
## Fase 58: o coqueiro gerado no código (TreeModel.Species.COCONUT_PALM) no lugar das palmeiras do Kenney — de pé no
## chão, no tamanho e no orçamento, com a coroa só no alto, a malha de longe mais leve — e a TreeView desenhando-o nas
## ilhas tropicais, perto e longe.

const PALM := TreeModel.Species.COCONUT_PALM


func _triangles(mesh: ArrayMesh) -> int:
	var points: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	return points.size() / 3


## Altura do vértice de folha mais baixo (verde bem acima do vermelho).
func _lowest_leaf(mesh: ArrayMesh) -> float:
	var arrays := mesh.surface_get_arrays(0)
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var lowest := INF
	for i: int in points.size():
		if colors[i].g > colors[i].r * 1.4:
			lowest = minf(lowest, points[i].y)
	return lowest


func test_the_palm_stands_on_the_ground_with_the_crown_on_top() -> void:
	for variant: int in TreeView.PALMS.size():
		var mesh := TreeModel.mesh(PALM, variant)
		var box := mesh.get_aabb()
		var label := "coqueiro %d" % variant
		assert_float(box.position.y).override_failure_message(label).is_between(-0.01, 0.01)
		assert_float(box.end.y).override_failure_message(label).is_between(7.0, 10.5)
		# copa larga: as folhas abrem mais de 5 m
		assert_float(minf(box.size.x, box.size.z)).override_failure_message(label).is_greater(5.0)
		assert_int(_triangles(mesh)).override_failure_message(label).is_between(300, 800)
		assert_float(_lowest_leaf(mesh)).override_failure_message(label).is_greater(box.end.y * 0.45)
		var far := TreeModel.mesh(PALM, variant, TreeModel.DETAIL_FAR)
		assert_int(_triangles(far)).override_failure_message(label).is_less(_triangles(mesh) / 3)
		assert_float(far.get_aabb().end.y).override_failure_message(label).is_equal_approx(box.end.y, box.end.y * 0.1)
		var material := mesh.surface_get_material(0) as ShaderMaterial
		assert_str(material.shader.resource_path).is_equal("res://shaders/foliage.gdshader")


func test_palm_variants_differ() -> void:
	var a := TreeModel.mesh(PALM, 0).get_aabb()
	var b := TreeModel.mesh(PALM, 1).get_aabb()
	var c := TreeModel.mesh(PALM, 2).get_aabb()
	assert_bool(a.is_equal_approx(b) or b.is_equal_approx(c) or a.is_equal_approx(c)).is_false()


func test_the_tropical_island_draws_the_palm_near_and_far() -> void:
	var config := GameConfig.get_default()
	var data := GameData.get_default()
	var world := ArchipelagoGenerator.new_world(1840, config, data)
	var view: TreeView = auto_free(TreeView.new())
	add_child(view)
	view.setup(world, data, config)
	var tropical := -1
	for index: int in world.islands.size():
		if world.is_tropical(index, data) and view.palm_count(index) > 0:
			tropical = index
	assert_int(tropical).override_failure_message("nenhuma ilha tropical com palmeira").is_greater_equal(0)
	var near := 0
	var far := 0
	var first := TreeView.BROADLEAF.size() + TreeView.CONIFER.size() + TreeView.ROCKS
	for node: Node in view.get_children():
		var layer := node as MultiMeshInstance3D
		# o Godot renomeia as camadas repetidas de outros trechos para "@Palm9Far@123"
		var clean := String(layer.name).trim_prefix("@").get_slice("@", 0) if layer != null else ""
		if not clean.begins_with("Palm"):
			continue
		var model := int(clean.trim_prefix("Palm").trim_suffix("Far"))
		var palm: Array = TreeView.PALMS[model - first]
		var variant: int = palm[1]
		if clean.ends_with("Far"):
			far += layer.multimesh.instance_count
			assert_object(layer.multimesh.mesh).is_same(TreeModel.mesh(PALM, variant, TreeModel.DETAIL_FAR))
		else:
			near += layer.multimesh.instance_count
			assert_object(layer.multimesh.mesh).is_same(TreeModel.mesh(PALM, variant))
			assert_float(layer.visibility_range_end).is_equal(TreeView.NEAR_UNTIL_M)
	print("coqueiros: %d perto, %d longe" % [near, far])
	var counted := 0
	for index: int in world.islands.size():
		counted += view.palm_count(index)
	assert_int(counted).is_equal(near)
	assert_int(near).is_greater(0)
	assert_int(far).is_equal(near)
	remove_child(view)
