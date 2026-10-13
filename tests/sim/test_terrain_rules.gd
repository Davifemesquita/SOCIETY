extends GdUnitTestSuite
## Construção pelo terreno (seção 7): plano, em terra, litoral, rio e jazida; estrada fora do mar
## e sem barranco, ponte no rio; construir derruba árvores; lenhador sem árvores para.
## Ilha montada à mão (40 × 30): plana a 1,2 m, mar na faixa x < 4, rio em x = 20..22 de y = 0 a
## 12, morro inclinado em x 30..39, carvão em (10..15, 20..25), ferro em (24..29, 20..25) e
## floresta em (4..19, 0..9).

var _sim: Simulation
var _grid: IslandGrid


func before_test() -> void:
	var grid := IslandGrid.new(Vector2i(40, 30))
	grid.init_terrain()
	for y: int in 31:
		for x: int in 41:
			var height := 1.2 if x < 30 else 1.2 + (x - 30) * 0.8
			grid.corner_heights[grid.corner_index(x, y)] = height if x >= 4 else -3.0
	for y: int in 30:
		for x: int in 40:
			var i := y * 40 + x
			grid.ground[i] = IslandGrid.Ground.SEA if x < 4 else IslandGrid.Ground.LAND
			if x >= 20 and x <= 22 and y <= 12:
				grid.ground[i] = IslandGrid.Ground.RIVER
			if x >= 4 and x < 20 and y < 10:
				grid.trees[i] = 3
	grid.deposit_goods = [&"coal", &"iron_ore"]
	for y: int in range(20, 26):
		for x: int in range(10, 16):
			grid.deposits[y * 40 + x] = 1
		for x: int in range(24, 30):
			grid.deposits[y * 40 + x] = 2
	var world := WorldState.new()
	world.islands.append(grid)
	var economy := IslandEconomy.new()
	economy.profile_id = &"main_island"
	world.economies.append(economy)
	world.money = 100000.0
	var config := GameConfig.new()
	config.instant_logistics = true
	_sim = Simulation.new(config, GameData.get_default(), world)
	_sim.free_build = true
	_grid = grid


func _reason(def_id: StringName, origin: Vector2i, rotation: int = 0) -> StringName:
	return _sim.placement_reason(_sim.data.building(def_id), origin, rotation)


func test_flat_land_builds_but_slopes_and_water_do_not() -> void:
	assert_str(_reason(&"house", Vector2i(8, 14))).is_equal(PlacementRules.OK)
	assert_str(_reason(&"house", Vector2i(31, 14))).is_equal(PlacementRules.NOT_FLAT)
	assert_str(_reason(&"house", Vector2i(2, 14))).is_equal(PlacementRules.ON_WATER)
	assert_str(_reason(&"house", Vector2i(20, 5))).is_equal(PlacementRules.ON_WATER)


func test_coast_river_and_deposit_requirements() -> void:
	assert_str(_reason(&"fishery", Vector2i(4, 14))).is_equal(PlacementRules.OK)
	assert_str(_reason(&"fishery", Vector2i(10, 14))).is_equal(PlacementRules.NEEDS_COAST)
	assert_str(_reason(&"clay_pit", Vector2i(16, 2))).is_equal(PlacementRules.OK)
	assert_str(_reason(&"clay_pit", Vector2i(16, 14))).is_equal(PlacementRules.NEEDS_RIVER_OR_COAST)
	assert_str(_reason(&"coal_mine", Vector2i(11, 21))).is_equal(PlacementRules.OK)
	assert_str(_reason(&"coal_mine", Vector2i(13, 21))).is_equal(PlacementRules.NEEDS_DEPOSIT)
	assert_str(_reason(&"coal_mine", Vector2i(25, 21))).is_equal(PlacementRules.NEEDS_DEPOSIT)
	assert_str(_reason(&"iron_mine", Vector2i(25, 21))).is_equal(PlacementRules.OK)


func test_roads_stay_off_the_sea_and_the_cliffs_and_bridge_the_river() -> void:
	assert_str(PlacementRules.check_road_cell(_grid, Vector2i(2, 15), _sim.config)).is_equal(PlacementRules.ON_WATER)
	assert_str(PlacementRules.check_road_cell(_grid, Vector2i(21, 5), _sim.config)).is_equal(PlacementRules.OK)
	assert_str(PlacementRules.check_road_cell(_grid, Vector2i(32, 15), _sim.config)).is_equal(PlacementRules.OK)
	_sim.config.max_road_relief_m = 0.5
	assert_str(PlacementRules.check_road_cell(_grid, Vector2i(32, 15), _sim.config)).is_equal(PlacementRules.TOO_STEEP)
	var bridge: Array[Vector2i] = [Vector2i(19, 5), Vector2i(20, 5), Vector2i(21, 5), Vector2i(22, 5), Vector2i(23, 5)]
	assert_bool(_sim.execute(BuildRoadCommand.new(0, bridge)).ok()).is_true()


func test_building_and_roads_clear_the_forest() -> void:
	var cleared: Array[Rect2i] = []
	var listener := func(_island: int, area: Rect2i) -> void: cleared.append(area)
	EventBus.trees_changed.connect(listener)
	var before := _grid.trees_in(Rect2i(Vector2i.ZERO, _grid.size))
	_sim.execute(PlaceBuildingCommand.new(0, &"house", Vector2i(6, 2), 0))
	var road: Array[Vector2i] = [Vector2i(12, 3), Vector2i(13, 3)]
	_sim.execute(BuildRoadCommand.new(0, road))
	EventBus.trees_changed.disconnect(listener)
	assert_int(_grid.trees_in(Rect2i(6, 2, 3, 3))).is_equal(0)
	assert_int(_grid.trees_in(Rect2i(Vector2i.ZERO, _grid.size))).is_equal(before - 9 * 3 - 2 * 3)
	assert_int(_grid.cleared_trees.count(1)).is_equal(11)
	assert_array(cleared).is_equal([Rect2i(6, 2, 3, 3), Rect2i(12, 3, 2, 1)])


func test_lumberjack_needs_trees_in_range() -> void:
	var road: Array[Vector2i] = []
	for x: int in range(4, 30):
		road.append(Vector2i(x, 17))
	_sim.execute(BuildRoadCommand.new(0, road))
	var in_forest := SimFixture.place(_sim, &"lumberjack", Vector2i(8, 14), 2)
	var bare := SimFixture.place(_sim, &"lumberjack", Vector2i(26, 14), 2)
	SimFixture.house(_sim, 14, 17, &"peasants", 10.0)
	_sim.run_ticks(20)
	assert_int(_sim.derived_state().entry_of(in_forest).trees).is_greater_equal(_sim.config.lumberjack_min_trees)
	assert_int(_sim.world.building(bare).state).is_equal(BuildingRecord.State.NO_TREES)
	assert_int(_sim.world.building(in_forest).state).is_not_equal(BuildingRecord.State.NO_TREES)
