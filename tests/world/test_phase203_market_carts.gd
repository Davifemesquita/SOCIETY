extends GdUnitTestSuite
## Carrinho de feira (Fase 203): um carrinho junto de cada mercado, numa célula livre encostada nele e com estrada ao lado; a
## bomba e o poço desviam dele; o recheio deixa a célula limpa; outros prédios e a ilha plana não têm; o carrinho assenta no
## chão e cabe na célula.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true
	_sim.ignore_terrain = true


## Uma rua com dois mercados de frente para ela e casas entre eles.
func _street() -> void:
	var grid := _sim.world.island(0)
	var base := grid.size / 2 - Vector2i(14, 4)
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(base + Vector2i(-2, 6), base + Vector2i(32, 6))))
	var size := Footprint.rotated_size(_sim.data.building(&"market").size, 2)
	var x := 0
	for def_id: StringName in [&"market", &"house", &"house", &"market", &"house"]:
		var footprint := Footprint.rotated_size(_sim.data.building(def_id).size, 2)
		_sim.execute(PlaceBuildingCommand.new(0, def_id, base + Vector2i(x, 6 - footprint.y), 2))
		x += footprint.x + 1
	assert_int(size.x).is_greater(0)


func test_a_cart_stands_beside_each_market_by_the_street() -> void:
	_street()
	var grid := _sim.world.island(0)
	var cells := MarketCartView.cells(_sim.world, _sim.data, 0)
	assert_int(cells.size()).is_greater(0)
	for cell: Vector2i in cells:
		assert_int(grid.building_at(cell)).is_equal(0)
		assert_bool(grid.has_road(cell)).is_false()
		var side: Vector2i = cells[cell]
		assert_bool(grid.has_road(cell + side)).is_true()
		var beside := false
		for dy: int in range(-1, 2):
			for dx: int in range(-1, 2):
				var id := grid.building_at(cell + Vector2i(dx, dy))
				if id != 0 and _sim.world.building(id).def_id == &"market":
					beside = true
		assert_bool(beside).is_true()


func test_pumps_wells_and_the_scatter_keep_off_the_cart() -> void:
	_street()
	var carts := MarketCartView.cells(_sim.world, _sim.data, 0)
	var pumps := WaterPumpView.cells(_sim.world, _sim.data, 0)
	var wells := WellView.cells(_sim.world, _sim.data, 0)
	var clear: Dictionary = ScatterView.island_context(_sim.world, _sim.data, 0)[0]
	for cell: Vector2i in carts:
		assert_bool(pumps.has(cell)).is_false()
		assert_bool(wells.has(cell)).is_false()
		assert_bool(clear.has(cell)).is_true()


func test_no_cart_without_a_market_or_on_the_flat_island() -> void:
	var grid := _sim.world.island(0)
	var base := grid.size / 2 - Vector2i(14, 4)
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(base + Vector2i(-2, 4), base + Vector2i(30, 4))))
	for i: int in 6:
		_sim.execute(PlaceBuildingCommand.new(0, &"house", base + Vector2i(i * 4, 1), 2))
	assert_int(MarketCartView.cells(_sim.world, _sim.data, 0).size()).is_equal(0)
	var sim := SimFixture.simulation(Vector2i(60, 30))
	sim.free_build = true
	SimFixture.road(sim, Vector2i(0, 10), Vector2i(59, 10))
	SimFixture.place(sim, &"market", Vector2i(10, 4), 2)
	assert_int(MarketCartView.cells(sim.world, sim.data, 0).size()).is_equal(0)


func test_the_cart_fits_its_cell() -> void:
	var box := MarketCartView.cart_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.02)
	assert_float(box.size.x).is_less(2.2)
	assert_float(box.end.y).is_between(MarketCartView.POLE_M, MarketCartView.POLE_M + 0.3)
