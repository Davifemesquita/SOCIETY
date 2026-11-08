extends GdUnitTestSuite
## Fase 371: com o MegaKit, as águas de telha levam as telhas redondas do pacote (a camada 7 das pilhas de textura).

const ALBEDO := "res://assets/models/megakit/megakit_albedo_rough.png"
const NORMALS := "res://assets/models/megakit/megakit_normal.png"


func test_the_stacks_have_the_round_tiles() -> void:
	var constants := (load("res://tools/pack_megakit.gd") as GDScript).get_script_constant_map()
	var layers: Array = constants["LAYERS"]
	assert_int(layers.size()).is_equal(8)
	var tiles: Array = layers[7]
	assert_str(str(tiles[0])).is_equal("round_tiles")
	for path: String in [ALBEDO, NORMALS]:
		var stack := load(path) as TextureLayered
		assert_object(stack).override_failure_message(path).is_not_null()
		assert_int(stack.get_layers()).override_failure_message(path).is_equal(layers.size())


func test_the_shader_has_the_tile_uniforms() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var names: Array[String] = []
	for uniform: Dictionary in BuildingMaterials.kit().shader.get_shader_uniform_list():
		var name: String = uniform["name"]
		names.append(name)
	for wanted: String in ["megakit_tile_m", "megakit_tile_tint", "megakit_tile_luma"]:
		assert_bool(names.has(wanted)).override_failure_message(wanted).is_true()
