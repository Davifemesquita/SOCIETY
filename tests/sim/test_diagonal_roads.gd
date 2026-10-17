extends GdUnitTestSuite
## Estradas em diagonal (Fase 17): duas células de estrada que se tocam só pelo canto, sem estrada nas duas
## vizinhas em comum (diagonal pura), se ligam na rede, no alcance dos serviços, no campo dos armazéns e na
## rota da carroça, que anda √2 por passo diagonal. A esquina em L não ganha atalho pelo canto.

var _sim: Simulation
var _grid: IslandGrid


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(40, 40))
	_grid = _sim.world.island(SimFixture.ISLAND)


## Escada diagonal de from, n passos para (+1, +1).
func _diagonal(from: Vector2i, steps: int) -> void:
	for i: int in steps + 1:
		_grid.set_road(from + Vector2i(i, i), IslandGrid.Road.DIRT)


func test_only_a_pure_diagonal_links() -> void:
	_diagonal(Vector2i(5, 5), 3)
	assert_bool(RoadNetwork.linked_diagonal(_grid, Vector2i(5, 5), Vector2i(6, 6))).is_true()
	# esquina em L: a célula do meio já liga, o canto não conta
	_grid.set_road(Vector2i(20, 5), IslandGrid.Road.DIRT)
	_grid.set_road(Vector2i(21, 5), IslandGrid.Road.DIRT)
	_grid.set_road(Vector2i(21, 6), IslandGrid.Road.DIRT)
	assert_bool(RoadNetwork.linked_diagonal(_grid, Vector2i(20, 5), Vector2i(21, 6))).is_false()
	# vizinho de lado não é diagonal
	assert_bool(RoadNetwork.linked_diagonal(_grid, Vector2i(20, 5), Vector2i(21, 5))).is_false()


func test_a_diagonal_road_is_one_network_and_one_reach() -> void:
	_diagonal(Vector2i(5, 5), 6)
	var labels := RoadNetwork.components(_grid)
	assert_int(labels[_grid.index(Vector2i(11, 11))]).is_equal(labels[_grid.index(Vector2i(5, 5))])
	var start: Array[Vector2i] = [Vector2i(5, 5)]
	var reach := ServiceReach.road_cells(_grid, start, 4)
	# cada passo diagonal conta 1: chega a quatro passos e para
	assert_bool(reach.has(_grid.index(Vector2i(9, 9)))).is_true()
	assert_bool(reach.has(_grid.index(Vector2i(10, 10)))).is_false()
	var sources: Array[Vector2i] = [Vector2i(_grid.index(Vector2i(5, 5)), 7)]
	var field := WarehouseField.new(_grid, sources)
	assert_int(field.distance[_grid.index(Vector2i(11, 11))]).is_equal(6)
	assert_int(field.owner[_grid.index(Vector2i(11, 11))]).is_equal(7)


func test_the_cart_takes_the_diagonal_but_never_cuts_a_corner() -> void:
	_diagonal(Vector2i(5, 5), 4)
	var router := RoadRouter.new(_grid)
	var path := router.path(_grid.index(Vector2i(5, 5)), _grid.index(Vector2i(9, 9)))
	assert_int(path.size()).is_equal(5)
	assert_float(RoadRouter.step_length(_grid, path[0], path[1])).is_equal_approx(RoadRouter.SQRT2, 0.0001)
	# esquina em L: o caminho passa pela célula do meio
	for cell: Vector2i in RoadPath.l_path(Vector2i(20, 20), Vector2i(25, 25)):
		_grid.set_road(cell, IslandGrid.Road.DIRT)
	var corner := RoadRouter.new(_grid).path(_grid.index(Vector2i(20, 20)), _grid.index(Vector2i(25, 25)))
	assert_int(corner.size()).is_equal(11)
	for i: int in corner.size() - 1:
		assert_float(RoadRouter.step_length(_grid, corner[i], corner[i + 1])).is_equal(1.0)


func test_roads_that_only_touch_at_a_corner_of_an_l_stay_apart_from_shortcuts() -> void:
	# duas estradas paralelas encostadas pelo canto da ponta: a diagonal pura liga, e a rota usa o canto
	for x: int in range(5, 10):
		_grid.set_road(Vector2i(x, 20), IslandGrid.Road.DIRT)
	for x: int in range(10, 15):
		_grid.set_road(Vector2i(x, 21), IslandGrid.Road.DIRT)
	var path := RoadRouter.new(_grid).path(_grid.index(Vector2i(5, 20)), _grid.index(Vector2i(14, 21)))
	assert_int(path.size()).is_equal(10)


func test_the_diagonal_layout_builds_a_connected_road() -> void:
	_sim.free_build = true
	var cells := RoadPath.diagonal_path(Vector2i(5, 30), Vector2i(12, 26))
	# quatro passos diagonais e o resto (3) em linha reta
	assert_int(cells.size()).is_equal(8)
	assert_vector(cells[4]).is_equal(Vector2i(9, 26))
	assert_bool(_sim.execute(BuildRoadCommand.new(SimFixture.ISLAND, cells)).ok()).is_true()
	var labels := RoadNetwork.components(_grid)
	assert_int(labels[_grid.index(Vector2i(12, 26))]).is_equal(labels[_grid.index(Vector2i(5, 30))])
	# a mesma arrastada em L custa mais células
	assert_int(RoadPath.l_path(Vector2i(5, 30), Vector2i(12, 26)).size()).is_equal(12)
