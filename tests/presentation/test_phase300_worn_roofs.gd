extends GdUnitTestSuite
## Telhas gastas (Fase 300): nas águas de telha (não no sapê, na ardósia nem na chapa), um tom por casa pelo lugar do prédio, as
## telhas trocadas mais claras, o musgo em manchas e a sujeira escorrida; o shader compila com os uniformes novos (com tela).

const KIT := "res://shaders/building_kit.gdshader"


func test_tile_roofs_are_worn_per_house() -> void:
	var code := FileAccess.get_file_as_string(KIT)
	# o sorteio da casa sai do mesmo hash dos postigos, noutros bits
	assert_str(code).contains("roof_pick = float((h >> 13u) % 1024u) / 1023.0;")
	# só no ramo das telhas, depois da sombra delas
	var tiles := code.find("color *= 1.0 - roof_tile_shade(world_position, world_normal) * tile_strength * near;")
	# (a Fase 371 pôs o gasto também no ramo das telhas redondas do MegaKit, antes deste: procura depois da sombra)
	var wear := code.find("vec3 wear = roof_wear(world_position, world_normal, roof_pick);", tiles)
	assert_int(wear).is_greater(tiles)
	assert_int(wear).is_greater(code.find("} else if (corrugated > 0.5) {"))
	var body := code.substr(tiles, 700)
	for line: String in ["color *= mix(roof_tone_dark, roof_tone_light, roof_pick);",
			"wear.x * near", "roof_moss.rgb", "wear.z * roof_streak_strength"]:
		assert_str(body).override_failure_message(line).contains(line)
	# as telhas trocadas são raras
	var share := code.substr(code.find("uniform float roof_swap_share = ") + 32, 6).split(";")[0].to_float()
	assert_float(share).is_between(0.01, 0.15)


func test_the_shader_compiles_with_the_roof_uniforms() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(KIT) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if DisplayServer.get_name() == "headless":
		return
	assert_array(names).is_not_empty()
	for name: StringName in [&"roof_tone_dark", &"roof_tone_light", &"roof_swap_share", &"roof_moss", &"roof_moss_strength", &"roof_streak_strength"]:
		assert_bool(names.has(name)).is_true()
