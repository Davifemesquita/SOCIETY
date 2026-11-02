extends GdUnitTestSuite
## Limo na pedra (Fase 184): os rochedos, as rochas da falésia e os matacões do rio usam a rocha do mar (a faixa de limo junto
## da linha d'água), com a mesma textura e o mesmo tom da rocha de sempre; as pedras soltas dos barrancos usam o mesmo
## shader sem a faixa (Fase 261); o shader compila com os uniformes da faixa (com tela).


func test_the_sea_rock_keeps_the_rock_texture_and_tint() -> void:
	var sea := RockView.sea_material()
	var plain := RockView.material()
	assert_str(sea.shader.resource_path).is_equal("res://shaders/sea_rock.gdshader")
	assert_object(sea.get_shader_parameter("albedo_height")).is_equal(plain.get_shader_parameter("albedo_height"))
	assert_object(sea.get_shader_parameter("normal_roughness")).is_equal(plain.get_shader_parameter("normal_roughness"))
	# Fase 261: as pedras soltas usam o mesmo shader, sem a faixa da maré
	assert_object(plain.shader).is_same(sea.shader)
	assert_bool(plain.get_shader_parameter("sea")).is_false()
	var tint: Color = sea.get_shader_parameter("tint")
	assert_bool(tint.is_equal_approx(RockView.TINT)).is_true()
	var meters: float = sea.get_shader_parameter("texture_m")
	assert_float(meters).is_equal_approx(RockView.TEXTURE_M, 0.001)


func test_the_waterline_band_sits_between_the_sea_and_the_wet_rock() -> void:
	var shader := load("res://shaders/sea_rock.gdshader") as Shader
	var names: Array[String] = []
	for uniform: Dictionary in shader.get_shader_uniform_list():
		var name: String = uniform["name"]
		names.append(name)
	if names.is_empty():
		# sem tela o shader não compila e a lista vem vazia
		return
	for wanted: String in ["weed_top_m", "wet_top_m", "weed_light", "weed_dark", "edge_m"]:
		assert_bool(wanted in names).override_failure_message(wanted).is_true()
	# a faixa de limo começa acima do mar e a pedra molhada vai além dela
	var weed: float = RenderingServer.shader_get_parameter_default(shader.get_rid(), "weed_top_m")
	var wet: float = RenderingServer.shader_get_parameter_default(shader.get_rid(), "wet_top_m")
	var edge: float = RenderingServer.shader_get_parameter_default(shader.get_rid(), "edge_m")
	assert_float(weed - edge).is_greater(0.0)
	assert_float(wet).is_greater(weed + edge)
