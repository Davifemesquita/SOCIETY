extends GdUnitTestSuite
## Sinal no trilho (Fase 230): cada ponta de linha (a célula de trilho com um só vizinho de trilho) ganha um sinal ao lado da
## linha, à direita de quem chega, dentro da célula; o meio da linha e as curvas não; sem trilho, nada; a base é de mão direita.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(60, 40))
	_sim.free_build = true


func _rail(path: Array[Vector2i]) -> void:
	assert_bool(_sim.execute(BuildRailCommand.new(SimFixture.ISLAND, path)).ok()).is_true()


func test_only_the_two_ends_of_a_line_get_a_signal() -> void:
	var grid := _sim.world.island(SimFixture.ISLAND)
	assert_int(RailSignalView.ends(grid).size()).is_equal(0)
	var path: Array[Vector2i] = []
	for x: int in range(10, 25):
		path.append(Vector2i(x, 20))
	for y: int in range(21, 26):
		path.append(Vector2i(24, y))
	_rail(path)
	var ends := RailSignalView.ends(grid)
	assert_int(ends.size()).is_equal(2)
	assert_bool(ends.has(Vector2i(10, 20))).is_true()
	assert_bool(ends.has(Vector2i(24, 25))).is_true()
	# a linha segue da ponta para dentro
	assert_bool(ends[Vector2i(10, 20)] == Vector2i(1, 0)).is_true()
	assert_bool(ends[Vector2i(24, 25)] == Vector2i(0, -1)).is_true()


func test_the_signal_stands_beside_the_line_in_its_cell() -> void:
	var path: Array[Vector2i] = []
	for x: int in range(10, 20):
		path.append(Vector2i(x, 20))
	_rail(path)
	var grid := _sim.world.island(SimFixture.ISLAND)
	var ends := RailSignalView.ends(grid)
	for cell: Vector2i in ends:
		var place := RailSignalView.place_of(grid, cell, ends[cell])
		assert_bool(grid.world_to_cell(place.origin) == cell).is_true()
		# ao lado da linha (fora do eixo dela, que corre em x) e de mão direita
		assert_float(absf(place.origin.z - grid.cell_world(cell).z)).is_equal_approx(RailSignalView.ASIDE_M, 0.01)
		assert_float(place.basis.x.cross(place.basis.y).dot(place.basis.z)).is_greater(0.99)
		# o +z do sinal aponta para fora da linha
		var away := place.origin - grid.cell_world(cell)
		assert_float(place.basis.z.dot(Vector3(away.x, 0.0, away.z).normalized())).is_greater(0.5)


func test_the_view_draws_one_per_end_and_the_mesh_stands_up() -> void:
	var path: Array[Vector2i] = []
	for x: int in range(10, 20):
		path.append(Vector2i(x, 20))
	_rail(path)
	var view: RailSignalView = auto_free(RailSignalView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.signal_count()).is_equal(2)
	var box := RailSignalView.signal_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.05)
	assert_float(box.end.y).is_between(RailSignalView.POST_M, RailSignalView.POST_M + 0.6)
