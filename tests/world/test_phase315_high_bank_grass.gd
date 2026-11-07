extends GdUnitTestSuite
## Capim no alto da garganta (Fase 315): nas temperadas, a lama acima de gravel_top_m (a borda de cima da garganta do rio e as
## manchas no planalto) some no capim, com a borda recortada, antes de entrar na areia, na mata e no chão; as tropicais seguem com
## a laterita (Fase 170); o shader compila com os uniformes novos (com tela).

const TERRAIN := "res://shaders/terrain.gdshader"


func test_the_shader_has_the_high_bank_uniforms() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(TERRAIN) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if names.is_empty():
		# sem tela (dummy) a lista vem vazia: o shader só compila com GPU
		return
	for uniform_name: StringName in [&"high_bank_grass", &"high_bank_fade_m"]:
		assert_bool(names.has(uniform_name)).override_failure_message(uniform_name).is_true()


func test_the_high_mud_fades_into_grass_before_the_layers_use_it() -> void:
	var code := FileAccess.get_file_as_string(TERRAIN)
	var mud_at := code.find("float mud = smoothstep(0.3, 0.7, kinds.b + ragged * 1.2 + edge * 0.5);")
	var fade_at := code.find("mud *= 1.0 - high_bank_grass * above;")
	assert_int(mud_at).is_greater(0)
	assert_int(fade_at).is_greater(mud_at)
	# antes da areia, da mata e da camada da lama no chão
	assert_int(code.find("float sand = height_blend(", mud_at)).is_greater(fade_at)
	assert_int(code.find("ground_a = mix(ground_a, mud_a, mud * (1.0 - rock));")).is_greater(fade_at)
	# acima da altura onde o cascalho da margem acaba, com a borda recortada pelo mesmo ruído da lama
	assert_str(code).contains(
			"smoothstep(gravel_top_m, gravel_top_m + high_bank_fade_m, world_position.y + ragged * high_bank_fade_m)")
	# desligado por padrão: quem liga é a TerrainView
	assert_str(code).contains("uniform float high_bank_grass = 0.0;")


func test_temperate_islands_grow_grass_and_tropical_ones_keep_the_laterite() -> void:
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
		var value: Variant = materials[index].get_shader_parameter(&"high_bank_grass")
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
