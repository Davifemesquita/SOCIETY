extends GdUnitTestSuite
## Fases 381 e 383: com o MegaKit, as tábuas do telhado tiram o veio da madeira do pacote e a pedra clara gerada, os blocos da
## cantaria dele; os números ficam no shader do kit (que só compila com tela: a lista vazia é o shader que não compilou).


func test_the_shader_has_the_pack_texture_uniforms() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var names: Array[String] = []
	for uniform: Dictionary in BuildingMaterials.kit().shader.get_shader_uniform_list():
		var name: String = uniform["name"]
		names.append(name)
	assert_bool(names.is_empty()).is_false()
	for wanted: String in ["megakit_shingle_v", "megakit_shingle_luma", "megakit_ashlar_v", "megakit_ashlar_per_m",
			"megakit_ashlar_luma"]:
		assert_bool(names.has(wanted)).override_failure_message(wanted).is_true()


func test_the_bands_stay_inside_the_texture() -> void:
	var shader := (load(BuildingMaterials.KIT_SHADER) as Shader).code
	# a faixa clara da madeira e as quatro fiadas de baixo da cantaria, como em tools/pack_megakit.gd e no BuildingKit
	assert_bool(shader.contains("megakit_shingle_v = vec2(0.02, 0.28)")).is_true()
	assert_bool(shader.contains("megakit_ashlar_v = vec2(%.3f, %.1f)" % [BuildingKit.MEGAKIT_ASHLAR_V.x,
			BuildingKit.MEGAKIT_ASHLAR_V.y])).is_true()
	assert_bool(shader.contains("megakit_ashlar_per_m = %.2f" % BuildingKit.MEGAKIT_ASHLAR_PER_M)).is_true()
