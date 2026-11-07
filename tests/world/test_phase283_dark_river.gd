extends GdUnitTestSuite
## Rio escuro (Fase 283): o canal estreito achado pelo mapa da costa (sondas em volta), com a água na cor escura do rio, sem as
## bandas nem a espuma do Ocean e refletindo menos o céu; o cascalho cinza na margem baixa dos rios das temperadas (a TerrainView
## liga o gravel fora das tropicais, que seguem com a laterita); os shaders compilam com os uniformes novos (com tela).

const WATER := "res://shaders/water.gdshader"
const TERRAIN := "res://shaders/terrain.gdshader"


func _uniforms(path: String) -> Array[StringName]:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(path) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	return names


func test_the_shaders_have_the_river_uniforms() -> void:
	var water := _uniforms(WATER)
	var terrain := _uniforms(TERRAIN)
	if water.is_empty() or terrain.is_empty():
		# sem tela (dummy) a lista vem vazia: os shaders só compilam com GPU
		return
	for uniform_name: StringName in [&"channel_probe_m", &"channel_open_m", &"river_color"]:
		assert_bool(water.has(uniform_name)).override_failure_message(uniform_name).is_true()
	for uniform_name: StringName in [&"gravel", &"gravel_color", &"gravel_scale", &"gravel_wet_m", &"gravel_top_m"]:
		assert_bool(terrain.has(uniform_name)).override_failure_message(uniform_name).is_true()


func test_the_channel_is_dark_calm_and_without_foam() -> void:
	var code := FileAccess.get_file_as_string(WATER)
	assert_str(code).contains("channel = 1.0 - smoothstep(channel_open_m * 0.6, channel_open_m, max(open_m, shore_m));")
	for line: String in ["river_color.rgb * water_light, river_color.a * channel", "shore_alpha *= 1.0 - channel;",
			"* (1.0 - channel);", "SPECULAR = mix(SPECULAR, 0.15, channel * 0.75);"]:
		assert_str(code).override_failure_message(line).contains(line)
	# a sonda olha mais longe que a largura do canal: a praia aberta não vira rio
	var probe := code.substr(code.find("uniform float channel_probe_m = ") + 32, 6).to_float()
	var open := code.substr(code.find("uniform float channel_open_m = ") + 31, 6).to_float()
	assert_float(probe).is_greater_equal(open)


func test_temperate_river_banks_are_gravel_and_tropical_ones_laterite() -> void:
	var config := GameConfig.new()
	config.island_sizes_cells = PackedInt32Array([60])
	config.tropical_island_sizes_cells = PackedInt32Array([30])
	var data := GameData.get_default()
	var sim := Simulation.new(config, data, ArchipelagoGenerator.new_world(1840, config, data))
	var view: TerrainView = auto_free(TerrainView.new())
	add_child(view)
	view.setup(sim.world, config, data)
	var materials := view.materials()
	# um material por ilha com relevo, na ordem das ilhas (todas têm relevo no arquipélago)
	assert_int(materials.size()).is_equal(sim.world.islands.size())
	var temperate := 0
	var tropical := 0
	for index: int in sim.world.islands.size():
		var material := materials[index]
		var gravel: Variant = material.get_shader_parameter(&"gravel")
		var on := false
		if gravel is float:
			var amount: float = gravel
			on = amount > 0.5
		if sim.world.is_tropical(index, data):
			tropical += 1
			assert_bool(on).is_false()
		else:
			temperate += 1
			assert_bool(on).is_true()
	assert_int(temperate).is_greater(0)
	assert_int(tropical).is_greater(0)
