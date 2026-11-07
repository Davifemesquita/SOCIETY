extends GdUnitTestSuite
## Praia em curva (Fase 329): a beira da praia desce em rampa até a água só no desenho (TerrainDetail), sem o degrau de
## 1,2 m do patamar sobre o mar. A linha d'água fica onde estava (nenhum canto troca de lado), a terra não desce abaixo da
## água nem o mar sobe acima dela, a falésia não muda, e um prédio na praia volta a célula à altura da simulação.

var _config: GameConfig
var _world: WorldState


func before() -> void:
	_config = GameConfig.get_default()
	_world = ArchipelagoGenerator.new_world(1840, _config, GameData.get_default())


func test_the_beach_edge_becomes_a_ramp_without_moving_the_waterline() -> void:
	var lowered := 0
	var raised := 0
	var ramps := 0
	var steepest := 0.0
	for index: int in _world.islands.size():
		var grid := _world.island(index)
		if grid.flat:
			continue
		var offsets := TerrainDetail.offsets(grid, _config)
		var width := grid.size.x + 1
		var rows := grid.size.y + 1
		for i: int in offsets.size():
			var h := grid.corner_heights[i]
			var shown := h + offsets[i]
			# a linha d'água fica: nenhum canto troca de lado
			if h > 0.0:
				assert_float(shown).is_greater(0.0)
			elif h < 0.0:
				assert_float(shown).is_less(0.0)
			if h > 0.0 and h <= TerrainDetail.BEACH_MAX_M and offsets[i] < 0.0:
				lowered += 1
			elif h < 0.0 and offsets[i] > 0.0:
				raised += 1
				assert_float(offsets[i]).is_less_equal(TerrainDetail.BEACH_SEA_RAISE_M + 0.0001)
		# o degrau: lado de canto a canto com a terra do patamar da praia e o fundo raso da praia, os dois com rampa
		for y: int in rows:
			for x: int in width - 1:
				var a := y * width + x
				var b := a + 1
				var land := maxf(grid.corner_heights[a], grid.corner_heights[b])
				var sea := minf(grid.corner_heights[a], grid.corner_heights[b])
				# (com o fundo mais fundo que a subida máxima dele, sobra parte do degrau embaixo d'água)
				if land < 0.8 or land > TerrainDetail.BEACH_MAX_M or sea > -0.8 or sea < -TerrainDetail.BEACH_SEA_RAISE_M 						or offsets[a] == 0.0 or offsets[b] == 0.0:
					continue
				ramps += 1
				steepest = maxf(steepest, absf(grid.corner_heights[a] + offsets[a] - grid.corner_heights[b] - offsets[b]))
	print("rampa da praia na semente 1840: %d cantos baixados, %d do mar erguidos, %d degraus desfeitos (o mais íngreme %.2f m em %.0f m)"
			% [lowered, raised, ramps, steepest, _config.cell_size_m])
	assert_int(lowered).is_greater(200)
	assert_int(raised).is_greater(200)
	assert_int(ramps).is_greater(50)
	# o degrau era de ~2,4 m num canto; na rampa, no máximo a inclinação mais forte num lado de 2 m
	var limit := TerrainDetail.BEACH_SLOPE * (1.0 + TerrainDetail.BEACH_SLOPE_VARIATION) * _config.cell_size_m
	assert_float(steepest).is_less_equal(limit + 0.01)


func test_cliffs_and_cells_with_something_keep_the_simulation_height() -> void:
	for index: int in _world.islands.size():
		var grid := _world.island(index)
		if grid.flat:
			continue
		var offsets := TerrainDetail.offsets(grid, _config)
		var width := grid.size.x + 1
		for y: int in grid.size.y:
			for x: int in grid.size.x:
				if not TerrainDetail.holds_something(grid, Vector2i(x, y)):
					continue
				for corner: int in [y * width + x, y * width + x + 1, (y + 1) * width + x, (y + 1) * width + x + 1]:
					if offsets[corner] != 0.0:
						assert_bool(false).override_failure_message("ilha %d: célula (%d, %d) com algo e canto mexido" % [index, x, y]).is_true()
						return
		# o mar ao pé da falésia (a terra em volta acima do patamar da praia) não sobe
		for i: int in offsets.size():
			if grid.corner_heights[i] >= 0.0 or offsets[i] == 0.0:
				continue
			var x := i % width
			var y := i / width
			for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := x + step.x
				var ny := y + step.y
				if nx < 0 or ny < 0 or nx >= width or ny > grid.size.y:
					continue
				assert_float(grid.corner_heights[ny * width + nx]).is_less_equal(TerrainDetail.BEACH_MAX_M + 0.0001)


func test_the_ramp_is_deterministic_and_shown_at_follows_it() -> void:
	var other := ArchipelagoGenerator.new_world(1840, _config, GameData.get_default())
	var grid := _world.island(Simulation.MAIN_ISLAND)
	var offsets := TerrainDetail.offsets(grid, _config)
	assert_bool(offsets == TerrainDetail.offsets(other.island(Simulation.MAIN_ISLAND), _config)).is_true()
	var width := grid.size.x + 1
	for i: int in offsets.size():
		if offsets[i] < -0.3 and grid.corner_heights[i] > 0.0:
			var point := grid.origin_m + Vector2(i % width, i / width) * grid.cell_size
			assert_float(TerrainDetail.shown_at(grid, point.x, point.y)).is_equal_approx(grid.corner_heights[i] + offsets[i], 0.0001)
			return
	assert_bool(false).override_failure_message("nenhum canto da praia baixado na ilha principal").is_true()


func test_a_building_on_the_ramp_puts_the_cell_back_on_the_simulation_height() -> void:
	var config := GameConfig.new()
	config.island_sizes_cells = PackedInt32Array([70, 40])
	config.tropical_island_sizes_cells = PackedInt32Array([30])
	var sim := Simulation.new(config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, config, GameData.get_default()))
	sim.free_build = true
	sim.ignore_terrain = true
	var view: TerrainView = auto_free(TerrainView.new())
	add_child(view)
	view.setup(sim.world, config, sim.data)
	# uma célula de terra da praia com canto baixado
	var grid := sim.world.island(Simulation.MAIN_ISLAND)
	var offsets := TerrainDetail.offsets(grid, config)
	var width := grid.size.x + 1
	var target := Vector2i(-1, -1)
	for i: int in grid.ground.size():
		var cell := grid.cell_at(i)
		if grid.ground[i] != IslandGrid.Ground.LAND or TerrainDetail.holds_something(grid, cell):
			continue
		if offsets[cell.y * width + cell.x] < -0.1 and grid.corner_height(cell.x, cell.y) > 0.0:
			target = cell
			break
	assert_bool(target.x >= 0).override_failure_message("nenhuma célula da praia com rampa").is_true()
	var result := sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"flower_bed", target, 0))
	assert_bool(result.ok()).override_failure_message(str(result.reason)).is_true()
	offsets = TerrainDetail.offsets(grid, config)
	for corner: Vector2i in [target, target + Vector2i(1, 0), target + Vector2i(0, 1), target + Vector2i.ONE]:
		assert_float(offsets[corner.y * width + corner.x]).is_equal(0.0)
	remove_child(view)


