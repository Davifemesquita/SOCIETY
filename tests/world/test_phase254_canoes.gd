extends GdUnitTestSuite
## Canoas na margem do rio (Fase 254): as canoas ficam em terra livre e baixa encostada num rio, de comprido ao longo da margem,
## longe das vilas; a ilha plana não tem; a canoa é comprida e baixa.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func test_canoes_rest_on_low_river_banks() -> void:
	var total := 0
	for island_id: int in _sim.world.islands.size():
		var grid := _sim.world.island(island_id)
		for bank: Array in CanoeView.banks(_sim.world, _sim.data, island_id):
			var cell: Vector2i = bank[0]
			var river: Vector2i = bank[1]
			assert_bool(grid.is_land(cell)).is_true()
			assert_int(grid.ground_at(cell + river)).is_equal(IslandGrid.Ground.RIVER)
			assert_bool(CanoeView._river_side(grid, cell) != Vector2i.ZERO).is_true()
			# de comprido ao longo da margem: o z da canoa perpendicular ao lado do rio
			var place := CanoeView.place_of(grid, cell, river)
			var along := place.basis.z.normalized()
			assert_float(absf(along.dot(Vector3(river.x, 0.0, river.y)))).is_less(0.05)
			total += 1
	assert_int(total).is_greater(0)


func test_a_town_keeps_the_canoes_away() -> void:
	var found_bank: Array = []
	for island_id: int in _sim.world.islands.size():
		var banks := CanoeView.banks(_sim.world, _sim.data, island_id)
		if not banks.is_empty():
			found_bank = [island_id, banks[0][0]]
			break
	assert_bool(found_bank.is_empty()).is_false()
	var island_id: int = found_bank[0]
	var cell: Vector2i = found_bank[1]
	var site := SiteFinder.find(_sim, &"house", island_id, cell)
	if site.is_empty():
		return
	var origin: Vector2i = site[0]
	if not _sim.execute(PlaceBuildingCommand.new(island_id, &"house", origin, 0)).ok():
		return
	if (Vector2(origin) - Vector2(cell)).length() < SealView.WILD_CELLS:
		for bank: Array in CanoeView.banks(_sim.world, _sim.data, island_id):
			var other: Vector2i = bank[0]
			assert_bool(other == cell).is_false()


func test_the_flat_island_has_none() -> void:
	var flat := SimFixture.simulation(Vector2i(60, 30))
	assert_int(CanoeView.banks(flat.world, flat.data, 0).size()).is_equal(0)


func test_the_canoe_is_long_and_low() -> void:
	var box := CanoeView.canoe_mesh().get_aabb()
	assert_float(box.size.z).is_greater(box.size.x * 4.0)
	assert_float(box.end.y).is_less(0.5)
	assert_float(box.position.y).is_greater(-0.05)
