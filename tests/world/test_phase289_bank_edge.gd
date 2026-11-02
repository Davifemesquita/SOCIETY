extends GdUnitTestSuite
## Beira do barranco (Fase 289): no terreno, a faixa de terra, pedras e raízes na crista, onde a encosta começa logo adiante,
## fora da rocha, da areia e da lama, de borda recortada; o shader compila com os uniformes novos (com tela); e os dados do
## terreno marcam a crista de um barranco (curvatura abaixo do meio, inclinação subindo).

const TERRAIN := "res://shaders/terrain.gdshader"


func test_the_shader_has_the_bank_uniforms() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(TERRAIN) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if names.is_empty():
		# sem tela (dummy) a lista vem vazia: o shader só compila com GPU
		return
	for uniform_name: StringName in [&"bank_edge", &"bank_slope", &"bank_soil_tint", &"bank_stone_scale", &"bank_root_color"]:
		assert_bool(names.has(uniform_name)).override_failure_message(uniform_name).is_true()


func test_the_band_sits_on_the_crest_off_rock_sand_and_mud() -> void:
	var code := FileAccess.get_file_as_string(TERRAIN)
	var band_at := code.find("if (bank_edge > 0.0) {")
	# depois da lama (a última camada antes das estradas) e antes das estradas pintadas
	assert_int(band_at).is_greater(code.find("ground_n = mix(ground_n, mud_n, mud * (1.0 - rock));"))
	assert_int(code.find("if (has_roads) {", band_at)).is_greater(band_at)
	for line: String in ["float crest = 1.0 - smoothstep(0.42, 0.47, data.g);",
			"float near_slope = smoothstep(bank_slope.x, bank_slope.y, data.r);",
			"float band = near_slope * crest * (1.0 - rock) * (1.0 - sand) * (1.0 - mud) * bank_edge;"]:
		assert_str(code).override_failure_message(line).contains(line)
	# a faixa começa antes da rocha (que vem com a normal a 0,86, ~31°: 0,34 da inclinação dos dados)
	var slope := code.substr(code.find("uniform vec2 bank_slope = vec2(") + 31, 20).split(")")[0].split(",")
	assert_float(slope[1].to_float()).is_less(0.34)


func test_the_bake_marks_a_crest_above_a_bank() -> void:
	# uma rampa: plano em cima (x < 10), encosta de 45° descendo, plano embaixo
	var side := 33
	var heights := PackedFloat32Array()
	heights.resize(side * side)
	for y: int in side:
		for x: int in side:
			heights[y * side + x] = 10.0 - clampf((x - 10) * 2.0, 0.0, 10.0)
	var image := TerrainBake.bake(heights, side, 2.0, 30.0)
	# na crista (a primeira coluna da encosta, ainda quase plana): curvatura abaixo do meio
	var crest := image.get_pixel(10, 16)
	var flat_top := image.get_pixel(4, 16)
	assert_float(crest.g).is_less(0.5)
	assert_float(crest.r).is_greater(flat_top.r)
