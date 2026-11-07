extends GdUnitTestSuite
## Leque de cascalho (Fase 347): no shader do terreno, o cascalho cinza no pé das encostas de rocha (encosta íngreme por perto, chão
## quase plano e côncavo), recortado por ruído e fora da areia, da lama, da rocha e da água; compila (com tela).

const TERRAIN := "res://shaders/terrain.gdshader"


func test_the_scree_sits_at_the_foot() -> void:
	var code := FileAccess.get_file_as_string(TERRAIN)
	var at := code.find("if (scree_foot > 0.0) {")
	assert_int(at).is_greater(code.find("float land = step(0.0, world_position.y);"))
	var block := code.substr(at, code.find("\n\t}\n", at) - at)
	# íngreme por perto, o próprio chão plano e côncavo
	assert_str(block).contains("steep_near")
	assert_str(block).contains("(1.0 - smoothstep(0.12, 0.26, data.r))")
	assert_str(block).contains("smoothstep(0.48, 0.56, data.g)")
	assert_str(block).contains("(1.0 - sand) * (1.0 - mud) * (1.0 - rock) * land")


func test_the_shader_compiles_with_the_scree() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(TERRAIN) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if DisplayServer.get_name() == "headless":
		return
	for wanted: StringName in [&"scree_foot", &"scree_reach_m", &"scree_scale", &"scree_color"]:
		assert_bool(names.has(wanted)).override_failure_message(wanted).is_true()
