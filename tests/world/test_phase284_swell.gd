extends GdUnitTestSuite
## Marulho (Fase 284): três trens de ondas longas na normal da água, andando com o vento, fora da costa e do rio, com o mais
## curto sumindo de longe e antes do Fresnel (o reflexo segue a ondulação); o shader compila com os uniformes novos (com tela).

const WATER := "res://shaders/water.gdshader"


func test_the_shader_has_the_swell_uniforms() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(WATER) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if names.is_empty():
		# sem tela (dummy) a lista vem vazia: o shader só compila com GPU
		return
	for uniform_name: StringName in [&"swell_strength", &"swell_lengths_m", &"swell_slopes", &"swell_speed", &"swell_open_m"]:
		assert_bool(names.has(uniform_name)).override_failure_message(uniform_name).is_true()


func test_the_swell_bends_the_normal_before_the_reflection() -> void:
	var code := FileAccess.get_file_as_string(WATER)
	var fragment := code.find("void fragment() {")
	var swell := code.find("if (swell_strength > 0.0) {", fragment)
	var fresnel := code.find("fresnel(3.0, NORMAL, VIEW)", fragment)
	assert_int(swell).is_greater(fragment)
	assert_int(fresnel).is_greater(swell)
	# longe da costa, com o vento, e o trem curto sumindo de longe
	for line: String in ["smoothstep(swell_open_m * 0.4, swell_open_m, -coast_at(world_coordinates.xz))",
			"normalize(wind_direction)", "steep *= 1.0 - smoothstep(500.0, 900.0, length(VERTEX));",
			"NORMAL = normalize(NORMAL - (VIEW_MATRIX * vec4(slope.x, 0.0, slope.y, 0.0)).xyz);"]:
		assert_str(code).override_failure_message(line).contains(line)


func test_the_swell_is_long_and_gentle() -> void:
	var code := FileAccess.get_file_as_string(WATER)
	var lengths := _vec3_after(code, "uniform vec3 swell_lengths_m = vec3(")
	var slopes := _vec3_after(code, "uniform vec3 swell_slopes = vec3(")
	# bem mais longas que as ondas de porto da WaterView (até ~10 m) e suaves
	assert_float(minf(lengths.x, minf(lengths.y, lengths.z))).is_greater(15.0)
	assert_float(slopes.x + slopes.y + slopes.z).is_less(0.3)
	# o swell não chega ao rio: começa mais longe da costa que a largura de um canal
	var open := code.substr(code.find("uniform float swell_open_m = ") + 29, 6).to_float()
	var channel := code.substr(code.find("uniform float channel_open_m = ") + 31, 6).to_float()
	assert_float(open * 0.4).is_greater_equal(channel)


func _vec3_after(code: String, prefix: String) -> Vector3:
	var at := code.find(prefix)
	var parts := code.substr(at + prefix.length(), 30).split(")")[0].split(",")
	return Vector3(parts[0].to_float(), parts[1].to_float(), parts[2].to_float())
