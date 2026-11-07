extends GdUnitTestSuite
## Colmeias de palha (Fase 190): ao lado das fazendas de lúpulo, vinhedo e batata, numa célula livre encostada no lote, do lado
## oposto ao das medas; nada nas outras fazendas nem na ilha plana; o recheio deixa a célula; o banco com as três colmeias.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func _farm(def_id: StringName) -> int:
	var grid := _sim.world.island(0)
	var found := SiteFinder.find(_sim, def_id, 0, grid.size / 2)
	assert_bool(found.is_empty()).is_false()
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := _sim.execute(PlaceBuildingCommand.new(0, def_id, origin, rotation))
	assert_bool(result.ok()).is_true()
	return result.placed[0]


func test_hives_sit_beside_the_right_farms() -> void:
	var potato := _farm(&"potato_farm")
	var found := BeehiveView.cells(_sim.world, _sim.data, 0)
	assert_int(found.size()).is_equal(1)
	var cell: Vector2i = found.keys()[0]
	assert_int(found[cell]).is_equal(potato)
	var grid := _sim.world.island(0)
	var record := _sim.world.building(potato)
	var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
	assert_bool(area.grow(1).has_point(cell) and not area.has_point(cell)).is_true()
	var index := grid.index(cell)
	assert_int(grid.occupancy[index]).is_equal(0)
	assert_int(grid.roads[index]).is_equal(IslandGrid.Road.NONE)
	assert_int(grid.trees[index]).is_equal(0)


func test_no_hives_by_other_farms_or_on_the_flat_island() -> void:
	_farm(&"sheep_farm")
	assert_int(BeehiveView.cells(_sim.world, _sim.data, 0).size()).is_equal(0)
	var flat := SimFixture.simulation(Vector2i(60, 40))
	flat.free_build = true
	flat.ignore_terrain = true
	SimFixture.place(flat, &"potato_farm", Vector2i(10, 10), 0)
	assert_int(BeehiveView.cells(flat.world, flat.data, SimFixture.ISLAND).size()).is_equal(0)


func test_the_scatter_keeps_the_hive_cell_clear() -> void:
	_farm(&"hop_farm")
	var doors: Dictionary = ScatterView.island_context(_sim.world, _sim.data, 0)[0]
	for cell: Vector2i in BeehiveView.cells(_sim.world, _sim.data, 0):
		assert_bool(doors.has(cell)).is_true()


func test_the_bench_carries_three_skeps() -> void:
	var box := BeehiveView.hive_mesh().get_aabb()
	assert_float(box.end.y).is_equal_approx(BeehiveView.BENCH_M + 0.03 + BeehiveView.SKEP_M, 0.02)
	assert_float(box.size.x).is_between(1.6, 2.2)
