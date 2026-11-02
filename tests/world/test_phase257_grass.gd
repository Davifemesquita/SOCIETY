extends GdUnitTestSuite
## Grama viva (Fase 257): a grama do terreno puxa o matiz para um verde-amarelado, guardando a luminância da textura, e a
## graduação deixa de puxar para o vermelho e o amarelo (de longe ela saía cor de oliva).


func test_the_grass_is_pulled_to_a_living_green() -> void:
	var code := (load("res://shaders/terrain.gdshader") as Shader).code
	for line: String in ["uniform vec3 grass_tint = vec3(0.52, 1.0, 0.2)", "uniform float grass_tint_mix = 0.6",
			"grass_a.rgb = mix(grass_a.rgb, tinted, grass_tint_mix)", "uniform vec3 grass_grade = vec3(0.6, 1.12, 0.7)",
			"uniform float dry_strength = 0.15"]:
		assert_str(code).override_failure_message(line).contains(line)
	# o puxão vem depois da graduação e da saturação (é ele quem decide o matiz)
	assert_int(code.find("grass_a.rgb = mix(grass_a.rgb, tinted, grass_tint_mix)")).is_greater(
			code.find("grass_a.rgb = max(mix(vec3(grass_luma), grass_a.rgb, grass_saturation), vec3(0.0))"))


func test_the_tint_keeps_the_texture_brightness() -> void:
	# a conta do shader: o verde-alvo escalado para a luminância do texel
	var tint := Vector3(0.52, 1.0, 0.2)
	var weights := Vector3(0.299, 0.587, 0.114)
	for texel: Vector3 in [Vector3(0.3, 0.25, 0.1), Vector3(0.12, 0.1, 0.05), Vector3(0.5, 0.45, 0.3)]:
		var tinted := tint * (texel.dot(weights) / tint.dot(weights))
		assert_float(tinted.dot(weights)).is_equal_approx(texel.dot(weights), 0.0001)
		assert_float(tinted.y).is_greater(tinted.x)
		assert_float(tinted.x).is_greater(tinted.z)
