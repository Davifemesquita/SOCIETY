extends GdUnitTestSuite
## Beiral saliente (Fase 352): a sombra do beiral no alto da fachada, pelo parâmetro de instância da altura dele (o alto da parede acima
## do piso do modelo), só nas paredes; o beiral mais largo mexia na geometria (o telhado do corpo por cima da ala, a igreja) e ficou
## como estava. O shader compila (com tela).

const KIT := "res://shaders/building_kit.gdshader"


func test_the_eave_band_darkens_the_top_of_the_walls() -> void:
	var code := FileAccess.get_file_as_string(KIT)
	assert_str(code).contains("instance uniform float eave_m = 0.0;")
	var band := code.find("// Fase 352: a sombra do beiral\n")
	assert_int(band).is_greater(code.find("if (wall && abs(world_normal.y) < 0.5) {"))
	assert_str(code.substr(band, 220)).contains("world_position.y - model_floor")
	var view := FileAccess.get_file_as_string("res://presentation/building_view.gd")
	assert_str(view).contains("body.set_instance_shader_parameter(&\"eave_m\", spec.height_m)")
	assert_float(BuildingKit.OVERHANGS_M[0]).is_equal_approx(0.3, 0.001)


func test_the_shader_compiles_with_the_band() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(KIT) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if DisplayServer.get_name() == "headless":
		return
	assert_bool(names.has(&"eave_band_m")).is_true()
	assert_bool(names.has(&"eave_shade")).is_true()
