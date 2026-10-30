extends GdUnitTestSuite
## Coqueiros na rua tropical (Fase 112): o recheio põe coqueiros pequenos nas células livres da beira das ruas das ilhas
## tropicais, no meio da célula e no tamanho reduzido; nas temperadas nenhum, e as outras peças da beira da rua não mudam.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([70, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _all(island_id: int, kind: int) -> Array:
	var grid := _sim.world.island(island_id)
	var found: Array = []
	for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
		for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
			var items := ScatterView.places(_sim.world, _sim.data, _config, island_id, Vector2i(cx, cy))
			var list: Array = items[kind]
			found.append_array(list)
	return found


func _road(island_id: int) -> void:
	var grid := _sim.world.island(island_id)
	var middle := grid.size / 2
	_sim.execute(BuildRoadCommand.new(island_id, RoadPath.l_path(middle - Vector2i(20, 0), middle + Vector2i(20, 0))))


func test_tropical_streets_get_palms_beside_the_road() -> void:
	var island := -1
	for index: int in _sim.world.islands.size():
		if _sim.world.is_tropical(index, _sim.data) and not _sim.world.island(index).flat:
			island = index
	_road(island)
	var grid := _sim.world.island(island)
	var palms := _all(island, ScatterView.Kind.STREET_PALM)
	assert_int(palms.size()).is_greater(0)
	for item: Array in palms:
		var place: Transform3D = item[0]
		var cell := grid.world_to_cell(place.origin)
		var beside := false
		for side: Vector2i in ScatterView.SIDES:
			if grid.in_bounds(cell + side) and grid.has_road(cell + side):
				beside = true
		assert_bool(beside).is_true()
		assert_bool(grid.has_road(cell)).is_false()
		assert_float(place.basis.get_scale().x).is_less(ScatterView.STREET_PALM_SCALE * 1.2)


func test_temperate_streets_have_none() -> void:
	_road(0)
	assert_int(_all(0, ScatterView.Kind.STREET_PALM).size()).is_equal(0)
	assert_int(_all(0, ScatterView.Kind.TUFT).size()).is_greater(0)
