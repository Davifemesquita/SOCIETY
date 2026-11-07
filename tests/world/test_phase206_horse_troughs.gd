extends GdUnitTestSuite
## Bebedouro de cavalos (Fase 206): um bebedouro junto de cada taverna, numa célula livre encostada nela pelo lado, de costas
## para ela e fora das mesas; a bomba e o poço desviam dele; o recheio deixa a célula; sem taverna e na ilha plana não há; o cocho
## assenta no chão e cabe na célula.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true
	_sim.ignore_terrain = true


## Uma rua com duas tavernas de frente para ela e casas entre elas, num pedaço de terra da ilha (a obra ignora o terreno: no
## mar a rua sairia igual, e o anel da taverna seria água).
func _street() -> void:
	var grid := _sim.world.island(0)
	var base := _open_land(grid, Vector2i(40, 12)) + Vector2i(4, 2)
	# as árvores da rua caem (a célula do bebedouro, a duas da taverna, não é limpa pela obra)
	var felled: Array[Vector2i] = []
	for y: int in range(base.y - 2, base.y + 9):
		for x: int in range(base.x - 4, base.x + 34):
			felled.append(Vector2i(x, y))
	grid.clear_trees(felled)
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(base + Vector2i(-2, 6), base + Vector2i(32, 6))))
	var x := 0
	for def_id: StringName in [&"tavern", &"house", &"house", &"tavern", &"house"]:
		var footprint := Footprint.rotated_size(_sim.data.building(def_id).size, 2)
		_sim.execute(PlaceBuildingCommand.new(0, def_id, base + Vector2i(x, 6 - footprint.y), 2))
		x += footprint.x + 1


func test_a_trough_leans_on_the_side_of_each_tavern() -> void:
	_street()
	var grid := _sim.world.island(0)
	var cells := HorseTroughView.cells(_sim.world, _sim.data, 0)
	assert_int(cells.size()).is_greater(0)
	var tables := TavernGardenView.cells(_sim.world, _sim.data, 0)
	for cell: Vector2i in cells:
		assert_bool(tables.has(cell)).is_false()
		assert_int(grid.building_at(cell)).is_equal(0)
		assert_bool(grid.has_road(cell)).is_false()
		# encostado na taverna pelo lado: a célula do outro lado (para dentro) é dela, e o lado de fora aponta para longe
		var away: Vector2i = cells[cell]
		assert_int(absi(away.x) + absi(away.y)).is_equal(1)
		var inside := grid.building_at(cell - away)
		assert_int(inside).is_not_equal(0)
		assert_bool(_sim.world.building(inside).def_id == &"tavern").is_true()


func test_pumps_wells_and_the_scatter_keep_off_the_trough() -> void:
	_street()
	var pumps := WaterPumpView.cells(_sim.world, _sim.data, 0)
	var wells := WellView.cells(_sim.world, _sim.data, 0)
	var clear: Dictionary = ScatterView.island_context(_sim.world, _sim.data, 0)[0]
	var pieces := WaterPumpView.street_pieces(_sim.world, _sim.data, 0)
	for cell: Vector2i in HorseTroughView.cells(_sim.world, _sim.data, 0):
		assert_bool(pieces.has(cell)).is_true()
		assert_bool(pumps.has(cell)).is_false()
		assert_bool(wells.has(cell)).is_false()
		assert_bool(clear.has(cell)).is_true()


func test_no_trough_without_a_tavern_or_on_the_flat_island() -> void:
	var grid := _sim.world.island(0)
	var base := grid.size / 2 - Vector2i(14, 4)
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(base + Vector2i(-2, 4), base + Vector2i(30, 4))))
	for i: int in 6:
		_sim.execute(PlaceBuildingCommand.new(0, &"house", base + Vector2i(i * 4, 1), 2))
	assert_int(HorseTroughView.cells(_sim.world, _sim.data, 0).size()).is_equal(0)
	var sim := SimFixture.simulation(Vector2i(60, 30))
	sim.free_build = true
	SimFixture.road(sim, Vector2i(0, 10), Vector2i(59, 10))
	SimFixture.place(sim, &"tavern", Vector2i(10, 6), 2)
	assert_int(HorseTroughView.cells(sim.world, sim.data, 0).size()).is_equal(0)


func test_the_trough_fits_its_cell() -> void:
	var box := HorseTroughView.trough_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.01)
	assert_float(box.size.x).is_less(2.0)
	assert_float(box.size.z).is_less(2.0)
	assert_float(box.end.y).is_between(1.0, 1.3)


## O canto do retângulo de size células todo em terra quase plana (as árvores contam como terra), o mais perto do meio da ilha.
func _open_land(grid: IslandGrid, size: Vector2i) -> Vector2i:
	var best := grid.size / 2
	var best_distance := INF
	for y: int in range(2, grid.size.y - size.y - 2, 2):
		for x: int in range(2, grid.size.x - size.x - 2, 2):
			var area := Rect2i(Vector2i(x, y), size)
			if not grid.area_is_land(area) or grid.area_relief(area) > 2.0:
				continue
			var distance := Vector2(x, y).distance_to(Vector2(grid.size / 2))
			if distance < best_distance:
				best_distance = distance
				best = Vector2i(x, y)
	return best
