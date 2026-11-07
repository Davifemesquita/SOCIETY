extends GdUnitTestSuite
## Mourões na estrada (Fase 339): nas estradas de terra retas fora das vilas, lanços de cerca em blocos ao longo da estrada, na beira
## livre, com o lanço de 2 m inclinado com o chão; nada na rua calçada, nada perto de casa, nada na ilha plana.

var _config: GameConfig
var _world: WorldState
var _data: GameData


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_world = ArchipelagoGenerator.new_world(1840, _config, GameData.get_default())
	_data = GameData.get_default()


func test_fences_line_long_country_roads() -> void:
	var grid := _world.island(0)
	var road := _lay_road(grid, 24)
	assert_int(road.size()).is_greater(0)
	var places := RoadFenceView.fences(_world, _data, 0)
	assert_int(places.size()).is_greater(0)
	# nem toda a estrada é cercada: blocos
	assert_int(places.size()).is_less(road.size())
	for place: Transform3D in places:
		# na beira da célula da estrada (a 0,9 m do meio dela), com a vizinha desse lado livre
		var cell := grid.world_to_cell(place.origin)
		assert_bool(grid.has_road(cell)).is_true()
		var out := place.origin - grid.surface_world(cell)
		var side := Vector2i(roundi(out.x / RoadFenceView.OFFSET_M), roundi(out.z / RoadFenceView.OFFSET_M))
		assert_int(absi(side.x) + absi(side.y)).is_equal(1)
		assert_bool(grid.has_road(cell + side)).is_false()
		# o lanço tem 2 m ao longo da estrada, com a inclinação do chão
		var rise := RoadFenceView.MAX_RISE_M / _config.cell_size_m
		assert_float(place.basis.x.length()).is_between(0.99, sqrt(1.0 + rise * rise) + 0.01)
		assert_float(absf(place.basis.y.normalized().y)).is_greater(0.9)


func test_no_fences_on_paved_roads_or_flat_islands() -> void:
	var grid := _world.island(0)
	var road := _lay_road(grid, 24)
	for cell: Vector2i in road:
		grid.roads[grid.index(cell)] = IslandGrid.Road.PAVED
	assert_int(RoadFenceView.fences(_world, _data, 0).size()).is_equal(0)
	var flat := WorldState.new()
	flat.islands.append(IslandGrid.new(Vector2i(40, 40)))
	assert_int(RoadFenceView.fences(flat, _data, 0).size()).is_equal(0)


func test_the_fence_piece_spans_two_metres() -> void:
	var box := RoadFenceView.fence_mesh().get_aabb()
	assert_float(box.size.x).is_between(2.0, 2.2)
	assert_float(box.end.y).is_between(0.7, 1.0)
	assert_float(box.position.y).is_less(0.0)


## Até quatro estradas de terra retas de `length` células, em linhas a 5 células umas das outras, na terra livre (só a grade, para a
## vista): muitos blocos, para o sorteio de 35% não sair vazio por acaso.
func _lay_road(grid: IslandGrid, length: int) -> Array[Vector2i]:
	var laid: Array[Vector2i] = []
	var last_row := -100
	for y: int in range(3, grid.size.y - 3):
		if laid.size() >= length * 4 or y - last_row < 5:
			continue
		for x0: int in range(2, grid.size.x - length - 2, 3):
			var cells: Array[Vector2i] = []
			for k: int in length:
				cells.append(Vector2i(x0 + k, y))
			var free := true
			for cell: Vector2i in cells:
				for side: Vector2i in [Vector2i.ZERO, Vector2i(0, 1), Vector2i(0, -1)]:
					var at := cell + side
					if not grid.in_bounds(at) or grid.ground_at(at) != IslandGrid.Ground.LAND or grid.occupancy[grid.index(at)] != 0:
						free = false
			if free:
				for cell: Vector2i in cells:
					grid.roads[grid.index(cell)] = IslandGrid.Road.DIRT
				laid.append_array(cells)
				last_row = y
				break
	return laid
