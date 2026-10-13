extends GdUnitTestSuite
## Rota de pedestre: trechos retos na calçada à direita de quem anda, sem sair da estrada.

const CELL := 2.0
const OFFSET := 0.62


func _grid_with_road(cells: Array[Vector2i]) -> IslandGrid:
	var grid := IslandGrid.new(Vector2i(20, 20))
	for cell: Vector2i in cells:
		grid.set_road(cell, IslandGrid.Road.DIRT)
	return grid


func _indices(grid: IslandGrid, cells: Array[Vector2i]) -> PackedInt32Array:
	var result := PackedInt32Array()
	for cell: Vector2i in cells:
		result.append(grid.index(cell))
	return result


func test_straight_road_becomes_one_segment_on_the_right() -> void:
	var cells: Array[Vector2i] = [Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5)]
	var grid := _grid_with_road(cells)
	var points := SidewalkPath.from_cells(grid, _indices(grid, cells), OFFSET)
	assert_int(points.size()).is_equal(2)
	# andando para +x, a direita é +z
	assert_vector(points[0]).is_equal_approx(Vector3(5.0, 0.0, 11.0 + OFFSET), Vector3.ONE * 0.001)
	assert_vector(points[1]).is_equal_approx(Vector3(11.0, 0.0, 11.0 + OFFSET), Vector3.ONE * 0.001)


func test_corner_meets_both_sidewalks_and_every_point_stays_on_the_road() -> void:
	var cells: Array[Vector2i] = [Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5), Vector2i(4, 6), Vector2i(4, 7), Vector2i(4, 8)]
	var grid := _grid_with_road(cells)
	var points := SidewalkPath.from_cells(grid, _indices(grid, cells), OFFSET)
	assert_int(points.size()).is_equal(3)
	assert_vector(points[1]).is_equal_approx(Vector3(9.0 - OFFSET, 0.0, 11.0 + OFFSET), Vector3.ONE * 0.001)
	for i: int in points.size() - 1:
		for step: int in 11:
			var point := points[i].lerp(points[i + 1], step / 10.0)
			var cell := Vector2i(floori(point.x / CELL), floori(point.z / CELL))
			assert_bool(grid.has_road(cell)).override_failure_message("fora da estrada em %s" % point).is_true()


func test_opposite_directions_use_opposite_sidewalks() -> void:
	assert_vector(SidewalkPath.right_of(Vector3.RIGHT)).is_equal_approx(Vector3.BACK, Vector3.ONE * 0.001)
	assert_vector(SidewalkPath.right_of(Vector3.LEFT)).is_equal_approx(Vector3.FORWARD, Vector3.ONE * 0.001)


func test_single_cell_gives_nothing_to_walk() -> void:
	var cells: Array[Vector2i] = [Vector2i(2, 5)]
	var grid := _grid_with_road(cells)
	assert_int(SidewalkPath.from_cells(grid, _indices(grid, cells), OFFSET).size()).is_equal(1)
