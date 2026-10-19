extends GdUnitTestSuite
## Árvores de época (Fase 22): carvalho, faia e pinheiro-silvestre gerados no código, de pé no chão, no
## tamanho certo, dentro do orçamento de triângulos e com a copa onde a espécie a tem.

const SPECIES: Array[TreeModel.Species] = [TreeModel.Species.OAK, TreeModel.Species.BEECH, TreeModel.Species.SCOTS_PINE]


func _triangles(mesh: ArrayMesh) -> int:
	var arrays := mesh.surface_get_arrays(0)
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: Variant = arrays[Mesh.ARRAY_INDEX]
	if indices is PackedInt32Array:
		var list: PackedInt32Array = indices
		return list.size() / 3
	return points.size() / 3


## Altura do vértice de folhagem mais baixo (verde bem acima do vermelho).
func _lowest_leaf(mesh: ArrayMesh) -> float:
	var arrays := mesh.surface_get_arrays(0)
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var lowest := INF
	for i: int in points.size():
		if colors[i].g > colors[i].r * 1.2:
			lowest = minf(lowest, points[i].y)
	return lowest


func test_each_species_stands_on_the_ground_in_its_size_and_budget() -> void:
	for species: TreeModel.Species in SPECIES:
		for variant: int in TreeModel.VARIANTS:
			var mesh := TreeModel.mesh(species, variant)
			var box := mesh.get_aabb()
			var label := "espécie %d, variante %d" % [species, variant]
			# o pé do tronco inclinado desce uns centímetros (a árvore fica 0,1 m enterrada)
			assert_float(box.position.y).override_failure_message(label).is_between(-0.06, 0.01)
			assert_float(box.end.y).override_failure_message(label).is_between(7.0, 11.5)
			assert_int(_triangles(mesh)).override_failure_message(label).is_between(300, 800)
			var far := TreeModel.mesh(species, variant, TreeModel.DETAIL_FAR)
			assert_int(_triangles(far)).override_failure_message(label).is_less(_triangles(mesh) / 3)
			assert_float(far.get_aabb().end.y).override_failure_message(label).is_equal_approx(box.end.y, box.end.y * 0.1)
			var material := mesh.surface_get_material(0) as ShaderMaterial
			assert_str(material.shader.resource_path).is_equal("res://shaders/foliage.gdshader")
			assert_bool(material.get_shader_parameter(&"use_vertex_color")).is_true()


func test_the_oak_is_wide_the_beech_oval_and_the_pine_tall_with_a_crown_on_top() -> void:
	var oak := TreeModel.mesh(TreeModel.Species.OAK, 0).get_aabb()
	var beech := TreeModel.mesh(TreeModel.Species.BEECH, 0).get_aabb()
	var pine_mesh := TreeModel.mesh(TreeModel.Species.SCOTS_PINE, 0)
	var pine := pine_mesh.get_aabb()
	assert_float(oak.size.x).is_greater(oak.size.y * 0.8)
	assert_float(beech.size.y).is_greater(beech.size.x)
	assert_float(pine.size.y).is_greater(oak.size.y)
	# a copa do pinheiro só no último terço; a do carvalho desce mais
	assert_float(_lowest_leaf(pine_mesh)).is_greater(pine.size.y * 0.6)
	assert_float(_lowest_leaf(TreeModel.mesh(TreeModel.Species.OAK, 0))).is_less(oak.size.y * 0.6)


func test_variants_differ_and_the_same_variant_is_cached() -> void:
	var a := TreeModel.mesh(TreeModel.Species.OAK, 0)
	var b := TreeModel.mesh(TreeModel.Species.OAK, 1)
	assert_object(TreeModel.mesh(TreeModel.Species.OAK, 0)).is_same(a)
	assert_bool(a.get_aabb().is_equal_approx(b.get_aabb())).is_false()


func test_the_forest_swaps_to_the_far_trees_away_from_the_camera() -> void:
	var config := GameConfig.get_default()
	var sim := Simulation.new(config, GameData.get_default(), ArchipelagoGenerator.new_world(5, config, GameData.get_default()))
	var view: TreeView = auto_free(TreeView.new())
	add_child(view)
	view.setup(sim.world, sim.data)
	var near := 0
	var far := 0
	for cy: int in 4:
		for cx: int in 4:
			var by_name := {}
			for node: MultiMeshInstance3D in view.chunk_layers(0, Vector2i(cx, cy)):
				by_name[node.name] = node
			for layer_name: String in by_name:
				var node: MultiMeshInstance3D = by_name[layer_name]
				if layer_name.ends_with("Far"):
					far += 1
					var twin: MultiMeshInstance3D = by_name[layer_name.trim_suffix("Far")]
					assert_int(node.multimesh.instance_count).is_equal(twin.multimesh.instance_count)
					assert_float(node.visibility_range_begin).is_equal(twin.visibility_range_end)
					assert_float(node.visibility_range_end).is_equal(TreeView.VISIBLE_UNTIL_M)
				elif layer_name.begins_with("Trees") and int(layer_name.trim_prefix("Trees")) < TreeView.BROADLEAF.size() + TreeView.CONIFER.size():
					near += 1
					assert_float(node.visibility_range_end).is_equal(TreeView.NEAR_UNTIL_M)
	assert_int(near).is_greater(0)
	assert_int(far).is_equal(near)
