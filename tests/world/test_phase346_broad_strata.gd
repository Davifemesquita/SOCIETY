extends GdUnitTestSuite
## Estratos de longe (Fase 346): as bancadas largas da rocha (strata_broad) entram só de longe, por cima dos estratos de perto, na rocha
## do terreno e nas pedras; os dois shaders compilam (com tela).

const INCLUDE := "res://shaders/rock_strata.gdshaderinc"


func test_the_broad_layers_come_in_from_afar() -> void:
	var code := FileAccess.get_file_as_string(INCLUDE)
	assert_str(code).contains("float strata_broad(vec3 at, vec3 normal_w, float distance_m)")
	assert_float(_float_after(code, "uniform float strata_broad_m = ")).is_greater(_float_after(code, "uniform float strata_m = ") * 3.0)
	assert_float(_float_after(code, "uniform float strata_broad_from_m = ")).is_greater(40.0)
	for path: String in ["res://shaders/terrain.gdshader", "res://shaders/sea_rock.gdshader"]:
		var shader := FileAccess.get_file_as_string(path)
		var broad := shader.find("strata_broad(")
		assert_int(broad).override_failure_message(path).is_greater(shader.find("strata_factor("))


func test_the_shaders_compile_with_the_broad_layers() -> void:
	for path: String in ["res://shaders/terrain.gdshader", "res://shaders/sea_rock.gdshader"]:
		var names: Array[StringName] = []
		for entry: Dictionary in (load(path) as Shader).get_shader_uniform_list():
			var raw: String = entry["name"]
			names.append(StringName(raw))
		if DisplayServer.get_name() == "headless":
			return
		assert_bool(names.has(&"strata_broad_m")).override_failure_message(path).is_true()


func _float_after(code: String, prefix: String) -> float:
	var at := code.find(prefix)
	return code.substr(at + prefix.length(), 10).split(";")[0].to_float()
