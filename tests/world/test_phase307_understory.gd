extends GdUnitTestSuite
## Sub-bosque (Fase 307): as peças novas no fim do enum, entre as plantas e fora das listas de regras (o sorteio de antes não muda);
## samambaias e arbustos baixos só nas células de mata das ilhas temperadas, dentro da célula; nada nas tropicais.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([120])
	_config.tropical_island_sizes_cells = PackedInt32Array([50])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))


func _pieces(island_id: int, kind: int) -> Array:
	var grid := _sim.world.island(island_id)
	var found: Array = []
	for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
		for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
			var items := ScatterView.places(_sim.world, _sim.data, _config, island_id, Vector2i(cx, cy))
			var list: Array = items[kind]
			found.append_array(list)
	return found


func test_the_new_pieces_close_the_enum_and_stay_out_of_the_rules() -> void:
	assert_int(ScatterView.Kind.FOREST_FERN).is_greater(ScatterView.Kind.CLIFF_SPRUCE)
	assert_int(ScatterView.Kind.UNDERBRUSH).is_greater(ScatterView.Kind.FOREST_FERN)
	for kind: int in [ScatterView.Kind.FOREST_FERN, ScatterView.Kind.UNDERBRUSH]:
		assert_bool(ScatterView.PLANTS.has(kind)).is_true()
		assert_bool(ScatterView.SHADOWED.has(kind)).is_false()
		for rules: Array[Array] in [ScatterView.OPEN, ScatterView.NEAR_FOREST, ScatterView.NEAR_HOUSE, ScatterView.NEAR_ROAD,
				ScatterView.NEAR_SEA, ScatterView.NEAR_WORKS]:
			for rule: Array in rules:
				var other: int = rule[0]
				assert_int(other).is_not_equal(kind)


func test_ferns_and_brush_grow_only_in_temperate_forest_cells() -> void:
	var grid := _sim.world.island(0)
	var forest := 0
	for value: int in grid.trees:
		if value > 0:
			forest += 1
	var ferns := _pieces(0, ScatterView.Kind.FOREST_FERN)
	var brush := _pieces(0, ScatterView.Kind.UNDERBRUSH)
	assert_int(ferns.size()).is_greater(forest / 5)
	assert_int(brush.size()).is_greater(forest / 20)
	assert_int(brush.size()).is_less(ferns.size())
	for item: Array in ferns + brush:
		var place: Transform3D = item[0]
		var cell := grid.world_to_cell(place.origin)
		assert_int(grid.trees[grid.index(cell)]).is_greater(0)


func test_tropical_islands_have_no_understory() -> void:
	for island_id: int in _sim.world.islands.size():
		if _sim.world.is_tropical(island_id, _sim.data):
			assert_int(_pieces(island_id, ScatterView.Kind.FOREST_FERN).size()).is_equal(0)
			assert_int(_pieces(island_id, ScatterView.Kind.UNDERBRUSH).size()).is_equal(0)
