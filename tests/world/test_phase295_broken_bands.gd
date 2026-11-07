extends GdUnitTestSuite
## Espuma em trechos (Fase 295): as bandas de espuma que andam para a praia (Fase 35) se quebram em trechos longe da areia, numa
## linha que sorteia de novo a cada onda; junto da areia ficam inteiras; o shader compila com os uniformes novos (com tela).

const WATER := "res://shaders/water.gdshader"


func _uniform(code: String, name: String) -> float:
	var at := code.find("uniform float %s = " % name)
	return code.substr(at + name.length() + 17, 8).split(";")[0].to_float()


func test_bands_break_offshore_and_stay_whole_by_the_sand() -> void:
	var code := FileAccess.get_file_as_string(WATER)
	var band := code.find("float band = smoothstep(band_sharpness, 1.0, sin(coast_phase(")
	var pieces := code.find("band *= smoothstep(gap, gap + 0.18, pieces);", band)
	assert_int(band).is_greater(0)
	assert_int(pieces).is_greater(band)
	# a falta cresce de band_whole_m até o fim do alcance das bandas, e cada onda sorteia os seus trechos
	for line: String in ["float gap = band_gap * smoothstep(band_whole_m, shore_foam_width_m, shore_m);",
			"float crest = floor(wave_at);",
			"reef_noise(world_coordinates.xz / band_piece_m + vec2(crest * 7.31, crest * 3.17))"]:
		assert_str(code).override_failure_message(line).contains(line)
	assert_float(_uniform(code, "band_whole_m")).is_less(_uniform(code, "shore_foam_width_m"))
	assert_float(_uniform(code, "band_gap")).is_between(0.2, 0.8)
	assert_float(_uniform(code, "band_piece_m")).is_between(2.0, 20.0)


## A crista da banda é o pico do seno (fase / TAU = 0,25): o número da onda só muda no vale (0,75), onde a banda some.
func test_the_crest_number_changes_only_in_the_trough() -> void:
	var peak := 0.25 - 0.75
	var trough := 0.75 - 0.75
	assert_float(floor(peak + 0.2)).is_equal(floor(peak - 0.2))
	assert_float(floor(trough - 0.01)).is_not_equal(floor(trough + 0.01))


func test_the_shader_compiles_with_the_band_uniforms() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(WATER) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if DisplayServer.get_name() == "headless":
		return
	assert_array(names).is_not_empty()
	for name: StringName in [&"band_piece_m", &"band_gap", &"band_whole_m"]:
		assert_bool(names.has(name)).is_true()
