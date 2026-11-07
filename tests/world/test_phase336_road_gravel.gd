extends GdUnitTestSuite
## Cascalho na estrada (Fase 336): na estrada de terra, pedrinhas de Voronoi com o hash inteiro (as coordenadas do arquipélago são
## grandes), mais no meio, poucas nos sulcos e nenhuma na poça, só perto da câmera; o shader compila (com tela).

const TERRAIN := "res://shaders/terrain.gdshader"


func test_the_gravel_sits_in_the_road_block() -> void:
	var code := FileAccess.get_file_as_string(TERRAIN)
	var gravel := code.find("// Fase 336: o cascalho\n")
	assert_int(gravel).is_greater(code.find("if (has_roads) {"))
	var block := code.substr(gravel, code.find("ground_a.rgb = mix(ground_a.rgb, dirt, road);", gravel) - gravel)
	assert_str(block).contains("strata_hash(")
	assert_str(block).not_contains("sin(")
	assert_str(block).contains("(1.0 - ruts * 0.75)")
	assert_str(block).contains("(1.0 - puddle)")
	assert_str(block).contains("road_gravel_far_m")


func test_the_shader_compiles_with_the_gravel() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(TERRAIN) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if DisplayServer.get_name() == "headless":
		return
	for wanted: StringName in [&"road_gravel_m", &"road_gravel_share", &"road_gravel_color", &"road_gravel_far_m"]:
		assert_bool(names.has(wanted)).override_failure_message(wanted).is_true()
