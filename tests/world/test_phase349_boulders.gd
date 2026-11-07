extends GdUnitTestSuite
## Matacões no capim (Fase 349): a peça nova no fim do enum e das listas do campo aberto e da beira da mata (o sorteio de antes não
## muda), só junto de encosta ou barranco das temperadas, meio enterrada e do tamanho dela, com a rocha das pedras.

var _config: GameConfig
var _world: WorldState


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_world = ArchipelagoGenerator.new_world(1840, _config, GameData.get_default())


func test_the_boulder_comes_last() -> void:
	assert_int(ScatterView.Kind.BOULDER).is_equal(ScatterView.Kind.size() - 1)
	for rules: Array[Array] in [ScatterView.OPEN, ScatterView.NEAR_FOREST]:
		var last: Array = rules[rules.size() - 1]
		assert_int(last[0]).is_equal(ScatterView.Kind.BOULDER)
	assert_bool(ScatterView.PLANTS.has(ScatterView.Kind.BOULDER)).is_false()


func test_boulders_lie_by_the_slopes_of_temperate_islands() -> void:
	var data := GameData.get_default()
	var temperate := 0
	var tropical := 0
	for island_id: int in _world.islands.size():
		var grid := _world.island(island_id)
		for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
			for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
				var items := ScatterView.places(_world, data, _config, island_id, Vector2i(cx, cy))
				for item: Array in items[ScatterView.Kind.BOULDER]:
					var place: Transform3D = item[0]
					var cell := grid.world_to_cell(place.origin)
					assert_bool(ScatterView._near_relief(grid, cell)).is_true()
					var size := place.basis.x.length()
					assert_float(size).is_between(ScatterView.BOULDER_SCALE.x - 0.01, ScatterView.BOULDER_SCALE.y + 0.01)
					# meio enterrado
					assert_float(place.origin.y).is_less(grid.height_at(place.origin.x, place.origin.z))
					if _world.is_tropical(island_id, data):
						tropical += 1
					else:
						temperate += 1
	assert_int(temperate).is_greater(5)
	assert_int(tropical).is_equal(0)
