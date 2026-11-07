extends GdUnitTestSuite
## Onda quebrando (Fase 358): uma crista em breaker_every vira série — banda mais grossa e com menos falhas, no mesmo alcance —,
## depois dos trechos falhados da Fase 295, fora do rio; o shader compila (com tela).

const WATER := "res://shaders/water.gdshader"


func test_every_fourth_crest_breaks_bigger() -> void:
	var code := FileAccess.get_file_as_string(WATER)
	var series := code.find("// Fase 358: a série")
	assert_int(series).is_greater(code.find("band *= smoothstep(gap, gap + 0.18, pieces);"))
	var block := code.substr(series, 900)
	assert_str(block).contains("mod(crest, breaker_every)")
	assert_str(block).contains("(1.0 - channel)")
	assert_float(_float_after(code, "uniform float breaker_sharpness = ")).is_less(_float_after(code, "uniform float band_sharpness = "))
	# no mesmo alcance e ainda em trechos (mais longe ou inteira, virava a fita branca solta no mar)
	assert_str(block).contains("* reach;")
	assert_str(block).contains("pieces)")
	assert_float(_float_after(code, "uniform float breaker_gap_share = ")).is_between(0.2, 0.8)


func test_the_shader_compiles_with_the_breakers() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(WATER) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if DisplayServer.get_name() == "headless":
		return
	assert_bool(names.has(&"breaker_every")).is_true()
	assert_bool(names.has(&"breaker_gap_share")).is_true()


func _float_after(code: String, prefix: String) -> float:
	var at := code.find(prefix)
	return code.substr(at + prefix.length(), 10).split(";")[0].to_float()
