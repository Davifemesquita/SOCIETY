extends GdUnitTestSuite
## Crista sem risco (Fase 321): nas temperadas, a beira do barranco da Fase 289 acima de gravel_top_m troca a terra alaranjada
## (a textura da estrada) por capim rente e mais escuro, com mais pedra à mostra; as tropicais seguem com a terra; o shader compila
## com os uniformes novos (com tela).

const TERRAIN := "res://shaders/terrain.gdshader"


func test_the_shader_has_the_turf_uniforms() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(TERRAIN) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if names.is_empty():
		# sem tela (dummy) a lista vem vazia: o shader só compila com GPU
		return
	for uniform_name: StringName in [&"bank_edge_grass", &"bank_turf_shade", &"bank_turf_stones"]:
		assert_bool(names.has(uniform_name)).override_failure_message(uniform_name).is_true()


func test_the_edge_soil_turns_to_turf_above_the_gravel() -> void:
	var code := FileAccess.get_file_as_string(TERRAIN)
	var band := code.find("if (bank_edge > 0.0) {")
	var soil := code.find("soil *= bank_soil_tint;", band)
	var turf := code.find("if (bank_edge_grass > 0.0) {", band)
	var mix_at := code.find("vec3 edge_rgb = mix(soil, stone, stones);", band)
	assert_int(band).is_greater(0)
	# depois da terra de antes e antes de a cor da beira sair dela
	assert_int(turf).is_greater(soil)
	assert_int(mix_at).is_greater(turf)
	for line: String in [
			"float high = smoothstep(gravel_top_m, gravel_top_m + high_bank_fade_m, world_position.y) * bank_edge_grass;",
			"soil = mix(soil, ground_a.rgb * bank_turf_shade, high);",
			"stones = mix(stones, smoothstep(bank_turf_stones.x, bank_turf_stones.y, stone_a.a), high);"]:
		assert_int(code.find(line, turf)).override_failure_message(line).is_greater(turf)
	# mais pedra à mostra que a beira de antes (que começava em 0,55)
	assert_str(code).contains("uniform vec2 bank_turf_stones = vec2(0.45, 0.62);")
	# desligado por padrão: quem liga é a TerrainView
	assert_str(code).contains("uniform float bank_edge_grass = 0.0;")


func test_temperate_islands_get_the_turf_and_tropical_ones_keep_the_soil() -> void:
	var config := GameConfig.new()
	config.island_sizes_cells = PackedInt32Array([60])
	config.tropical_island_sizes_cells = PackedInt32Array([30])
	var data := GameData.get_default()
	var sim := Simulation.new(config, data, ArchipelagoGenerator.new_world(1840, config, data))
	var view: TerrainView = auto_free(TerrainView.new())
	add_child(view)
	view.setup(sim.world, config, data)
	var materials := view.materials()
	var temperate := 0
	var tropical := 0
	for index: int in sim.world.islands.size():
		var value: Variant = materials[index].get_shader_parameter(&"bank_edge_grass")
		var on := false
		if value is float:
			var amount: float = value
			on = amount > 0.5
		if sim.world.is_tropical(index, data):
			tropical += 1
			assert_bool(on).is_false()
		else:
			temperate += 1
			assert_bool(on).is_true()
	assert_int(temperate).is_greater(0)
	assert_int(tropical).is_greater(0)
