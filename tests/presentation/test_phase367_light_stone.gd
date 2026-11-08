extends GdUnitTestSuite
## Fase 367: com o MegaKit, a pedra clara gerada no código no tom da cantaria do pacote (o parâmetro do material segue a troca).


func after_test() -> void:
	BuildingKit.reset_megakit()


func _stone() -> float:
	var value: Variant = BuildingMaterials.kit().get_shader_parameter(&"megakit_stone")
	return value if value is float else -1.0


func test_the_material_follows_the_megakit() -> void:
	BuildingKit.use_megakit(true)
	assert_float(_stone()).is_equal(1.0)
	BuildingKit.use_megakit(false)
	assert_float(_stone()).is_equal(0.0)
	BuildingKit.use_megakit(true)
	assert_float(_stone()).is_equal(1.0)


func test_the_shader_has_the_stone_uniforms() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var names: Array[String] = []
	for uniform: Dictionary in BuildingMaterials.kit().shader.get_shader_uniform_list():
		var name: String = uniform["name"]
		names.append(name)
	for wanted: String in ["megakit_stone", "megakit_stone_color", "megakit_stone_mottle"]:
		assert_bool(names.has(wanted)).override_failure_message(wanted).is_true()

