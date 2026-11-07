extends GdUnitTestSuite
## Praia de seixos (Fase 292): na areia das temperadas com rocha perto (a inclinação dos dados em quatro lados), em trechos, os
## seixos cinzentos escuros e brilhantes junto da água; a TerrainView liga nas temperadas e não nas tropicais; o shader compila
## com os uniformes novos (com tela).

const TERRAIN := "res://shaders/terrain.gdshader"


func test_the_pebbles_replace_the_sand_near_rock() -> void:
	var code := FileAccess.get_file_as_string(TERRAIN)
	var block := code.find("if (pebble_beach > 0.0) {")
	# depois da areia dourada e antes da areia entrar no chão
	assert_int(block).is_greater(code.find("sand_a.rgb = mix(sand_a.rgb, golden, sand_tint_mix);"))
	assert_int(code.find("ground_a = mix(ground_a, sand_a, sand);")).is_greater(block)
	# a lama (Fase 283) sai da areia de antes: os seixos não chegam nela
	assert_int(code.find("vec3 mud_base = sand_a.rgb")).is_less(block)
	for line: String in ["float pebbly = smoothstep(0.22, 0.38, near_rock)", "sand_a = mix(sand_a, vec4(pebble, joint), pebbly);",
			"mix(1.0, 0.55, wet_pebble)", "mix(0.7, 0.2, wet_pebble)"]:
		assert_str(code).override_failure_message(line).contains(line)


func test_temperate_islands_get_pebble_beaches() -> void:
	var config := GameConfig.new()
	config.island_sizes_cells = PackedInt32Array([60])
	config.tropical_island_sizes_cells = PackedInt32Array([30])
	var data := GameData.get_default()
	var sim := Simulation.new(config, data, ArchipelagoGenerator.new_world(1840, config, data))
	var view: TerrainView = auto_free(TerrainView.new())
	add_child(view)
	view.setup(sim.world, config, data)
	var materials := view.materials()
	for index: int in sim.world.islands.size():
		var pebbles: Variant = materials[index].get_shader_parameter(&"pebble_beach")
		var on := false
		if pebbles is float:
			var amount: float = pebbles
			on = amount > 0.5
		assert_bool(on).is_equal(not sim.world.is_tropical(index, data))


func test_the_shader_compiles_with_the_pebble_uniforms() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(TERRAIN) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if DisplayServer.get_name() == "headless":
		# sem tela (dummy) a lista vem vazia: o shader só compila com GPU
		return
	assert_array(names).is_not_empty()
	for uniform_name: StringName in [&"pebble_beach", &"pebble_reach_m", &"pebble_stretch_m", &"pebble_size_m", &"pebble_color",
			&"pebble_wet_m"]:
		assert_bool(names.has(uniform_name)).override_failure_message(uniform_name).is_true()
