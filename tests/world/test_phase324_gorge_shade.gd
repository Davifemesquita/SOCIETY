extends GdUnitTestSuite
## Fundo na sombra (Fase 324): no canal, a água escurece, reflete menos e fica fosca pelo tanto de céu que as paredes em volta tapam
## (sky_closed: o ângulo mais alto da terra em oito rumos, pela altura da terra do mapa da costa); a conta só roda no canal e tira a
## cintilação junto; o shader compila com os uniformes novos (com tela).

const WATER := "res://shaders/water.gdshader"


func _number(code: String, name: String) -> float:
	var key := "uniform float %s = " % name
	return code.substr(code.find(key) + key.length(), 8).split(";")[0].to_float()


func test_the_sky_is_measured_from_the_land_around() -> void:
	var code := FileAccess.get_file_as_string(WATER)
	var body := code.find("float sky_closed(vec2 xz) {")
	assert_int(body).is_greater(0)
	assert_int(code.find("const int GORGE_DIRECTIONS = 8;")).is_between(0, body)
	for line: String in [
			"float land = textureLod(land_height, uv, 0.0).r;",
			"best = max(best, max(land, 0.0) / length(vec2(d, max(land, 0.0))));",
			"return closed / float(GORGE_DIRECTIONS);"]:
		assert_int(code.find(line, body)).override_failure_message(line).is_greater(body)


func test_the_channel_darkens_under_the_walls() -> void:
	var code := FileAccess.get_file_as_string(WATER)
	var block := code.find("if (gorge_shade > 0.0 && channel > 0.0) {")
	assert_int(block).is_greater(0)
	# depois da sombra da falésia (Fase 314) e antes da cintilação, que ela apaga
	assert_int(block).is_greater(code.find("float cliff_dark = 1.0 - cliff_shade * cliff_shadow("))
	assert_int(code.find("EMISSION += vec3(1.0, 0.95, 0.85) * glint * glint_strength * cliff_dark;")).is_greater(block)
	for line: String in [
			"float deep = smoothstep(gorge_closed.x, gorge_closed.y, sky_closed(world_coordinates.xz)) * channel;",
			"ALBEDO *= 1.0 - gorge_shade * deep;",
			"EMISSION *= 1.0 - gorge_shade * deep;",
			"SPECULAR *= 1.0 - gorge_specular * deep;",
			"ROUGHNESS = mix(ROUGHNESS, gorge_roughness, deep);",
			"cliff_dark *= 1.0 - deep;"]:
		assert_int(code.find(line, block)).override_failure_message(line).is_greater(block)
	# escura mas não preta
	assert_float(_number(code, "gorge_shade")).is_between(0.4, 0.85)
	assert_float(_number(code, "gorge_reach_m")).is_between(4.0, 16.0)


func test_the_shader_compiles_with_the_gorge_uniforms() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(WATER) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if names.is_empty():
		# sem tela (dummy) a lista vem vazia: o shader só compila com GPU
		return
	for uniform_name: StringName in [&"gorge_shade", &"gorge_specular", &"gorge_roughness", &"gorge_closed", &"gorge_reach_m",
			&"gorge_steps"]:
		assert_bool(names.has(uniform_name)).override_failure_message(uniform_name).is_true()
