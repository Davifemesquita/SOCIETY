extends GdUnitTestSuite
## Recife de coral (Fase 125): a borda do recife fica a oeste de todas as ilhas tropicais e a leste de todas as temperadas;
## sem ilha tropical, não há recife; o shader da água compila com os uniformes novos (com tela).


func test_the_reef_starts_between_the_temperate_and_the_tropical_islands() -> void:
	var config := GameConfig.new()
	var data := GameData.get_default()
	var world := ArchipelagoGenerator.new_world(1840, config, data)
	var edge := WaterView.reef_min_x(config, world, data)
	assert_float(edge).is_less(INF)
	for index: int in world.islands.size():
		var rect := world.island(index).world_rect()
		if world.is_tropical(index, data):
			assert_float(rect.position.x).is_greater_equal(edge)
		else:
			assert_float(rect.end.x).is_less_equal(edge)


func test_no_reef_without_tropical_islands() -> void:
	var sim := SimFixture.simulation()
	assert_float(WaterView.reef_min_x(sim.config, sim.world, sim.data)).is_equal(INF)


func test_the_water_shader_has_the_reef_uniforms() -> void:
	var shader := load("res://shaders/water.gdshader") as Shader
	var names: Array[StringName] = []
	for entry: Dictionary in shader.get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if names.is_empty():
		# sem tela (dummy) a lista vem vazia: o shader só compila com GPU
		return
	for uniform_name: StringName in [&"has_reef", &"reef_min_x", &"reef_color", &"reef_share"]:
		assert_bool(names.has(uniform_name)).is_true()
