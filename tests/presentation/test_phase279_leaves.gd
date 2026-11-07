extends GdUnitTestSuite
## Folhas recortadas (Fase 279): as árvores de perto (menos o coqueiro) no shader das folhas, as de longe e o coqueiro no de
## sempre; o shader das folhas compila com os uniformes dele e os de sempre; o corpo dividido no foliage.gdshaderinc, com o
## recorte só onde LEAF_DETAIL está definido (as plantações e o capim seguem sem discard).

const TEMPERATE: Array[TreeModel.Species] = [TreeModel.Species.OAK, TreeModel.Species.BEECH, TreeModel.Species.SCOTS_PINE,
		TreeModel.Species.NORWAY_SPRUCE, TreeModel.Species.BIRCH, TreeModel.Species.TROPICAL_BROADLEAF]


func _shader_of(mesh: ArrayMesh) -> String:
	var material := mesh.surface_get_material(0) as ShaderMaterial
	return material.shader.resource_path


func test_near_trees_use_the_leaf_shader_and_far_ones_the_plain_one() -> void:
	for species: TreeModel.Species in TEMPERATE:
		for variant: int in TreeModel.VARIANTS:
			assert_str(_shader_of(TreeModel.mesh(species, variant))).is_equal(TreeModel.TREE_SHADER)
			assert_str(_shader_of(TreeModel.mesh(species, variant, TreeModel.DETAIL_FAR))).is_equal(TreeModel.FOLIAGE_SHADER)
	# o coqueiro, de folhas finas, fica sem recorte
	assert_str(_shader_of(TreeModel.mesh(TreeModel.Species.COCONUT_PALM, 0))).is_equal(TreeModel.FOLIAGE_SHADER)


func test_the_leaf_shader_compiles_with_its_uniforms() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var shader := load(TreeModel.TREE_SHADER) as Shader
	var names: Array[String] = []
	for uniform: Dictionary in shader.get_shader_uniform_list():
		var uniform_name: String = uniform["name"]
		names.append(uniform_name)
	# sem tela (renderer falso) a lista vem vazia: só confere com o shader compilado
	if names.is_empty():
		return
	for wanted: String in ["leaf_size", "leaf_light", "leaf_dark", "leaf_cut", "leaf_far_m", "sway", "leaf_fill", "use_vertex_color"]:
		assert_bool(names.has(wanted)).override_failure_message(wanted).is_true()
	var plain := load(TreeModel.FOLIAGE_SHADER) as Shader
	var plain_names: Array[String] = []
	for uniform: Dictionary in plain.get_shader_uniform_list():
		var uniform_name: String = uniform["name"]
		plain_names.append(uniform_name)
	assert_bool(plain_names.has("sway")).is_true()
	assert_bool(plain_names.has("leaf_cut")).is_false()


func test_the_cut_lives_only_behind_the_define() -> void:
	var body := FileAccess.get_file_as_string("res://shaders/foliage.gdshaderinc")
	var discard_at := body.find("discard;")
	assert_int(discard_at).is_greater(0)
	# o discard está dentro de um bloco LEAF_DETAIL
	var opened := body.rfind("#ifdef LEAF_DETAIL", discard_at)
	var closed := body.rfind("#endif", discard_at)
	assert_int(opened).is_greater(closed)
	assert_str(FileAccess.get_file_as_string(TreeModel.TREE_SHADER)).contains("#define LEAF_DETAIL")
	assert_str(FileAccess.get_file_as_string(TreeModel.FOLIAGE_SHADER)).not_contains("LEAF_DETAIL")
