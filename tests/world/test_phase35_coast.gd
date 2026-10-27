extends GdUnitTestSuite
## Costa viva (Fase 35): a distância até a costa com sinal sai das alturas (positiva na terra, negativa na água, com a
## linha d'água onde a altura cruza o zero, desde a Fase 54), é determinística e barata, vira um mapa do arquipélago que a água lê, e os shaders da água e
## do terreno a recebem. O shader só compila com um renderizador de verdade (o CI roda com tela): sem tela, esse teste
## pula.

const SIDE := 33
const SPACING := 2.0


func _heights(height: Callable) -> PackedFloat32Array:
	var heights := PackedFloat32Array()
	heights.resize(SIDE * SIDE)
	for y: int in SIDE:
		for x: int in SIDE:
			heights[y * SIDE + x] = height.call(x, y)
	return heights


func test_straight_coast_is_positive_on_land_negative_at_sea_and_clamped() -> void:
	# mar nas quatro primeiras colunas, terra a 2 m no resto
	var heights := _heights(func(x: int, _y: int) -> float: return -1.0 if x < 4 else 2.0)
	var coast := TerrainBake.signed_coast(heights, SIDE, SPACING, 64.0)
	# a linha d'água fica entre as colunas 3 e 4, onde a altura cruza o zero (de -1 para 2: a um terço do canto do mar)
	assert_float(coast[16 * SIDE + 3]).is_equal_approx(-2.0 / 3.0, 0.001)
	assert_float(coast[16 * SIDE + 4]).is_equal_approx(4.0 / 3.0, 0.001)
	assert_float(coast[16 * SIDE + 0]).is_equal_approx(-6.0 - 2.0 / 3.0, 0.001)
	assert_float(coast[16 * SIDE + 10]).is_equal_approx(12.0 + 4.0 / 3.0, 0.001)
	var clamped := TerrainBake.signed_coast(heights, SIDE, SPACING, 8.0)
	assert_float(clamped[16 * SIDE + 10]).is_equal_approx(8.0, 0.001)
	assert_float(clamped[16 * SIDE + 30]).is_equal_approx(8.0, 0.001)


func test_distance_stays_close_to_euclidean_off_the_axes() -> void:
	# um poço de água no meio da terra
	var coast := TerrainBake.signed_coast(_heights(func(x: int, y: int) -> float: return -1.0 if x == 16 and y == 16 else 3.0),
			SIDE, SPACING, 64.0)
	# de -1 para 3 a água acaba a um quarto do canto do poço
	for offset: Vector2i in [Vector2i(3, 0), Vector2i(3, 3), Vector2i(3, 1), Vector2i(5, 2), Vector2i(7, 4)]:
		var exact := (Vector2(offset).length() - 0.25) * SPACING
		var cell := Vector2i(16, 16) + offset
		assert_float(coast[cell.y * SIDE + cell.x]).override_failure_message("%s longe do euclidiano" % offset) \
				.is_between(exact * 0.97, exact * 1.1)


func test_field_composes_regions_and_falls_to_deep_sea_outside() -> void:
	var land := TerrainBake.signed_coast(_heights(func(_x: int, _y: int) -> float: return 2.0), SIDE, SPACING, 20.0)
	var sea := TerrainBake.signed_coast(_heights(func(_x: int, _y: int) -> float: return -3.0), SIDE, SPACING, 20.0)
	var regions: Array[Dictionary] = [
		{"origin": Vector2(0.0, 0.0), "side": SIDE, "coast": land},
		{"origin": Vector2(128.0, 0.0), "side": SIDE, "coast": sea},
	]
	var field := CoastField.compose(regions, SPACING, 20.0)
	assert_vector(field.origin).is_equal(Vector2.ZERO)
	assert_int(field.size.x).is_equal(roundi((128.0 + (SIDE - 1) * SPACING) / SPACING) + 1)
	assert_int(field.size.y).is_equal(SIDE)
	assert_float(field.at(10.0, 10.0)).is_equal(20.0)
	assert_float(field.at(140.0, 10.0)).is_equal(-20.0)
	# o vão entre as regiões e fora do mapa: mar fundo
	assert_float(field.at(100.0, 10.0)).is_equal(-20.0)
	assert_float(field.at(-50.0, 10.0)).is_equal(-20.0)
	assert_object(field.texture()).is_not_null()
	# meio pixel de margem: o centro do primeiro pixel cai no canto (0, 0)
	assert_vector(field.bounds()).is_equal(Vector4(-1.0, -1.0, field.size.x * SPACING, field.size.y * SPACING))


