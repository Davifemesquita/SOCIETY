extends GdUnitTestSuite
## Retângulo girado e face de entrada nas quatro rotações.


func test_rotation_swaps_size_on_odd_steps() -> void:
	assert_vector(Footprint.rotated_size(Vector2i(4, 6), 0)).is_equal(Vector2i(4, 6))
	assert_vector(Footprint.rotated_size(Vector2i(4, 6), 1)).is_equal(Vector2i(6, 4))
	assert_vector(Footprint.rotated_size(Vector2i(4, 6), 2)).is_equal(Vector2i(4, 6))
	assert_vector(Footprint.rotated_size(Vector2i(4, 6), 3)).is_equal(Vector2i(6, 4))


func test_front_cells_on_each_side() -> void:
	var origin := Vector2i(10, 10)
	var size := Vector2i(3, 3)
	assert_array(Footprint.front_cells(origin, size, 0)).is_equal([Vector2i(10, 9), Vector2i(11, 9), Vector2i(12, 9)])
	assert_array(Footprint.front_cells(origin, size, 1)).is_equal([Vector2i(13, 10), Vector2i(13, 11), Vector2i(13, 12)])
	assert_array(Footprint.front_cells(origin, size, 2)).is_equal([Vector2i(10, 13), Vector2i(11, 13), Vector2i(12, 13)])
	assert_array(Footprint.front_cells(origin, size, 3)).is_equal([Vector2i(9, 10), Vector2i(9, 11), Vector2i(9, 12)])


func test_entrance_is_middle_of_front() -> void:
	assert_vector(Footprint.entrance_cell(Vector2i(10, 10), Vector2i(3, 3), 0)).is_equal(Vector2i(11, 9))
	assert_vector(Footprint.entrance_cell(Vector2i(10, 10), Vector2i(4, 6), 1)).is_equal(Vector2i(16, 12))


func test_front_cells_follow_rotated_size() -> void:
	assert_int(Footprint.front_cells(Vector2i.ZERO, Vector2i(4, 6), 0).size()).is_equal(4)
	assert_int(Footprint.front_cells(Vector2i.ZERO, Vector2i(4, 6), 1).size()).is_equal(4)


func test_origin_centered_on_cursor() -> void:
	var origin := Footprint.origin_centered_on(Vector2i(20, 20), Vector2i(3, 3), 0)
	assert_bool(Footprint.rect(origin, Vector2i(3, 3), 0).has_point(Vector2i(20, 20))).is_true()
	assert_vector(origin).is_equal(Vector2i(19, 19))


## front_indices é o front_cells em índices da grade, na mesma ordem, sem as células de fora.
func test_front_indices_match_front_cells_inside_the_grid() -> void:
	var grid_size := Vector2i(20, 15)
	var origins: Array[Vector2i] = [Vector2i(5, 5), Vector2i(0, 0), Vector2i(17, 12), Vector2i(-1, 3), Vector2i(18, -1)]
	var sizes: Array[Vector2i] = [Vector2i(3, 3), Vector2i(2, 4), Vector2i(1, 1)]
	for origin: Vector2i in origins:
		for size: Vector2i in sizes:
			for rotation: int in 4:
				var expected := PackedInt32Array()
				for cell: Vector2i in Footprint.front_cells(origin, size, rotation):
					if cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y:
						expected.append(cell.y * grid_size.x + cell.x)
				assert_array(Footprint.front_indices(grid_size, origin, size, rotation)).override_failure_message(
						"origem %s, tamanho %s, rotação %d" % [origin, size, rotation]).is_equal(expected)
