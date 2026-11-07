extends GdUnitTestSuite
## Praia dourada (Fase 259): a areia mais clara puxa o matiz para um dourado, guardando a luminância da textura (saía
## cinza-taupe), e a lama da margem dos rios segue com a areia de antes.


func test_the_sand_is_pulled_to_gold() -> void:
	var code := (load("res://shaders/terrain.gdshader") as Shader).code
	for line: String in ["uniform vec3 sand_grade = vec3(1.5, 1.35, 1.1)", "uniform vec3 sand_tint = vec3(1.0, 0.82, 0.58)",
			"uniform float sand_tint_mix = 0.55", "sand_a.rgb = mix(sand_a.rgb, golden, sand_tint_mix)"]:
		assert_str(code).override_failure_message(line).contains(line)
	assert_int(code.find("sand_a.rgb = mix(sand_a.rgb, golden, sand_tint_mix)")).is_greater(code.find("sand_a.rgb *= sand_grade"))


func test_the_mud_keeps_the_old_sand() -> void:
	var code := (load("res://shaders/terrain.gdshader") as Shader).code
	assert_str(code).contains("vec3 mud_base = sand_a.rgb * vec3(1.3, 1.2, 1.0)")
	assert_str(code).contains("vec4 mud_a = vec4(mud_base * mud_tint * 1.6, sand_a.a)")
	# a base da lama é lida antes da graduação nova da areia
	assert_int(code.find("vec3 mud_base")).is_less(code.find("sand_a.rgb *= sand_grade"))


func test_the_gold_is_warm() -> void:
	var tint := Vector3(1.0, 0.82, 0.58)
	assert_float(tint.x).is_greater(tint.y)
	assert_float(tint.y).is_greater(tint.z)
