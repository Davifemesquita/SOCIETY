extends GdUnitTestSuite
## Manchas do prado (Fase 285): o capim alto (mais escuro, mais verde, com mais relevo) e o baixo (mais claro e seco) em manchas
## de alguns metros no shader do terreno, só na grama (antes da mata, da estrada, da areia, da rocha e da lama entrarem); o
## shader compila com os uniformes novos (com tela).

const TERRAIN := "res://shaders/terrain.gdshader"


func test_the_shader_has_the_meadow_uniforms() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(TERRAIN) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if names.is_empty():
		# sem tela (dummy) a lista vem vazia: o shader só compila com GPU
		return
	for uniform_name: StringName in [&"meadow_patches", &"meadow_patch_m", &"meadow_tall_tint", &"meadow_short_tint",
			&"meadow_tall_detail"]:
		assert_bool(names.has(uniform_name)).override_failure_message(uniform_name).is_true()


func test_the_patches_touch_only_the_grass() -> void:
	var code := FileAccess.get_file_as_string(TERRAIN)
	var patches := code.find("if (meadow_patches > 0.0) {")
	assert_int(patches).is_greater(0)
	# depois da cor da grama e antes de qualquer outro chão entrar por cima dela
	assert_int(patches).is_greater(code.find("grass_a.rgb = mix(grass_a.rgb, tinted, grass_tint_mix);"))
	for later: String in ["vec4 ground_a = mix(grass_a, forest_a, forest);", "ground_a = mix(ground_a, sand_a, sand);"]:
		assert_int(code.find(later)).override_failure_message(later).is_greater(patches)
	var block := code.substr(patches, code.find("\n\t}\n", patches) - patches)
	for touched: String in ["forest_a", "sand_a", "rock_a", "mud_a"]:
		assert_str(block).override_failure_message(touched).not_contains(touched)


func test_tall_grass_is_darker_and_short_grass_lighter() -> void:
	var code := FileAccess.get_file_as_string(TERRAIN)
	var tall := _vec3_after(code, "uniform vec3 meadow_tall_tint = vec3(")
	var short := _vec3_after(code, "uniform vec3 meadow_short_tint = vec3(")
	assert_float(tall.x + tall.y + tall.z).is_less(3.0)
	assert_float(short.x + short.y + short.z).is_greater(3.0)
	# o alto puxa para o verde, o baixo para o amarelo (menos azul)
	assert_float(tall.y).is_greater(tall.x)
	assert_float(short.z).is_less(short.x)
	var size := code.substr(code.find("uniform float meadow_patch_m = ") + 31, 5).to_float()
	assert_float(size).is_between(3.0, 12.0)


func _vec3_after(code: String, prefix: String) -> Vector3:
	var at := code.find(prefix)
	var parts := code.substr(at + prefix.length(), 30).split(")")[0].split(",")
	return Vector3(parts[0].to_float(), parts[1].to_float(), parts[2].to_float())
