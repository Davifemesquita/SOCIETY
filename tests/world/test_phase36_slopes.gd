extends GdUnitTestSuite
## Encostas de pedra (Fase 36): o detalhe visual do relevo só mexe na malha onde nada da simulação está — em toda
## célula construível, com estrada, prédio ou árvore, os 4 cantos ficam na altura da simulação, e uma estrada nova num
## barranco desfaz o detalhe da célula —, é determinístico, não muda depois de derrubar árvores (o save carregado
## desenha igual), e as pedras viram rocha de verdade nos barrancos e no litoral rochoso.

var _config: GameConfig
var _world: WorldState


func before() -> void:
	_config = GameConfig.get_default()
	_world = ArchipelagoGenerator.new_world(1840, _config, GameData.get_default())


func test_detail_is_zero_on_and_around_every_cell_the_simulation_uses() -> void:
	var moved := 0
	var started := Time.get_ticks_msec()
	for index: int in _world.islands.size():
		var grid := _world.island(index)
		if grid.flat:
			continue
		var offsets := TerrainDetail.offsets(grid, _config)
		var width := grid.size.x + 1
		for value: float in offsets:
			assert_float(absf(value)).is_less_equal(TerrainDetail.WIDTH_M + TerrainDetail.GULLY_M)
			if value != 0.0:
				moved += 1
		for y: int in grid.size.y:
			for x: int in grid.size.x:
				if not TerrainDetail.protected_cell(grid, _config, Vector2i(x, y)):
					continue
				# nenhum dos 4 cantos da célula se mexe: o que fica em cima dela fica na altura da simulação
				for cy: int in [y, y + 1]:
					for cx: int in [x, x + 1]:
						if offsets[cy * width + cx] != 0.0:
							assert_bool(false).override_failure_message(
									"ilha %d: canto (%d, %d) mexido junto da célula (%d, %d)" % [index, cx, cy, x, y]).is_true()
							return
	print("detalhe das encostas da semente 1840: %d cantos mexidos em %d ms" % [moved, Time.get_ticks_msec() - started])
	assert_int(moved).override_failure_message("nenhum barranco ganhou detalhe").is_greater(100)


func test_detail_is_deterministic() -> void:
	var other := ArchipelagoGenerator.new_world(1840, _config, GameData.get_default())
	for index: int in _world.islands.size():
		if _world.island(index).flat:
			continue
		assert_bool(TerrainDetail.offsets(_world.island(index), _config) == TerrainDetail.offsets(other.island(index), _config)) \
				.override_failure_message("ilha %d mudou" % index).is_true()


func test_clearing_trees_does_not_change_the_detail() -> void:
	# o save guarda as árvores derrubadas: a célula sem árvore continua protegida e o desenho não muda ao carregar
	var fresh := ArchipelagoGenerator.new_world(1840, _config, GameData.get_default())
	var cleared := ArchipelagoGenerator.new_world(1840, _config, GameData.get_default())
	var grid := cleared.island(0)
	var forest: Array[Vector2i] = []
	for i: int in grid.trees.size():
		if grid.trees[i] > 0:
			forest.append(grid.cell_at(i))
	assert_bool(grid.clear_trees(forest)).is_true()
	assert_bool(TerrainDetail.offsets(grid, _config) == TerrainDetail.offsets(fresh.island(0), _config)).is_true()


func test_a_new_road_on_a_bank_puts_the_cell_back_on_the_simulation_height() -> void:
	var config := GameConfig.new()
	config.island_sizes_cells = PackedInt32Array([70, 40])
	config.tropical_island_sizes_cells = PackedInt32Array([30])
	var sim := Simulation.new(config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, config, GameData.get_default()))
	sim.free_build = true
	var view: TerrainView = auto_free(TerrainView.new())
	add_child(view)
	view.setup(sim.world, config, sim.data)
	# uma célula de barranco com detalhe onde a estrada pode ir (até max_road_relief_m)
	var target := Vector2i(-1, -1)
	var island := -1
	for index: int in sim.world.islands.size():
		var grid := sim.world.island(index)
		if grid.flat:
			continue
		var offsets := TerrainDetail.offsets(grid, config)
		var width := grid.size.x + 1
		for i: int in grid.ground.size():
			var cell := grid.cell_at(i)
			if offsets[cell.y * width + cell.x] != 0.0 and PlacementRules.check_road_cell(grid, cell, config) == PlacementRules.OK:
				target = cell
				island = index
				break
		if island >= 0:
			break
	assert_int(island).override_failure_message("nenhum barranco com detalhe aceita estrada").is_greater_equal(0)
	var grid := sim.world.island(island)
	var one: Array[Vector2i] = [target]
	assert_bool(sim.execute(BuildRoadCommand.new(island, one)).ok()).is_true()
	var offsets := TerrainDetail.offsets(grid, config)
	var width := grid.size.x + 1
	for corner: Vector2i in [target, target + Vector2i(1, 0), target + Vector2i(0, 1), target + Vector2i.ONE]:
		assert_float(offsets[corner.y * width + corner.x]).is_equal(0.0)
		var point := grid.origin_m + Vector2(corner) * grid.cell_size
		assert_float(view.shown_height(point.x, point.y)).is_equal_approx(sim.world.surface_height(point.x, point.y), 0.001)
	remove_child(view)


func test_offset_at_matches_the_corners() -> void:
	var grid := _world.island(0)
	var offsets := TerrainDetail.offsets(grid, _config)
	var width := grid.size.x + 1
	var corner := -1
	for i: int in offsets.size():
		if offsets[i] != 0.0:
			corner = i
			break
	assert_int(corner).override_failure_message("a ilha principal não tem canto mexido").is_greater_equal(0)
	var x := grid.origin_m.x + (corner % width) * grid.cell_size
	var z := grid.origin_m.y + (corner / width) * grid.cell_size
	assert_float(TerrainDetail.offset_at(grid, _config, x, z)).is_equal_approx(offsets[corner], 0.0001)


func test_rocks_are_stone_on_tall_banks_and_rocky_coast() -> void:
	var view: TreeView = auto_free(TreeView.new())
	add_child(view)
	view.setup(_world, GameData.get_default(), _config)
	var material := view.rock_material() as StandardMaterial3D
	assert_object(material).override_failure_message("a pedra continua com o recolorido verde-cinza").is_not_null()
	assert_bool(material.uv1_triplanar and material.uv1_world_triplanar).is_true()
	assert_object(material.albedo_texture).is_not_null()
	var grid := _world.island(0)
	var bank := 0
	var coast := 0
	for i: int in grid.ground.size():
		if grid.ground[i] != IslandGrid.Ground.LAND:
			continue
		var cell := grid.cell_at(i)
		var chance := TreeView.rock_chance(grid, cell)
		if chance == TreeView.ROCK_CHANCE:
			bank += 1
		elif chance == TreeView.COAST_ROCK_CHANCE:
			coast += 1
			assert_bool(grid.area_touches(Rect2i(cell, Vector2i.ONE), IslandGrid.Ground.SEA)).is_true()
	print("pedras possíveis na ilha principal: %d em barranco, %d no litoral" % [bank, coast])
	assert_int(bank + coast).is_greater(0)
	remove_child(view)
