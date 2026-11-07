extends GdUnitTestSuite
## Capim na beira (Fase 338): a peça nova entra no fim do enum e da lista da beira da estrada (o sorteio das peças de antes não
## muda), cresce junto das estradas de terra das temperadas (nunca nas tropicais), com a malha do capim alto e mais escura.

var _config: GameConfig
var _world: WorldState


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_world = ArchipelagoGenerator.new_world(1840, _config, GameData.get_default())


func test_the_verge_grass_comes_last() -> void:
	var last: Array = ScatterView.NEAR_ROAD[ScatterView.NEAR_ROAD.size() - 1]
	assert_int(last[0]).is_equal(ScatterView.Kind.VERGE_GRASS)
	# depois de todas as peças de antes (as de depois entram no fim do enum)
	assert_int(ScatterView.Kind.VERGE_GRASS).is_greater(ScatterView.Kind.CLIFF_SHRUB)
	assert_bool(ScatterView.PLANTS.has(ScatterView.Kind.VERGE_GRASS)).is_true()
	assert_float(ScatterView.VERGE_GRASS_SHADE.y).is_less(0.9)


func test_the_verge_grass_lines_the_temperate_roads() -> void:
	var data := GameData.get_default()
	var temperate := 0
	var tropical := 0
	for island_id: int in _world.islands.size():
		var grid := _world.island(island_id)
		var road := _lay_road(grid)
		if road.is_empty():
			continue
		var chunks: Dictionary[Vector2i, bool] = {}
		for cell: Vector2i in road:
			chunks[cell / ScatterView.CHUNK_CELLS] = true
		for chunk: Vector2i in chunks:
			var items := ScatterView.places(_world, data, _config, island_id, chunk)
			for item: Array in items[ScatterView.Kind.VERGE_GRASS]:
				var place: Transform3D = item[0]
				var cell := grid.world_to_cell(place.origin)
				assert_bool(_next_to_road(grid, cell)).override_failure_message("capim da beira longe da estrada em %s" % cell).is_true()
				if _world.is_tropical(island_id, data):
					tropical += 1
				else:
					temperate += 1
	assert_int(temperate).is_greater(3)
	assert_int(tropical).is_equal(0)


## Uma estrada de terra reta de 12 células na terra livre mais perto do meio da ilha (só para o desenho do recheio).
func _lay_road(grid: IslandGrid) -> Array[Vector2i]:
	var middle := grid.size / 2
	for radius: int in range(0, grid.size.x / 2 - 8):
		for dy: int in [-radius, radius]:
			var start := middle + Vector2i(-6, dy)
			var cells: Array[Vector2i] = []
			for k: int in 12:
				cells.append(start + Vector2i(k, 0))
			var free := true
			for cell: Vector2i in cells:
				for side: Vector2i in [Vector2i.ZERO, Vector2i(0, 1), Vector2i(0, -1)]:
					var at := cell + side
					if not grid.in_bounds(at) or grid.ground_at(at) != IslandGrid.Ground.LAND or grid.trees[grid.index(at)] > 0 \
							or grid.occupancy[grid.index(at)] != 0:
						free = false
			if free:
				for cell: Vector2i in cells:
					grid.roads[grid.index(cell)] = IslandGrid.Road.DIRT
				return cells
	return []


func _next_to_road(grid: IslandGrid, cell: Vector2i) -> bool:
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var at := cell + Vector2i(dx, dy)
			if grid.in_bounds(at) and grid.roads[grid.index(at)] != IslandGrid.Road.NONE:
				return true
	return false
