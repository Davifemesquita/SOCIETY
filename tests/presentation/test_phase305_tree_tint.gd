extends GdUnitTestSuite
## Tom por árvore (Fase 305): o material das árvores leva a força do tom sorteado (cheia nas folhosas, leve nas coníferas e no
## coqueiro), perto e longe; as plantações e o capim, no mesmo shader, ficam sem; o shader compila com os uniformes novos.

const BROADLEAF: Array[TreeModel.Species] = [TreeModel.Species.OAK, TreeModel.Species.BEECH, TreeModel.Species.BIRCH,
		TreeModel.Species.TROPICAL_BROADLEAF]
const CONIFERS: Array[TreeModel.Species] = [TreeModel.Species.SCOTS_PINE, TreeModel.Species.NORWAY_SPRUCE,
		TreeModel.Species.COCONUT_PALM]


func _tint_of(mesh: ArrayMesh) -> float:
	var material := mesh.surface_get_material(0) as ShaderMaterial
	var value: Variant = material.get_shader_parameter(&"tree_tint")
	if value is float:
		var tint: float = value
		return tint
	return 0.0


func test_broadleaves_get_the_full_tint_and_conifers_a_light_one() -> void:
	for detail: int in [TreeModel.DETAIL_NEAR, TreeModel.DETAIL_FAR]:
		for species: TreeModel.Species in BROADLEAF:
			assert_float(_tint_of(TreeModel.mesh(species, 0, detail))).is_equal(TreeModel.BROADLEAF_TINT)
		for species: TreeModel.Species in CONIFERS:
			assert_float(_tint_of(TreeModel.mesh(species, 0, detail))).is_equal(TreeModel.CONIFER_TINT)
	assert_float(TreeModel.CONIFER_TINT).is_less(TreeModel.BROADLEAF_TINT)
	assert_float(TreeModel.CONIFER_TINT).is_greater(0.0)


func test_crops_and_grass_stay_untinted() -> void:
	var material := CropView.plant_material(BoxMesh.new(), 0.1)
	var value: Variant = material.get_shader_parameter(&"tree_tint")
	if value is float:
		var tint: float = value
		assert_float(tint).is_zero()


func test_the_shaders_compile_with_the_tint_uniforms() -> void:
	if DisplayServer.get_name() == "headless":
		return
	for path: String in [TreeModel.TREE_SHADER, TreeModel.FOLIAGE_SHADER]:
		var names: Array[String] = []
		for uniform: Dictionary in (load(path) as Shader).get_shader_uniform_list():
			var uniform_name: String = uniform["name"]
			names.append(uniform_name)
		# com tela a lista vazia é o shader que não compilou
		assert_bool(names.is_empty()).override_failure_message(path).is_false()
		for wanted: String in ["tree_tint", "tint_dark", "tint_olive", "tint_yellow"]:
			assert_bool(names.has(wanted)).override_failure_message(path + " " + wanted).is_true()
