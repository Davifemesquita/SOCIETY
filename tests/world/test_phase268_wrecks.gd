extends GdUnitTestSuite
## Casco naufragado (Fase 268): na costa baixa e livre das ilhas temperadas, longe das vilas e fora das focas, no máximo
## MAX_PER_ISLAND por ilha, o casco velho de comprido ao longo da costa, adernado e afundado na areia; nada nas tropicais nem na
## ilha plana; o casco é comprido e com a quilha embaixo.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))


func test_wrecks_lie_on_low_temperate_shores() -> void:
	var world := _sim.world
	var total := 0
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		var found := WreckView.sites(world, _sim.data, island_id)
		assert_int(found.size()).is_less_equal(WreckView.MAX_PER_ISLAND)
		if world.is_tropical(island_id, _sim.data):
			assert_int(found.size()).is_equal(0)
		var seals := SealView.colonies(world, _sim.data, island_id)
		for cell: Vector2i in found:
			var sea: Vector2i = found[cell]
			assert_int(grid.ground_at(cell)).is_equal(IslandGrid.Ground.LAND)
			assert_int(grid.ground_at(cell + sea)).is_equal(IslandGrid.Ground.SEA)
			assert_bool(seals.has(cell)).is_false()
			var place := WreckView.place_of(grid, cell, sea, 0)
			# de comprido ao longo da costa: o x do casco perpendicular ao lado do mar
			assert_float(absf(place.basis.x.normalized().dot(Vector3(sea.x, 0.0, sea.y)))).is_less(0.05)
			# afundado na areia
			assert_float(place.origin.y).is_less(grid.height_at(place.origin.x, place.origin.z))
		total += found.size()
	print("cascos: ", total)
	assert_int(total).is_greater(0)


func test_a_town_keeps_the_wreck_away() -> void:
	var world := _sim.world
	var island_id := Simulation.MAIN_ISLAND
	var found := WreckView.sites(world, _sim.data, island_id)
	if found.is_empty():
		return
	var cell: Vector2i = found.keys()[0]
	var record := BuildingRecord.new(99999, &"house", island_id, cell + Vector2i(3, 3), 0)
	world.buildings[record.id] = record
	assert_bool(WreckView.sites(world, _sim.data, island_id).has(cell)).is_false()
	world.buildings.erase(record.id)


func test_the_flat_island_has_no_wreck() -> void:
	var flat := SimFixture.simulation()
	for island_id: int in flat.world.islands.size():
		assert_int(WreckView.sites(flat.world, flat.data, island_id).size()).is_equal(0)


func test_the_wreck_is_long_with_the_keel_below() -> void:
	var box := WreckView.wreck_mesh().get_aabb()
	assert_float(box.size.x).is_between(WreckView.LENGTH_M * 0.95, WreckView.LENGTH_M * 1.1)
	assert_float(box.position.y).is_greater(-0.2)
	assert_float(box.end.y).is_between(1.4, 2.2)
