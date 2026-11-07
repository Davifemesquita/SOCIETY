extends GdUnitTestSuite
## Prado sem xadrez (Fase 325): as manchas do prado (Fase 285) saem do meadow_patch.gdshaderinc (ruído de gradiente girado sobre
## as coordenadas torcidas), o mesmo no terreno e no tapete de capim (Fase 286); cobrem o mesmo tanto do prado que o ruído de valor
## de antes (a conta portada para cá); os dois shaders compilam (com tela).

const INCLUDE := "res://shaders/meadow_patch.gdshaderinc"
const SHADERS: Array[String] = ["res://shaders/terrain.gdshader", "res://shaders/grass_carpet.gdshader"]
const PATCH_M := 9.0
const TURN := 0.61
const WARP := 1.0
const WARP_SCALE := 2.6
const GAIN := 0.8


func test_both_shaders_read_the_same_patches() -> void:
	var include := FileAccess.get_file_as_string(INCLUDE)
	for line: String in ["float meadow_gradient(vec2 p) {", "float meadow_patch(vec2 xz, float patch_m) {",
			"float broad = 0.5 + meadow_gradient(a) * MEADOW_GRADIENT_GAIN;", "return broad * 0.7 + fine * 0.3;"]:
		assert_str(include).override_failure_message(line).contains(line)
	for path: String in SHADERS:
		var code := FileAccess.get_file_as_string(path)
		# depois do value_noise, que o include usa
		assert_int(code.find("#include \"%s\"" % INCLUDE)).override_failure_message(path).is_greater(code.find("float value_noise(vec2 p) {"))
		assert_str(code).override_failure_message(path).not_contains("value_noise(world_position.xz / meadow_patch_m)")
		assert_str(code).override_failure_message(path).not_contains("value_noise(origin.xz / meadow_patch_m)")
	assert_str(FileAccess.get_file_as_string(SHADERS[0])).contains("float patch = meadow_patch(world_position.xz, meadow_patch_m);")
	assert_str(FileAccess.get_file_as_string(SHADERS[1])).contains("float patch = meadow_patch(origin.xz, meadow_patch_m);")


func test_the_constants_in_the_test_follow_the_include() -> void:
	var include := FileAccess.get_file_as_string(INCLUDE)
	for pair: Array in [["MEADOW_TURN_RAD", TURN], ["MEADOW_WARP", WARP], ["MEADOW_WARP_SCALE", WARP_SCALE],
			["MEADOW_GRADIENT_GAIN", GAIN]]:
		var wanted: float = pair[1]
		var prefix := "const float %s = " % pair[0]
		var at := include.find(prefix)
		assert_int(at).override_failure_message(prefix).is_greater(0)
		var value := include.substr(at + prefix.length(), 8).split(";")[0].to_float()
		assert_float(value).override_failure_message(prefix).is_equal_approx(wanted, 0.0001)


func test_the_patches_cover_the_same_share_of_the_meadow() -> void:
	# o capim alto e o baixo pelos cortes do terrain.gdshader, numa amostra de 200 x 200 pontos a cada 1,7 m
	var old_tall := 0
	var old_short := 0
	var new_tall := 0
	var new_short := 0
	for y: int in 200:
		for x: int in 200:
			var at := Vector2(x, y) * 1.7 + Vector2(130.0, 270.0)
			var before := _value_noise(at / PATCH_M) * 0.7 + _value_noise(at / (PATCH_M * 0.37)) * 0.3
			var after := _patch(at)
			old_tall += 1 if before > 0.57 else 0
			old_short += 1 if before < 0.43 else 0
			new_tall += 1 if after > 0.57 else 0
			new_short += 1 if after < 0.43 else 0
	var total := 40000.0
	assert_float(new_tall / total).override_failure_message("alto %f contra %f" % [new_tall / total, old_tall / total]) \
			.is_between(old_tall / total - 0.08, old_tall / total + 0.08)
	assert_float(new_short / total).override_failure_message("baixo %f contra %f" % [new_short / total, old_short / total]) \
			.is_between(old_short / total - 0.08, old_short / total + 0.08)
	# e as duas sobram: o prado não vira um tom só
	assert_float(new_tall / total).is_greater(0.15)
	assert_float(new_short / total).is_greater(0.15)


func test_the_shaders_compile() -> void:
	for path: String in SHADERS:
		var names: Array[StringName] = []
		for entry: Dictionary in (load(path) as Shader).get_shader_uniform_list():
			var raw: String = entry["name"]
			names.append(StringName(raw))
		if DisplayServer.get_name() == "headless":
			return
		assert_array(names).override_failure_message(path).is_not_empty()
		assert_bool(names.has(&"meadow_patch_m")).override_failure_message(path).is_true()


# --- a conta dos shaders, portada ---

func _hash21(p: Vector2) -> float:
	var q := Vector2(_fract(p.x * 123.34), _fract(p.y * 456.21))
	var d := q.dot(q + Vector2(45.32, 45.32))
	q += Vector2(d, d)
	return _fract(q.x * q.y)


func _fract(v: float) -> float:
	return v - floorf(v)


func _value_noise(p: Vector2) -> float:
	var i := p.floor()
	var f := p - i
	var u := f * f * (Vector2(3.0, 3.0) - 2.0 * f)
	return lerpf(lerpf(_hash21(i), _hash21(i + Vector2(1, 0)), u.x), lerpf(_hash21(i + Vector2(0, 1)), _hash21(i + Vector2(1, 1)), u.x), u.y)


func _corner(node: Vector2, offset: Vector2) -> float:
	var angle := _hash21(node + Vector2(13.1, 71.7)) * TAU
	return Vector2(cos(angle), sin(angle)).dot(offset)


func _gradient(p: Vector2) -> float:
	var i := p.floor()
	var f := p - i
	var u := Vector2(_quintic(f.x), _quintic(f.y))
	return lerpf(lerpf(_corner(i, f), _corner(i + Vector2(1, 0), f - Vector2(1, 0)), u.x),
			lerpf(_corner(i + Vector2(0, 1), f - Vector2(0, 1)), _corner(i + Vector2(1, 1), f - Vector2(1, 1)), u.x), u.y)


func _quintic(t: float) -> float:
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)


## mat2(vec2(c, s), vec2(-s, c)) * v no GLSL (colunas): (c·x − s·y, s·x + c·y)
func _turn(v: Vector2) -> Vector2:
	return Vector2(cos(TURN) * v.x - sin(TURN) * v.y, sin(TURN) * v.x + cos(TURN) * v.y)


func _patch(xz: Vector2) -> float:
	var wide := xz / (PATCH_M * WARP_SCALE)
	var warp := Vector2(_value_noise(wide), _value_noise(wide + Vector2(31.7, 11.3))) - Vector2(0.5, 0.5)
	var a := _turn((xz + warp * PATCH_M * WARP) / PATCH_M)
	var broad := 0.5 + _gradient(a) * GAIN
	# (Fase 334: a oitava fina também de gradiente)
	var fine := 0.5 + _gradient(_turn(a) / 0.37 + Vector2(5.3, 9.1)) * GAIN
	return broad * 0.7 + fine * 0.3
