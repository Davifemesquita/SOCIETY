extends GdUnitTestSuite
## Guarda-sóis de palha (Fase 204): em volta do entreposto das ilhas tropicais, até PER_HOST células de areia livres, perto do
## mar, longe o bastante do prédio e afastadas umas das outras; o recheio deixa as células; as temperadas e a ilha plana não
## têm; o guarda-sol assenta no chão com a palha no alto.

var _config: GameConfig
var _sim: Simulation
var _tropical := -1


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([80])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true
	for index: int in _sim.world.islands.size():
		if _sim.world.is_tropical(index, _sim.data):
			_tropical = index


func _post(island: int) -> BuildingRecord:
	var grid := _sim.world.island(island)
	var found := SiteFinder.find(_sim, &"trading_post", island, grid.size / 2)
	assert_bool(found.is_empty()).is_false()
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := _sim.execute(PlaceBuildingCommand.new(island, &"trading_post", origin, rotation))
	assert_bool(result.ok()).is_true()
	return _sim.world.building(result.placed[0])


func test_the_palapas_stand_on_the_sand_near_the_post() -> void:
	assert_int(_tropical).is_greater_equal(0)
	var record := _post(_tropical)
	var grid := _sim.world.island(_tropical)
	var cells := PalapaView.cells(_sim.world, _sim.data, _tropical)
	assert_int(cells.size()).is_between(1, PalapaView.PER_HOST)
	var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
	var middle := Vector2(area.position) + Vector2(area.size) * 0.5
	var near := PalapaView.near_of(record.def_id, area)
	for cell: Vector2i in cells:
		assert_bool(PalapaView._sand(grid, cell)).is_true()
		var apart := (Vector2(cell) + Vector2(0.5, 0.5)).distance_to(middle)
		assert_float(apart).is_greater_equal(near)
		assert_float(apart).is_less_equal(near + PalapaView.SPREAD_CELLS)
		for other: Vector2i in cells:
			if other != cell:
				assert_float(Vector2(other).distance_to(Vector2(cell))).is_greater_equal(PalapaView.SPACING_CELLS)
		# nunca debaixo da plataforma do cais de pedra (da beira até QUAY_DEPTH_M + STONE_QUAY_BACK_M para dentro)
		var at := grid.cell_world(cell)
		for segment: Array in HarborView.stone_quay(_sim, record):
			var front: Vector3 = segment[0]
			var outward: Vector3 = segment[1]
			var length: float = segment[2]
			var along := Vector3(-outward.z, 0.0, outward.x)
			var d := at - front
			var depth := HarborView.QUAY_DEPTH_M + HarborView.STONE_QUAY_BACK_M
			var under := d.dot(outward) < 1.0 and d.dot(outward) > -depth - 1.0 and absf(d.dot(along)) < length * 0.5 + 1.0
			assert_bool(under).is_false()


func test_the_scatter_keeps_off_the_palapas() -> void:
	_post(_tropical)
	var clear: Dictionary = ScatterView.island_context(_sim.world, _sim.data, _tropical)[0]
	for cell: Vector2i in PalapaView.cells(_sim.world, _sim.data, _tropical):
		assert_bool(clear.has(cell)).is_true()


func test_none_on_temperate_islands_or_the_flat_island() -> void:
	_post(0)
	assert_int(PalapaView.cells(_sim.world, _sim.data, 0).size()).is_equal(0)
	var sim := SimFixture.simulation(Vector2i(60, 30))
	sim.free_build = true
	SimFixture.port(sim)
	assert_int(PalapaView.cells(sim.world, sim.data, 0).size()).is_equal(0)


func test_the_palapa_stands_under_its_thatch() -> void:
	var box := PalapaView.palapa_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.001)
	assert_float(box.end.y).is_between(PalapaView.PEAK_M, PalapaView.PEAK_M + 0.2)
	assert_float(box.size.x).is_less(2.0 * PalapaView.ROOF_R_M + 0.3)
