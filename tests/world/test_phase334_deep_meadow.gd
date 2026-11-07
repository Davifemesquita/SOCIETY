extends GdUnitTestSuite
## Prado fundo (Fase 334): as manchas de capim alto mais escuras (no terreno e no tapete de capim, a mesma cor), e a oitava fina das
## manchas também de ruído de gradiente: com a de valor, as curvas de nível dentro de cada célula eram quase retas e as manchas mais
## escuras saíam em facetas de bordas retas.

const INCLUDE := "res://shaders/meadow_patch.gdshaderinc"


func test_the_fine_octave_is_gradient_noise() -> void:
	var include := FileAccess.get_file_as_string(INCLUDE)
	var at := include.find("float fine = ")
	assert_int(at).is_greater(0)
	var line := include.substr(at, include.find("\n", at) - at)
	assert_str(line).contains("meadow_gradient(")
	assert_str(line).not_contains("value_noise(")


func test_the_tall_grass_is_darker_and_the_same_in_both_shaders() -> void:
	var terrain := _vec3_after(FileAccess.get_file_as_string("res://shaders/terrain.gdshader"), "uniform vec3 meadow_tall_tint = vec3(")
	var carpet := _vec3_after(FileAccess.get_file_as_string("res://shaders/grass_carpet.gdshader"), "uniform vec3 tall_tint = vec3(")
	assert_bool(terrain.is_equal_approx(carpet)).is_true()
	# era (0,64; 0,79; 0,58)
	assert_float(terrain.y).is_less(0.72)
	assert_float(terrain.y).is_greater(terrain.x)


func _vec3_after(code: String, prefix: String) -> Vector3:
	var at := code.find(prefix)
	var parts := code.substr(at + prefix.length(), 30).split(")")[0].split(",")
	return Vector3(parts[0].to_float(), parts[1].to_float(), parts[2].to_float())
