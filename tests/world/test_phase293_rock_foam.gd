extends GdUnitTestSuite
## Espuma nas pedras (Fase 293): o anel fino de espuma da diferença de profundidade em volta das pedras na água, longe da linha
## d'água (perto dela a espuma da Fase 281 já faz o serviço), fino (rock_foam_m abaixo da faixa larga do Ocean), pulsando e mais
## fraco no rio; o shader compila com o uniforme novo (com tela).

const WATER := "res://shaders/water.gdshader"


func test_the_ring_comes_back_offshore_and_thin() -> void:
	var code := FileAccess.get_file_as_string(WATER)
	var block := code.find("#ifdef SHORE_FOAM\n\tfloat z_diff")
	var ring := code.find("float ring = (1.0 - smoothstep(rock_foam_m * 0.3, rock_foam_m, z_diff))", block)
	assert_int(ring).is_greater(block)
	# depois do corte da Fase 281 e do rio da Fase 283, e somado por max (não reabre a faixa larga)
	assert_int(ring).is_greater(code.find("shore_alpha *= 1.0 - channel;", block))
	for line: String in ["ring *= smoothstep(shore_line_m * 0.4, shore_line_m, from_line) * (1.0 - channel * 0.5) * shore_fade_alpha;",
			"shore_alpha = max(shore_alpha, ring);"]:
		assert_str(code).override_failure_message(line).contains(line)
	# mais fino que a espuma de profundidade do Ocean (o prefab vai de 2 a 6 m)
	var thin := code.substr(code.find("uniform float rock_foam_m = ") + 28, 6).split(";")[0].to_float()
	assert_float(thin).is_between(0.2, 1.0)


func test_the_shader_compiles_with_the_ring_uniform() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(WATER) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if DisplayServer.get_name() == "headless":
		# sem tela (dummy) a lista vem vazia: o shader só compila com GPU
		return
	assert_array(names).is_not_empty()
	assert_bool(names.has(&"rock_foam_m")).is_true()
