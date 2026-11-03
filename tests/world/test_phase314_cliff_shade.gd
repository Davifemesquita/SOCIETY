extends GdUnitTestSuite
## Sombra da falésia na água (Fase 314): o CoastField guarda a altura da terra (o mar em 0) nos pixels da distância, e a água marcha
## na direção do sol até cliff_shade_reach_m da costa, escurecendo onde a terra passa do raio de sol; o shader compila (com tela).

const WATER := "res://shaders/water.gdshader"


func test_the_coast_field_keeps_the_land_height() -> void:
	var side := 4
	var coast := PackedFloat32Array()
	var heights := PackedFloat32Array()
	for i: int in side * side:
		coast.append(-5.0 + i)
		heights.append(-3.0 + i * 0.5)
	var regions: Array[Dictionary] = [{"origin": Vector2(10.0, 20.0), "side": side, "coast": coast, "heights": heights}]
	var field := CoastField.compose(regions, 2.0, 64.0)
	assert_int(field.heights.size()).is_equal(field.distances.size())
	for i: int in side * side:
		assert_float(field.heights[i]).is_equal(maxf(heights[i], 0.0))
	assert_object(field.height_texture()).is_not_null()
	# sem as alturas, nada (os testes e as ferramentas antigas)
	var plain: Array[Dictionary] = [{"origin": Vector2.ZERO, "side": side, "coast": coast}]
	assert_object(CoastField.compose(plain, 2.0, 64.0).height_texture()).is_null()


func test_the_water_marches_toward_the_sun() -> void:
	var code := FileAccess.get_file_as_string(WATER)
	for line: String in ["float cliff_shadow(vec2 xz, vec3 sun) {",
			"shade = max(shade, smoothstep(0.0, 1.5, land - d * rise));",
			"float cliff_dark = 1.0 - cliff_shade * cliff_shadow(world_coordinates.xz, sun_direction) * (1.0 - night_light);",
			"EMISSION *= cliff_dark;"]:
		assert_str(code).override_failure_message(line).contains(line)
	var view := FileAccess.get_file_as_string("res://world/water/water_view.gd")
	assert_str(view).contains("_material.set_shader_parameter(&\"has_cliff_shade\", true)")


func test_the_water_shader_compiles_with_the_shade_uniforms() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(WATER) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if DisplayServer.get_name() == "headless":
		return
	assert_array(names).is_not_empty()
	for name: StringName in [&"has_cliff_shade", &"land_height", &"cliff_shade", &"cliff_shade_reach_m", &"cliff_shade_steps"]:
		assert_bool(names.has(name)).override_failure_message(name).is_true()
