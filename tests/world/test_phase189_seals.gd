extends GdUnitTestSuite
## Focas nas pedras (Fase 189): os grupos ficam na beira baixa e livre da costa das temperadas, longe dos prédios; nada nas
## tropicais nem na ilha plana; cada foca no chão, virada mais ou menos para o mar; a cabeça ergue de vez em quando e volta.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 60])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func test_colonies_lie_on_the_low_free_shore_of_temperate_islands() -> void:
	var total := 0
	for island_id: int in _sim.world.islands.size():
		var grid := _sim.world.island(island_id)
		var found := SealView.colonies(_sim.world, _sim.data, island_id)
		if _sim.world.is_tropical(island_id, _sim.data):
			assert_int(found.size()).is_equal(0)
			continue
		for cell: Vector2i in found:
			var index := grid.index(cell)
			assert_int(grid.ground[index]).is_equal(IslandGrid.Ground.LAND)
			assert_int(grid.occupancy[index]).is_equal(0)
			assert_int(grid.trees[index]).is_equal(0)
			assert_int(grid.ground_at(cell + found[cell])).is_equal(IslandGrid.Ground.SEA)
			var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
			assert_float(corners.y).is_less_equal(SealView.LOW_M)
			total += 1
	assert_int(total).is_greater(0)


func test_each_seal_lies_on_the_ground_facing_the_sea() -> void:
	for island_id: int in _sim.world.islands.size():
		var grid := _sim.world.island(island_id)
		var found := SealView.colonies(_sim.world, _sim.data, island_id)
		for seal: Array in SealView.seals(_sim.world, _sim.data, island_id):
			var place: Transform3D = seal[0]
			assert_float(place.origin.y).is_equal_approx(grid.height_at(place.origin.x, place.origin.z), 0.01)
			# a cabeça (−z) mais ou menos para o mar da célula de onde ela saiu
			var cell := grid.world_to_cell(place.origin)
			var sea := Vector2i.ZERO
			for colony: Vector2i in found:
				if absi(colony.x - cell.x) <= 2 and absi(colony.y - cell.y) <= 2:
					sea = found[colony]
			if sea != Vector2i.ZERO:
				var head := -place.basis.z
				assert_float(Vector2(head.x, head.z).normalized().dot(Vector2(sea))).is_greater(0.5)


func test_no_seals_near_buildings() -> void:
	var island_id := 0
	var found := SealView.colonies(_sim.world, _sim.data, island_id)
	assert_int(found.size()).is_greater(0)
	var cell: Vector2i = found.keys()[0]
	# um prédio ao lado do grupo (o registro basta: a conta usa os prédios da ilha)
	var record := BuildingRecord.new(4242, &"lumberjack", island_id, cell + Vector2i(2, 2), 0)
	_sim.world.buildings[record.id] = record
	assert_bool(SealView.colonies(_sim.world, _sim.data, island_id).has(cell)).is_false()


func test_the_head_lifts_now_and_then() -> void:
	var lifted := false
	var lowered := false
	for step: int in 200:
		var lift := SealView.head_lift(1234, step * 0.1)
		assert_float(lift).is_between(0.0, SealView.LIFT_RAD)
		if lift > SealView.LIFT_RAD * 0.9:
			lifted = true
		if lift < 0.01:
			lowered = true
	assert_bool(lifted).is_true()
	assert_bool(lowered).is_true()
