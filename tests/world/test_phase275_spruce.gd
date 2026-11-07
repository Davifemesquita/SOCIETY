extends GdUnitTestSuite
## Abeto em camadas (Fase 275): a espécie nova no fim do enum, de pé no chão, no tamanho e no orçamento das outras, com a
## folhagem descendo até perto do chão (sem tronco à mostra) e mais larga embaixo que em cima, mais escura que o pinheiro; o
## nível de longe mais leve e da mesma altura; e a mata escolhendo abeto na maior parte das coníferas, pinheiro mais no alto.

const SPRUCE := TreeModel.Species.NORWAY_SPRUCE


func _triangles(mesh: ArrayMesh) -> int:
	var arrays := mesh.surface_get_arrays(0)
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	return points.size() / 3


## Os vértices de folhagem (verde bem acima do vermelho).
func _leaves(mesh: ArrayMesh) -> PackedVector3Array:
	var arrays := mesh.surface_get_arrays(0)
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var found := PackedVector3Array()
	for i: int in points.size():
		if colors[i].g > colors[i].r * 1.4:
			found.append(points[i])
	return found


func test_the_spruce_is_the_last_species() -> void:
	assert_int(SPRUCE).is_greater(TreeModel.Species.TROPICAL_BROADLEAF)


func test_the_spruce_stands_on_the_ground_in_its_size_and_budget() -> void:
	for variant: int in TreeModel.VARIANTS:
		var mesh := TreeModel.mesh(SPRUCE, variant)
		var box := mesh.get_aabb()
		assert_float(box.position.y).is_between(-0.3, 0.01)
		assert_float(box.end.y).is_between(8.0, 10.5)
		assert_int(_triangles(mesh)).is_between(300, 800)
		var far := TreeModel.mesh(SPRUCE, variant, TreeModel.DETAIL_FAR)
		assert_int(_triangles(far)).is_less(_triangles(mesh) / 3)
		assert_float(far.get_aabb().end.y).is_equal_approx(box.end.y, box.end.y * 0.1)
		var material := mesh.surface_get_material(0) as ShaderMaterial
		assert_str(material.shader.resource_path).is_equal(TreeModel.TREE_SHADER)


func test_the_foliage_reaches_down_and_narrows_upward() -> void:
	var mesh := TreeModel.mesh(SPRUCE, 0)
	var height := mesh.get_aabb().end.y
	var leaves := _leaves(mesh)
	var lowest := INF
	var wide_low := 0.0
	var wide_high := 0.0
	for point: Vector3 in leaves:
		lowest = minf(lowest, point.y)
		var reach := Vector2(point.x, point.z).length()
		if point.y < height / 3.0:
			wide_low = maxf(wide_low, reach)
		elif point.y > height * 2.0 / 3.0:
			wide_high = maxf(wide_high, reach)
	# os galhos de baixo escondem o tronco: nada da paliçada do pinheiro
	assert_float(lowest).is_less(0.6)
	assert_float(wide_low).is_greater(wide_high * 2.0)
	# mais estreito que o carvalho
	assert_float(mesh.get_aabb().size.x).is_less(TreeModel.mesh(TreeModel.Species.OAK, 0).get_aabb().size.x)


func test_the_spruce_is_darker_than_the_pine() -> void:
	assert_float(TreeModel.SPRUCE_NEEDLE.get_luminance()).is_less(TreeModel.PINE_NEEDLE.get_luminance())


func test_the_forest_picks_mostly_spruce_and_more_pine_up_high() -> void:
	assert_int(TreeView.CONIFER[0][0]).is_equal(SPRUCE)
	var low_pines := 0
	var high_pines := 0
	var variants := {}
	for i: int in 2000:
		var seed_value := hash([0, i, 0])
		var low := TreeView.conifer_pick(seed_value, 4.0)
		var high := TreeView.conifer_pick(seed_value, TreeView.PINE_HEIGHT_M + 1.0)
		variants[low] = true
		if TreeView.CONIFER[low][0] == TreeModel.Species.SCOTS_PINE:
			low_pines += 1
		if TreeView.CONIFER[high][0] == TreeModel.Species.SCOTS_PINE:
			high_pines += 1
	assert_int(low_pines).is_between(250, 550)
	assert_int(high_pines).is_between(1050, 1350)
	# as quatro coníferas aparecem
	assert_int(variants.size()).is_equal(4)


func test_the_forest_draws_spruces() -> void:
	var config := GameConfig.get_default()
	var sim := Simulation.new(config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, config, GameData.get_default()))
	var view: TreeView = auto_free(TreeView.new())
	add_child(view)
	view.setup(sim.world, sim.data)
	# pela malha (o nome não serve: o Godot renomeia as camadas repetidas de outros trechos)
	var spruce_meshes: Array[Mesh] = [TreeModel.mesh(SPRUCE, 0), TreeModel.mesh(SPRUCE, 1)]
	var pine_meshes: Array[Mesh] = [TreeModel.mesh(TreeModel.Species.SCOTS_PINE, 0), TreeModel.mesh(TreeModel.Species.SCOTS_PINE, 1)]
	var spruces := 0
	var pines := 0
	for node: Node in view.get_children():
		var layer := node as MultiMeshInstance3D
		if layer == null:
			continue
		if layer.multimesh.mesh in spruce_meshes:
			spruces += layer.multimesh.instance_count
		elif layer.multimesh.mesh in pine_meshes:
			pines += layer.multimesh.instance_count
	print("abetos: ", spruces, ", pinheiros: ", pines)
	assert_int(spruces).is_greater(pines)
	assert_int(pines).is_greater(0)