func test_seed_1840_coast_is_deterministic_and_cheap() -> void:
	var config := GameConfig.get_default()
	var data := GameData.get_default()
	var world := ArchipelagoGenerator.new_world(1840, config, data)
	var total_ms := 0
	for index: int in world.islands.size():
		if world.island(index).flat:
			continue
		var region := ArchipelagoGenerator.region_corners(world, index, config, data)
		var heights: PackedFloat32Array = region["heights"]
		var side: int = region["side"]
		var started := Time.get_ticks_msec()
		var first := TerrainBake.signed_coast(heights, side, config.cell_size_m, config.coast_field_max_m)
		total_ms += Time.get_ticks_msec() - started
		assert_bool(first == TerrainBake.signed_coast(heights, side, config.cell_size_m, config.coast_field_max_m)).is_true()
	print("campo da costa da semente 1840: %d ms" % total_ms)
	# a meta do plano é até 0,5 s a mais no jogo novo; aqui há folga para máquina mais lenta
	assert_int(total_ms).is_less(2000)


func test_terrain_setup_with_the_data_and_the_coast_fits_the_new_game() -> void:
	var config := GameConfig.get_default()
	var world := ArchipelagoGenerator.new_world(1840, config, GameData.get_default())
	var terrain: TerrainView = auto_free(TerrainView.new())
	add_child(terrain)
	var started := Time.get_ticks_msec()
	terrain.setup(world, config, GameData.get_default())
	var total := Time.get_ticks_msec() - started
	print("TerrainView.setup da semente 1840 (malhas, bake e costa): %d ms" % total)
	assert_object(terrain.coast_field()).is_not_null()
	remove_child(terrain)


func test_terrain_and_water_receive_the_same_field() -> void:
	var config := GameConfig.new()
	config.island_sizes_cells = PackedInt32Array([70, 40])
	config.tropical_island_sizes_cells = PackedInt32Array([30])
	var sim := Simulation.new(config, GameData.get_default(), ArchipelagoGenerator.new_world(5, config, GameData.get_default()))
	var terrain: TerrainView = auto_free(TerrainView.new())
	add_child(terrain)
	terrain.setup(sim.world, config, sim.data)
	var field := terrain.coast_field()
	assert_object(field).is_not_null()
	# um canto de terra fica positivo, um de mar fundo fica negativo
	var grid := sim.world.island(0)
	var land := grid.ground.find(IslandGrid.Ground.LAND)
	var sea := grid.ground.find(IslandGrid.Ground.SEA)
	var land_point := grid.cell_world(grid.cell_at(land))
	var sea_point := grid.cell_world(grid.cell_at(sea))
	assert_float(field.at(land_point.x, land_point.z)).is_greater(0.0)
	assert_float(field.at(sea_point.x, sea_point.z)).is_less(0.0)
	for material: ShaderMaterial in terrain.materials():
		assert_bool(material.get_shader_parameter(&"has_coast")).is_true()
		assert_object(material.get_shader_parameter(&"coast_distance")).is_not_null()
	var water: WaterView = auto_free(WaterView.new())
	add_child(water)
	water.setup(sim, field)
	if water.material() != null:
		assert_bool(water.material().get_shader_parameter(&"has_coast")).is_true()
		assert_vector(water.material().get_shader_parameter(&"coast_bounds")).is_equal(field.bounds())
	remove_child(water)
	remove_child(terrain)


func test_shaders_compile_with_the_coast_uniforms() -> void:
	var expected := {
		"res://shaders/water.gdshader": ["has_coast", "coast_field", "coast_bounds", "shelf_m", "shore_foam_width_m"],
		"res://shaders/terrain.gdshader": ["has_coast", "coast_distance", "swash_m", "seabed_deep_m", "hex_tiling"],
	}
	for path: String in expected:
		var names: Array = (load(path) as Shader).get_shader_uniform_list().map(func(uniform: Dictionary) -> String: return uniform["name"])
		if names.is_empty() and DisplayServer.get_name() == "headless":
			# sem renderizador o shader nem é compilado: quem confere é o CI, com tela
			continue
		for uniform: String in expected[path]:
			assert_array(names).override_failure_message("%s sem %s: o shader não compilou?" % [path, uniform]).contains([uniform])
