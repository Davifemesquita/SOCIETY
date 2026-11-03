extends GdUnitTestSuite
## Fendas com mato (Fase 313): a peça nova no fim do enum e das listas OPEN, NEAR_FOREST e NEAR_SEA (o sorteio das de antes não
## muda), entre as plantas; só nas células de face de falésia, meio deitada para fora da face.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([160])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))


func _last_rule(rules: Array[Array]) -> int:
	var last: Array = rules[rules.size() - 1]
	var kind: int = last[0]
	return kind


func test_the_shrub_closes_the_enum_and_its_lists() -> void:
	assert_int(ScatterView.Kind.CLIFF_SHRUB).is_greater(ScatterView.Kind.UNDERBRUSH)
	for rules: Array[Array] in [ScatterView.OPEN, ScatterView.NEAR_FOREST, ScatterView.NEAR_SEA]:
		assert_int(_last_rule(rules)).is_equal(ScatterView.Kind.CLIFF_SHRUB)
	assert_bool(ScatterView.PLANTS.has(ScatterView.Kind.CLIFF_SHRUB)).is_true()
	assert_bool(ScatterView.SHADOWED.has(ScatterView.Kind.CLIFF_SHRUB)).is_false()


func test_shrubs_cling_to_cliff_faces_leaning_out() -> void:
	var grid := _sim.world.island(0)
	var found: Array = []
	for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
		for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
			var items := ScatterView.places(_sim.world, _sim.data, _config, 0, Vector2i(cx, cy))
			var list: Array = items[ScatterView.Kind.CLIFF_SHRUB]
			found.append_array(list)
	assert_int(found.size()).is_greater(10)
	for item: Array in found:
		var place: Transform3D = item[0]
		var cell := grid.world_to_cell(place.origin)
		assert_float(ScatterView.cell_relief(grid, cell)).is_greater_equal(ScatterView.CLIFF_SHRUB_MIN_RELIEF_M)
		# deitada para o lado da face: o +y da peça sai da vertical
		assert_float(place.basis.y.normalized().y).is_less(0.999)


func test_the_shrub_mesh_is_small() -> void:
	var box := ScatterView.cliff_shrub_mesh().get_aabb()
	assert_float(box.end.y).is_between(0.3, 0.7)
	assert_float(box.size.x).is_less(1.0)
