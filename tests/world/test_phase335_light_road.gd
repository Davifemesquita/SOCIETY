extends GdUnitTestSuite
## Estrada clara (Fase 335): a terra batida das estradas sai da textura laranja puxada para o cinza-bege (na luminância dela: o claro
## e o escuro da textura ficam) e clareada, antes dos sulcos e das poças; no Anno a estrada é uma faixa clara que se lê de longe.

const TERRAIN := "res://shaders/terrain.gdshader"


func test_the_dirt_leans_to_grey_beige_and_lighter() -> void:
	var code := FileAccess.get_file_as_string(TERRAIN)
	var tint := _vec3_after(code, "uniform vec3 road_tint = vec3(")
	# cinza-bege: quase sem saturação, o vermelho só um pouco acima do azul
	assert_float(tint.x - tint.z).is_between(0.05, 0.2)
	assert_float(tint.y).is_between(tint.z, tint.x)
	assert_float(_float_after(code, "uniform float road_tint_mix = ")).is_between(0.5, 0.95)
	assert_float(_float_after(code, "uniform float road_light = ")).is_greater(1.15)


func test_the_grade_comes_before_the_ruts() -> void:
	var code := FileAccess.get_file_as_string(TERRAIN)
	var grade := code.find("dirt_a.rgb = mix(dirt_a.rgb, dirt_grey, road_tint_mix) * road_light;")
	assert_int(grade).is_greater(0)
	assert_int(code.find("vec3 dirt = dirt_a.rgb * mix(1.0, road_rut_darken, ruts)")).is_greater(grade)


func test_the_shader_compiles_with_the_road_grade() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(TERRAIN) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if DisplayServer.get_name() == "headless":
		return
	for wanted: StringName in [&"road_tint", &"road_tint_mix", &"road_light"]:
		assert_bool(names.has(wanted)).override_failure_message(wanted).is_true()


func _vec3_after(code: String, prefix: String) -> Vector3:
	var at := code.find(prefix)
	var parts := code.substr(at + prefix.length(), 30).split(")")[0].split(",")
	return Vector3(parts[0].to_float(), parts[1].to_float(), parts[2].to_float())


func _float_after(code: String, prefix: String) -> float:
	var at := code.find(prefix)
	return code.substr(at + prefix.length(), 10).split(";")[0].to_float()
