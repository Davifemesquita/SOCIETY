extends GdUnitTestSuite
## Rocha cinza (Fase 261): a pedra dos rochedos, das falésias, do rio, dos barrancos e das jazidas e a rocha das encostas do
## terreno puxam o matiz para um cinza claro, guardando o claro e o escuro da textura (saíam marrom-oliva); as pedras soltas
## usam o shader da rocha do mar sem a faixa da maré.


func test_every_stone_takes_the_grey() -> void:
	for material: ShaderMaterial in [RockView.material(), RockView.sea_material()]:
		var grey: Vector3 = material.get_shader_parameter("stone_grey")
		assert_bool(grey.is_equal_approx(RockView.STONE_GREY)).is_true()
		var mix_value: float = material.get_shader_parameter("stone_grey_mix")
		assert_float(mix_value).is_equal_approx(RockView.STONE_GREY_MIX, 0.0001)
		var light: float = material.get_shader_parameter("stone_light")
		assert_float(light).is_equal_approx(RockView.STONE_LIGHT, 0.0001)
	assert_bool(RockView.sea_material().get_shader_parameter("sea")).is_true()
	assert_bool(RockView.material().get_shader_parameter("sea")).is_false()
	# cinza: quase sem matiz, um pouco frio
	assert_float(RockView.STONE_GREY.z).is_greater_equal(RockView.STONE_GREY.x)
	assert_float(RockView.STONE_GREY.x - RockView.STONE_GREY.y).is_less(0.05)
	assert_float(RockView.STONE_GREY_MIX).is_between(0.5, 0.9)
	assert_float(RockView.STONE_LIGHT).is_greater(1.0)


func test_the_shaders_pull_the_rock_to_grey() -> void:
	var stone := (load("res://shaders/sea_rock.gdshader") as Shader).code
	for line: String in ["uniform bool sea = true", "color = mix(color, grey, stone_grey_mix) * stone_light", "if (sea) {"]:
		assert_str(stone).override_failure_message(line).contains(line)
	var terrain := (load("res://shaders/terrain.gdshader") as Shader).code
	for line: String in ["uniform vec3 rock_grey = vec3(0.95, 0.95, 1.0)", "uniform float rock_grey_mix = 0.75",
			"uniform float rock_light = 1.5", "rock_a.rgb = mix(rock_a.rgb, rock_gray, rock_grey_mix) * rock_light"]:
		assert_str(terrain).override_failure_message(line).contains(line)
	# a mesma conta na pedra e no terreno: a falésia e as rochas encaixadas nela casam
	assert_bool(Vector3(0.95, 0.95, 1.0).is_equal_approx(RockView.STONE_GREY)).is_true()
