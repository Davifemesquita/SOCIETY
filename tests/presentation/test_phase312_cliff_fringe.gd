extends GdUnitTestSuite
## Capim na borda (Fase 312): a franja só na borda de cima das falésias (queda de DROP_M com o mar logo abaixo), virada para fora
## da queda, fora de prédio e estrada; a malha pende (as pontas abaixo do pé, para fora); a ilha plana não tem.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([160])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))


func test_the_fringe_hangs_out_and_down() -> void:
	var box := CliffFringeView.fringe_mesh().get_aabb()
	assert_float(box.end.z).is_greater(0.5)
	assert_float(box.position.y).is_less(-0.1)
	assert_float(box.size.x).is_between(0.9, 1.2)


func test_pieces_sit_on_cliff_tops_facing_the_drop() -> void:
	var grid := _sim.world.island(0)
	var places := CliffFringeView.places_of(_sim.world, _config, 0)
	assert_int(places.size()).is_greater(20)
	for place: Transform3D in places:
		var cell := grid.world_to_cell(place.origin)
		assert_int(grid.ground[grid.index(cell)]).is_equal(IslandGrid.Ground.LAND)
		assert_int(grid.occupancy[grid.index(cell)]).is_equal(0)
		var out := place.basis.z.normalized()
		# a vizinha para onde ela aponta fica DROP_M mais baixa (ou é água)
		var side := Vector2i(roundi(out.x), roundi(out.z))
		var below := cell + side
		var low := grid.cell_height(below) if grid.ground[grid.index(below)] == IslandGrid.Ground.LAND else 0.0
		assert_float(grid.cell_height(cell) - low).is_greater_equal(CliffFringeView.DROP_M)
		# de pé (o +y da peça para cima)
		assert_float(place.basis.y.normalized().y).is_greater(0.99)


func test_a_road_on_the_edge_takes_the_fringe_away() -> void:
	var grid := _sim.world.island(0)
	var places := CliffFringeView.places_of(_sim.world, _config, 0)
	var cell := grid.world_to_cell(places[0].origin)
	grid.roads[grid.index(cell)] = IslandGrid.Road.DIRT
	for place: Transform3D in CliffFringeView.places_of(_sim.world, _config, 0):
		assert_bool(grid.world_to_cell(place.origin) == cell).is_false()


func test_the_flat_island_has_no_fringe() -> void:
	var world := WorldState.new()
	world.islands.append(IslandGrid.new(Vector2i(20, 20)))
	assert_int(CliffFringeView.places_of(world, _config, 0).size()).is_equal(0)
