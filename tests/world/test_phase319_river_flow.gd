extends GdUnitTestSuite
## Correnteza (Fase 319): no canal da Fase 283, riscos claros e finos andando ao longo do rio, de través do gradiente do mapa da
## costa, virados sempre para o mesmo lado (as duas margens andam juntas), mais compridos que largos e só no canal; o shader compila
## com os uniformes novos (com tela).

const WATER := "res://shaders/water.gdshader"


func _number(code: String, name: String) -> float:
	var key := "uniform float %s = " % name
	return code.substr(code.find(key) + key.length(), 8).split(";")[0].to_float()


func test_the_streaks_run_along_the_channel() -> void:
	var code := FileAccess.get_file_as_string(WATER)
	var block := code.find("if (river_flow > 0.0 && channel > 0.0) {")
	assert_int(block).is_greater(0)
	# depois da espuma da costa (dentro do bloco do mapa da costa)
	assert_int(block).is_greater(code.find("ALBEDO = mix(ALBEDO, shore_foam_color, coast_foam);"))
	for line: String in [
			"vec2 along = normalize(vec2(-grad.y, grad.x));",
			"along *= dot(along, vec2(0.83, 0.56)) < 0.0 ? -1.0 : 1.0;",
			"dot(at_xz, along) - TIME * float(!freeze_time) * river_flow_speed",
			"* river_flow * channel * shore_fade_alpha;"]:
		assert_int(code.find(line, block)).override_failure_message(line).is_greater(block)
	# riscos: bem mais compridos que largos, devagar e fracos (não uma faixa branca)
	assert_float(_number(code, "river_flow_length_m")).is_greater(_number(code, "river_flow_width_m") * 8.0)
	assert_float(_number(code, "river_flow_speed")).is_between(0.1, 2.0)
	assert_float(_number(code, "river_flow")).is_between(0.1, 0.7)


func test_the_shader_compiles_with_the_flow_uniforms() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(WATER) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if names.is_empty():
		# sem tela (dummy) a lista vem vazia: o shader só compila com GPU
		return
	for uniform_name: StringName in [&"river_flow", &"river_flow_length_m", &"river_flow_width_m", &"river_flow_speed",
			&"river_flow_probe_m"]:
		assert_bool(names.has(uniform_name)).override_failure_message(uniform_name).is_true()
