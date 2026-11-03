extends GdUnitTestSuite
## Blocos na face (Fase 310): o block_factor dos estratos (Voronoi no plano da face, tom e faceta por bloco, juntas escuras) só nas
## faces de pé, chamado pela rocha do terreno e pelas pedras; os dois shaders compilam com os uniformes novos (com tela).

const TERRAIN := "res://shaders/terrain.gdshader"
const SEA_ROCK := "res://shaders/sea_rock.gdshader"


func test_the_blocks_live_in_the_strata_include_and_both_shaders_use_them() -> void:
	var code := FileAccess.get_file_as_string("res://shaders/rock_strata.gdshaderinc")
	for line: String in ["float block_factor(vec3 at, vec3 normal_w) {",
			"float steep = 1.0 - smoothstep(0.45, 0.8, normal_w.y);",
			"float joint = 1.0 - smoothstep(0.0, block_joint_m / block_m, second - first);",
			"vec3 q = vec3(at.x, at.y * 1.45, at.z) / block_m;"]:
		assert_str(code).override_failure_message(line).contains(line)
	var terrain := FileAccess.get_file_as_string(TERRAIN)
	assert_int(terrain.find("rock_a.rgb *= block_factor(world_position, world_normal);")).is_greater(
			terrain.find("rock_a.rgb *= strata_factor(world_position, world_normal);"))
	assert_str(FileAccess.get_file_as_string(SEA_ROCK)).contains("color *= block_factor(world_position, world_normal);")


func test_the_shaders_compile_with_the_block_uniforms() -> void:
	for path: String in [TERRAIN, SEA_ROCK]:
		var names: Array[StringName] = []
		for entry: Dictionary in (load(path) as Shader).get_shader_uniform_list():
			var raw: String = entry["name"]
			names.append(StringName(raw))
		if DisplayServer.get_name() == "headless":
			return
		assert_array(names).override_failure_message(path).is_not_empty()
		for name: StringName in [&"block_m", &"block_joint_m", &"block_joint_dark", &"block_tone", &"block_light",
				&"block_light_dir"]:
			assert_bool(names.has(name)).override_failure_message(path + " " + name).is_true()
