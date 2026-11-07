extends GdUnitTestSuite
## Brilho do sol no mar (Fase 110): o shader da água compila com os uniformes da cintilação; o parâmetro global da direção do
## sol existe no projeto.


func test_the_water_shader_compiles_with_the_glints() -> void:
	var names: Array = (load("res://shaders/water.gdshader") as Shader).get_shader_uniform_list().map(
			func(uniform: Dictionary) -> String: return uniform["name"])
	if names.is_empty() and DisplayServer.get_name() == "headless":
		# sem renderizador o shader nem é compilado: quem confere é a pasta com janela
		return
	for uniform: String in ["glint_strength", "glint_sharpness", "glint_cell_m", "glint_share", "glint_open_m"]:
		assert_array(names).override_failure_message("water.gdshader sem %s: o shader não compilou?" % uniform).contains([uniform])


func test_the_sun_direction_is_a_shader_global() -> void:
	assert_bool(ProjectSettings.has_setting("shader_globals/sun_direction")).is_true()
	# (o shader da água usa o global: se ele faltasse, o teste de cima pegaria a compilação quebrada)
