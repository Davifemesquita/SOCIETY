extends GdUnitTestSuite
## Fendas escuras (Fase 348): planos verticais no mundo (cortes em x e em z), sem a normal na posição das linhas, só nas faces de pé,
## na rocha do terreno e nas pedras; os dois shaders compilam (com tela).

const INCLUDE := "res://shaders/rock_strata.gdshaderinc"


func test_the_cracks_are_world_planes() -> void:
	var code := FileAccess.get_file_as_string(INCLUDE)
	var at := code.find("float crack_factor(vec3 at, vec3 normal_w)")
	assert_int(at).is_greater(0)
	var body := code.substr(at, code.find("\n}\n", at) - at)
	# a normal só decide a face de pé, não o lugar das linhas
	assert_str(body).contains("crack_line(at.x,")
	assert_str(body).contains("crack_line(at.z,")
	assert_str(body).not_contains("normal_w.xz")
	for path: String in ["res://shaders/terrain.gdshader", "res://shaders/sea_rock.gdshader"]:
		var shader := FileAccess.get_file_as_string(path)
		assert_int(shader.find("crack_factor(")).override_failure_message(path).is_greater(shader.find("block_factor("))


func test_the_shaders_compile_with_the_cracks() -> void:
	for path: String in ["res://shaders/terrain.gdshader", "res://shaders/sea_rock.gdshader"]:
		var names: Array[StringName] = []
		for entry: Dictionary in (load(path) as Shader).get_shader_uniform_list():
			var raw: String = entry["name"]
			names.append(StringName(raw))
		if DisplayServer.get_name() == "headless":
			return
		assert_bool(names.has(&"crack_spacing_m")).override_failure_message(path).is_true()
