extends GdUnitTestSuite
## Mar fundo (Fase 280): o mar das temperadas mais fundo e escuro que o das tropicais, com a plataforma mais estreita e menos
## clara; a troca pela borda das regiões tropicais (reef_min_x), com a guarda de quando não há ilha tropical; o shader compila
## com os uniformes novos (com tela).

const WATER := "res://shaders/water.gdshader"


func _default(uniform_name: StringName) -> Variant:
	return RenderingServer.shader_get_parameter_default((load(WATER) as Shader).get_rid(), uniform_name)


func test_the_shader_has_the_cold_sea_uniforms() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(WATER) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if names.is_empty():
		# sem tela (dummy) a lista vem vazia: o shader só compila com GPU
		return
	for uniform_name: StringName in [&"cold_deep", &"cold_shelf", &"cold_shelf_m", &"tropic_blend_m"]:
		assert_bool(names.has(uniform_name)).override_failure_message(uniform_name).is_true()
	if not _default(&"cold_deep") is Color:
		# sem tela o renderer falso lista os uniformes mas não guarda os valores padrão
		return
	var cold: Color = _default(&"cold_deep")
	var cold_shelf: Color = _default(&"cold_shelf")
	var cold_width: float = _default(&"cold_shelf_m")
	# o turquesa das tropicais é o que a WaterView põe (Fase 53)
	assert_float(cold.get_luminance()).is_less(Color(0.05, 0.19, 0.42).get_luminance())
	assert_float(cold_shelf.get_luminance()).is_less(Color(0.24, 0.76, 0.72).get_luminance())
	assert_float(cold_width).is_less(40.0)


func test_the_switch_follows_the_tropical_edge_and_is_guarded() -> void:
	var code := FileAccess.get_file_as_string(WATER)
	assert_str(code).contains("float tropic = reef_min_x > 1e8 ? 0.0 :")
	assert_str(code).contains("mix(cold_deep, color_deep, tropic)")
	assert_str(code).contains("mix(cold_shelf, color_shelf, tropic)")
	assert_str(code).contains("mix(cold_shelf_m, shelf_m, tropic)")
