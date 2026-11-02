extends GdUnitTestSuite
## Flores miúdas (Fase 287): no terreno, os pontos brancos e amarelos no capim, mais nos prados de flor e no capim baixo, sumindo
## de longe, só na grama; no tapete, a flor do tufo (alfa 0 no vértice) que o shader mostra só em parte deles, pelas mesmas regras;
## os shaders compilam com os uniformes novos (com tela).

const TERRAIN := "res://shaders/terrain.gdshader"
const CARPET := "res://shaders/grass_carpet.gdshader"


func _uniforms(path: String) -> Array[StringName]:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(path) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	return names


func test_the_shaders_have_the_flower_uniforms() -> void:
	var terrain := _uniforms(TERRAIN)
	var carpet := _uniforms(CARPET)
	if terrain.is_empty() or carpet.is_empty():
		# sem tela (dummy) a lista vem vazia: os shaders só compilam com GPU
		return
	for uniform_name: StringName in [&"flower_share", &"flower_cell_m", &"flower_dot_m", &"flower_meadow_m", &"flower_far_m",
			&"flower_white", &"flower_yellow"]:
		assert_bool(terrain.has(uniform_name)).override_failure_message(uniform_name).is_true()
	for uniform_name: StringName in [&"flower_share", &"flower_meadow_m", &"flower_white", &"flower_yellow"]:
		assert_bool(carpet.has(uniform_name)).override_failure_message(uniform_name).is_true()


func test_the_terrain_dots_are_grass_only_and_fade_away() -> void:
	var code := FileAccess.get_file_as_string(TERRAIN)
	var flowers := code.find("if (flower_share > 0.0 && camera_distance < flower_far_m) {")
	assert_int(flowers).is_greater(code.find("if (meadow_patches > 0.0) {"))
	assert_int(code.find("vec4 ground_a = mix(grass_a, forest_a, forest);")).is_greater(flowers)
	var block := code.substr(flowers, code.find("\n\t}\n", flowers) - flowers)
	assert_str(block).contains("grass_a.rgb = mix(grass_a.rgb, flower, petal * near_f);")
	assert_str(block).contains("(1.0 + short_grass * 0.6 - tall * 0.7)")
	for touched: String in ["forest_a", "sand_a", "rock_a"]:
		assert_str(block).override_failure_message(touched).not_contains(touched)


func test_the_carpet_flower_follows_the_same_rules() -> void:
	var mesh := GrassCarpetView.tuft_mesh()
	var arrays := mesh.surface_get_arrays(0)
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var petals := 0
	for i: int in colors.size():
		if colors[i].a < 0.5:
			petals += 1
			assert_float(vertices[i].y).is_equal_approx(GrassCarpetView.FLOWER_HEIGHT_M, 0.001)
	assert_int(petals).is_equal(GrassCarpetView.FLOWER_PETALS * 3)
	var code := FileAccess.get_file_as_string(CARPET)
	assert_str(code).contains("float share = flower_share * bloom * (1.0 + short_grass * 0.6 - tall * 0.7);")
	assert_str(code).contains("VERTEX = vec3(0.0);")
	# a mesma parte e o mesmo prado de flor nos dois shaders
	var terrain := FileAccess.get_file_as_string(TERRAIN)
	for prefix: String in ["uniform float flower_share = ", "uniform float flower_meadow_m = "]:
		assert_float(_number_after(code, prefix)).is_equal(_number_after(terrain, prefix))


func _number_after(code: String, prefix: String) -> float:
	return code.substr(code.find(prefix) + prefix.length(), 8).split(";")[0].to_float()
