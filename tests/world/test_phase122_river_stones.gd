extends GdUnitTestSuite
## Pedras no rio (Fase 122): matacões nas células de rio, sentados no leito e saindo da água; seixos só na terra da
## margem baixa e livre; a ponte tira o matacão; o sorteio é o mesmo a cada vez.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func test_boulders_sit_in_the_river_and_break_the_surface() -> void:
	var grid := _sim.world.island(0)
	var entries := RiverStoneView.places(_sim.world, 0)
	var boulders := entries.filter(func(entry: Array) -> bool: return entry[2] == RiverStoneView.Kind.BOULDER)
	assert_int(boulders.size()).is_greater(0)
	for entry: Array in boulders:
		var place: Transform3D = entry[1]
		assert_int(grid.ground_at(grid.world_to_cell(place.origin))).is_equal(IslandGrid.Ground.RIVER)
		# o pé no leito, abaixo da água, e o topo acima dela
		assert_float(place.origin.y).is_less_equal(0.0)
		var top := place.origin.y + place.basis.y.length()
		assert_float(top).is_between(RiverStoneView.EMERGE_M.x - 0.01, RiverStoneView.EMERGE_M.y + 0.01)


func test_pebbles_lie_on_free_low_bank_land() -> void:
	var total := 0
	for island_id: int in _sim.world.islands.size():
		var grid := _sim.world.island(island_id)
		for entry: Array in RiverStoneView.places(_sim.world, island_id):
			if entry[2] != RiverStoneView.Kind.PEBBLE:
				continue
			total += 1
			var place: Transform3D = entry[1]
			var cell := grid.world_to_cell(place.origin)
			assert_int(grid.ground_at(cell)).is_equal(IslandGrid.Ground.LAND)
			assert_float(grid.cell_height(cell)).is_less_equal(RiverStoneView.BANK_MAX_M)
			var touches := false
			for side: Vector2i in RiverStoneView.SIDES:
				touches = touches or grid.ground_at(cell + side) == IslandGrid.Ground.RIVER
			assert_bool(touches).is_true()
			assert_int(grid.building_at(cell)).is_equal(0)
	assert_int(total).is_greater(0)


func test_a_bridge_takes_the_boulder_away() -> void:
	var grid := _sim.world.island(0)
	var entries := RiverStoneView.places(_sim.world, 0)
	var first: Transform3D = entries.filter(func(entry: Array) -> bool:
		return entry[2] == RiverStoneView.Kind.BOULDER)[0][1]
	var cell := grid.world_to_cell(first.origin)
	grid.set_road(cell, IslandGrid.Road.DIRT)
	for entry: Array in RiverStoneView.places(_sim.world, 0):
		var place: Transform3D = entry[1]
		if entry[2] == RiverStoneView.Kind.BOULDER:
			assert_bool(grid.world_to_cell(place.origin) == cell).is_false()


func test_the_draw_is_stable() -> void:
	var a := RiverStoneView.places(_sim.world, 0)
	var b := RiverStoneView.places(_sim.world, 0)
	assert_int(a.size()).is_equal(b.size())
	for i: int in a.size():
		var pa: Transform3D = a[i][1]
		var pb: Transform3D = b[i][1]
		assert_bool(pa.is_equal_approx(pb)).is_true()


func test_no_stones_on_the_flat_island() -> void:
	var sim := SimFixture.simulation()
	assert_int(RiverStoneView.places(sim.world, 0).size()).is_equal(0)
