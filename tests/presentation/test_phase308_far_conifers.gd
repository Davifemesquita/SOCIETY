extends GdUnitTestSuite
## Abetos de longe (Fase 308): o pinheiro e o abeto, perto e longe, levam o escurecido e azulado pela distância; as folhosas, o
## coqueiro e as plantações não; o shader compila com os uniformes novos (com tela).

const CONIFERS: Array[TreeModel.Species] = [TreeModel.Species.SCOTS_PINE, TreeModel.Species.NORWAY_SPRUCE]
const OTHERS: Array[TreeModel.Species] = [TreeModel.Species.OAK, TreeModel.Species.BEECH, TreeModel.Species.BIRCH,
		TreeModel.Species.TROPICAL_BROADLEAF, TreeModel.Species.COCONUT_PALM]


func _cool_of(mesh: Mesh) -> float:
	var material := mesh.surface_get_material(0) as ShaderMaterial
	var value: Variant = material.get_shader_parameter(&"far_cool")
	if value is float:
		var cool: float = value
		return cool
	return 0.0


func test_only_conifers_cool_down_far_away() -> void:
	for detail: int in [TreeModel.DETAIL_NEAR, TreeModel.DETAIL_FAR]:
		for species: TreeModel.Species in CONIFERS:
			assert_float(_cool_of(TreeModel.mesh(species, 0, detail))).is_equal(TreeModel.CONIFER_FAR_COOL)
		for species: TreeModel.Species in OTHERS:
			assert_float(_cool_of(TreeModel.mesh(species, 0, detail))).is_zero()
	var crop := CropView.plant_material(BoxMesh.new(), 0.1)
	var value: Variant = crop.get_shader_parameter(&"far_cool")
	if value is float:
		var cool: float = value
		assert_float(cool).is_zero()


func test_the_shaders_compile_with_the_far_uniforms() -> void:
	if DisplayServer.get_name() == "headless":
		return
	for path: String in [TreeModel.TREE_SHADER, TreeModel.FOLIAGE_SHADER]:
		var names: Array[String] = []
		for uniform: Dictionary in (load(path) as Shader).get_shader_uniform_list():
			var uniform_name: String = uniform["name"]
			names.append(uniform_name)
		assert_bool(names.is_empty()).override_failure_message(path).is_false()
		for wanted: String in ["far_cool", "far_cool_from_m", "far_cool_to_m", "far_cool_tint"]:
			assert_bool(names.has(wanted)).override_failure_message(path + " " + wanted).is_true()
