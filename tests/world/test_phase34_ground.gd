extends GdUnitTestSuite
## Chão sem xadrez (Fase 34): as texturas de dados do terreno saem só das alturas (inclinação, curvatura, distância da
## água e umidade), são determinísticas e baratas, e o hex-tiling segue o nível gráfico. Roda sem tela: o shader em si
## só se confere com GPU (capturas).

const SIDE := 33
const SPACING := 2.0
const WATER_M := 64.0


## Alturas de teste: a função recebe (x, y) em células e devolve a altura em metros.
func _heights(height: Callable) -> PackedFloat32Array:
	var heights := PackedFloat32Array()
	heights.resize(SIDE * SIDE)
	for y: int in SIDE:
		for x: int in SIDE:
			heights[y * SIDE + x] = height.call(x, y)
	return heights


func _channel(image: Image, x: int, y: int, channel: int) -> int:
	return image.get_data()[(y * SIDE + x) * 4 + channel]


func test_flat_ground_far_from_water_is_level_straight_and_dry() -> void:
	var image := TerrainBake.bake(_heights(func(_x: int, _y: int) -> float: return 5.0), SIDE, SPACING, WATER_M)
	assert_int(image.get_width()).is_equal(SIDE)
	assert_int(image.get_format()).is_equal(Image.FORMAT_RGBA8)
	assert_int(_channel(image, 16, 16, 0)).is_equal(0)
	assert_int(_channel(image, 16, 16, 1)).is_equal(128)
	assert_int(_channel(image, 16, 16, 2)).is_equal(255)
	assert_int(_channel(image, 16, 16, 3)).is_equal(0)


func test_slope_grows_with_the_ramp() -> void:
	var gentle := TerrainBake.bake(_heights(func(x: int, _y: int) -> float: return x * 0.5), SIDE, SPACING, WATER_M)
	var steep := TerrainBake.bake(_heights(func(x: int, _y: int) -> float: return x * 2.0), SIDE, SPACING, WATER_M)
	# 0,25 m por metro: atan(0,25) / 90° ≈ 0,156; 1 m por metro: 45° = 0,5
	assert_int(_channel(gentle, 16, 16, 0)).is_between(37, 42)
	assert_int(_channel(steep, 16, 16, 0)).is_between(125, 130)
	# a rampa reta não tem curvatura
	assert_int(_channel(steep, 16, 16, 1)).is_equal(128)


func test_valleys_and_crests_split_the_curvature() -> void:
	var valley := TerrainBake.bake(_heights(func(x: int, _y: int) -> float: return absf(x - 16) * 0.5 + 3.0), SIDE, SPACING, WATER_M)
	var crest := TerrainBake.bake(_heights(func(x: int, _y: int) -> float: return 12.0 - absf(x - 16) * 0.5), SIDE, SPACING, WATER_M)
	assert_int(_channel(valley, 16, 16, 1)).is_greater(200)
	assert_int(_channel(crest, 16, 16, 1)).is_less(56)
	# o vale é mais úmido que a crista, mesmo longe da água
	assert_int(_channel(valley, 16, 16, 3)).is_greater(_channel(crest, 16, 16, 3))


func test_water_distance_and_moisture_fall_away_from_the_sea() -> void:
	# mar nas quatro primeiras colunas, terra plana a 2 m no resto
	var image := TerrainBake.bake(_heights(func(x: int, _y: int) -> float: return -1.0 if x < 4 else 2.0), SIDE, SPACING, WATER_M)
	assert_int(_channel(image, 2, 16, 2)).is_equal(0)
	assert_int(_channel(image, 2, 16, 3)).is_equal(255)
	# a 1 célula (2 m) e a 17 (34 m) da água
	assert_int(_channel(image, 4, 16, 2)).is_equal(roundi(2.0 / WATER_M * 255.0))
	assert_int(_channel(image, 20, 16, 2)).is_equal(roundi(34.0 / WATER_M * 255.0))
	var previous := 256
	for x: int in range(4, SIDE, 4):
		var moisture := _channel(image, x, 16, 3)
		assert_int(moisture).is_less(previous)
		previous = moisture


func test_bake_is_deterministic_and_cheap_on_the_seed_1840() -> void:
	var config := GameConfig.get_default()
	var data := GameData.get_default()
	var world := ArchipelagoGenerator.new_world(1840, config, data)
	var total_ms := 0
	var baked := 0
	for index: int in world.islands.size():
		if world.island(index).flat:
			continue
		var region := ArchipelagoGenerator.region_corners(world, index, config, data)
		var heights: PackedFloat32Array = region["heights"]
		var side: int = region["side"]
		var started := Time.get_ticks_msec()
		var first := TerrainBake.bake(heights, side, config.cell_size_m, config.terrain_water_distance_m)
		total_ms += Time.get_ticks_msec() - started
		var second := TerrainBake.bake(heights, side, config.cell_size_m, config.terrain_water_distance_m)
		assert_int(first.get_width()).is_equal(side)
		assert_bool(first.get_data() == second.get_data()).override_failure_message("bake da ilha %d mudou" % index).is_true()
		baked += 1
	print("bake do terreno da semente 1840: %d ilhas em %d ms" % [baked, total_ms])
	assert_int(baked).is_greater(1)
	# a meta do plano é menos de 1 s a mais no jogo novo; aqui há folga para máquina mais lenta
	assert_int(total_ms).is_less(3000)


func test_hex_tiling_follows_the_graphics_level() -> void:
	# só no ultra (decisão do dono do produto): ~1,2 ms de GPU, e a reamostragem de longe já tira o xadrez
	var config := GameConfig.get_default()
	var last := config.graphics_presets.size() - 1
	for index: int in last:
		assert_bool(config.graphics_presets[index].terrain_hex_tiling).is_false()
	assert_bool(config.graphics_presets[last].terrain_hex_tiling).is_true()


func test_terrain_view_gives_each_island_its_data_texture() -> void:
	var config := GameConfig.new()
	config.island_sizes_cells = PackedInt32Array([70, 40])
	config.tropical_island_sizes_cells = PackedInt32Array([30])
	var world := ArchipelagoGenerator.new_world(5, config, GameData.get_default())
	var view: TerrainView = auto_free(TerrainView.new())
	add_child(view)
	view.setup(world, config, GameData.get_default())
	for index: int in world.islands.size():
		assert_object(view.data_image(index)).override_failure_message("ilha %d sem textura de dados" % index).is_not_null()
	var material := (view.get_child(0) as MeshInstance3D).material_override as ShaderMaterial
	assert_object(material.get_shader_parameter(&"terrain_data")).is_not_null()
	view.set_hex_tiling(false)
	assert_bool(material.get_shader_parameter(&"hex_tiling")).is_false()
	view.set_hex_tiling(true)
	assert_bool(material.get_shader_parameter(&"hex_tiling")).is_true()
	remove_child(view)
