extends GdUnitTestSuite
## Balizas com corrente (Fase 152): os lados do largo calçado que dão para a estrada ganham as balizas nas pontas, para
## dentro da célula do largo; parte fica aberta; sem estrada encostada, nada; a ilha plana (sem largo) não tem.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true
	_sim.ignore_terrain = true


## Uma escola achada pelo SiteFinder, com a rua na frente dela de ponta a ponta e um pouco além.
func _school() -> BuildingRecord:
	var grid := _sim.world.island(0)
	var found: Array = SiteFinder.find(_sim, &"school", 0, grid.size / 2)
	assert_bool(found.is_empty()).is_false()
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := _sim.execute(PlaceBuildingCommand.new(0, &"school", origin, rotation))
	assert_bool(result.ok()).is_true()
	var record := _sim.world.building(result.placed[0])
	var front := Footprint.front_cells(record.origin, _sim.def_of(record).size, rotation)
	# as células da frente ficam em fila: o passo de uma para a outra
	var step := front[1] - front[0]
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(front[0] - step * 2, front[front.size() - 1] + step * 2)))
	return record


func test_the_bollards_line_the_forecourt_on_the_street_side() -> void:
	_school()
	var grid := _sim.world.island(0)
	var forecourt := ForecourtView.cells(_sim.world, _sim.data, 0)
	var found := BollardView.edges(_sim.world, _sim.data, 0)
	assert_int(found.size()).is_greater(0)
	for edge: Array in found:
		var a: Vector3 = edge[0]
		var b: Vector3 = edge[1]
		# as duas pontas na beira de uma célula do largo, a uma célula de distância
		assert_float(Vector2(a.x - b.x, a.z - b.z).length()).is_equal_approx(grid.cell_size, 0.01)
		var middle := (a + b) * 0.5
		assert_bool(forecourt.has(grid.world_to_cell(middle))).is_true()
		assert_float(a.y).is_equal_approx(grid.height_at(a.x, a.z) + ForecourtView.SLAB_LIFT_M, 0.001)


func test_no_chain_runs_through_a_gas_lamp() -> void:
	_school()
	var grid := _sim.world.island(0)
	for edge: Array in BollardView.edges(_sim.world, _sim.data, 0):
		var a: Vector3 = edge[0]
		var b: Vector3 = edge[1]
		var middle := (a + b) * 0.5
		var cell := grid.world_to_cell(middle)
		for side: Vector2i in BollardView.SIDES:
			var next := cell + side
			if grid.in_bounds(next) and grid.is_paved(next) and posmod(next.x + next.y * 3, LampView.LAMP_EVERY) == 0:
				var facing := Vector2(middle.x - grid.cell_world(cell).x, middle.z - grid.cell_world(cell).z).normalized()
				if LampView._sidewalk_side(grid, next) == -side:
					# a corrente desse lado não existe
					assert_float(facing.dot(Vector2(side.x, side.y))).is_less(0.9)


func test_without_a_road_beside_the_forecourt_there_are_no_bollards() -> void:
	var grid := _sim.world.island(0)
	var found: Array = SiteFinder.find(_sim, &"school", 0, grid.size / 2)
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	_sim.execute(PlaceBuildingCommand.new(0, &"school", origin, rotation))
	assert_int(BollardView.edges(_sim.world, _sim.data, 0).size()).is_equal(0)


func test_the_flat_island_has_no_bollards() -> void:
	var flat := SimFixture.simulation()
	flat.free_build = true
	SimFixture.place(flat, &"school", Vector2i(20, 10))
	SimFixture.road(flat, Vector2i(18, 9), Vector2i(30, 9))
	assert_int(BollardView.edges(flat.world, flat.data, 0).size()).is_equal(0)
