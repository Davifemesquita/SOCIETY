extends GdUnitTestSuite
## Espuma nas pedras do rio (Fase 318): no canal da Fase 283, o anel da Fase 293 em volta das pedras e dos blocos, mais largo, sem o
## corte da linha d'água (só o fio da margem fica de fora), só no canal e somado por max; o shader compila com os uniformes novos.

const WATER := "res://shaders/water.gdshader"


func test_the_river_ring_sits_in_the_channel_after_the_sea_ring() -> void:
	var code := FileAccess.get_file_as_string(WATER)
	var sea_ring := code.find("shore_alpha = max(shore_alpha, ring);")
	var river := code.find("if (river_foam > 0.0 && channel > 0.0) {")
	assert_int(sea_ring).is_greater(0)
	assert_int(river).is_greater(sea_ring)
	for line: String in [
			"float churn = (1.0 - smoothstep(rock_foam_m * 0.3, rock_foam_m * river_foam_reach, z_diff))",
			"churn *= smoothstep(river_foam_line_m * 0.5, river_foam_line_m, from_line) * channel * river_foam * shore_fade_alpha;",
			"shore_alpha = max(shore_alpha, churn);"]:
		assert_int(code.find(line, river)).override_failure_message(line).is_greater(river)
	# mais largo que o anel do mar, mas ainda um anel (não a faixa do Ocean, de 2 a 6 m)
	var reach := code.substr(code.find("uniform float river_foam_reach = ") + 33, 6).split(";")[0].to_float()
	assert_float(reach).is_between(1.0, 3.0)
	# o fio da margem que fica de fora é bem mais estreito que o corte do mar (shore_line_m)
	var line_m := code.substr(code.find("uniform float river_foam_line_m = ") + 34, 6).split(";")[0].to_float()
	var shore := code.substr(code.find("uniform float shore_line_m = ") + 29, 6).split(";")[0].to_float()
	assert_float(line_m).is_less(shore * 0.5)


func test_the_shader_compiles_with_the_river_foam_uniforms() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(WATER) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if names.is_empty():
		# sem tela (dummy) a lista vem vazia: o shader só compila com GPU
		return
	for uniform_name: StringName in [&"river_foam", &"river_foam_reach", &"river_foam_line_m"]:
		assert_bool(names.has(uniform_name)).override_failure_message(uniform_name).is_true()
