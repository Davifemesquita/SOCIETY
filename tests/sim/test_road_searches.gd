extends GdUnitTestSuite
## As buscas em largura sobre a estrada (trechos, alcance de serviço e armazém mais próximo)
## conferidas contra uma busca de referência simples, numa grade com terra e paralelepípedo
## misturados e trechos encostados nas bordas.

const SIZE := Vector2i(23, 17)


func _grid() -> IslandGrid:
	var grid := IslandGrid.new(SIZE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1840
	for index: int in grid.roads.size():
		var roll := rng.randf()
		grid.roads[index] = IslandGrid.Road.NONE if roll < 0.45 else (IslandGrid.Road.DIRT if roll < 0.8 else IslandGrid.Road.PAVED)
	return grid


## Vizinhos na ordem esquerda, direita, cima, baixo, sem atravessar a borda.
func _neighbors(index: int) -> Array[int]:
	var x := index % SIZE.x
	var result: Array[int] = []
	if x > 0:
		result.append(index - 1)
	if x < SIZE.x - 1:
		result.append(index + 1)
	if index - SIZE.x >= 0:
		result.append(index - SIZE.x)
	if index + SIZE.x < SIZE.x * SIZE.y:
		result.append(index + SIZE.x)
	return result


func test_components_number_stretches_in_index_order() -> void:
	var grid := _grid()
	var expected := PackedInt32Array()
	expected.resize(grid.roads.size())
	var label := 0
	for start: int in grid.roads.size():
		if grid.roads[start] == 0 or expected[start] != 0:
			continue
		label += 1
		expected[start] = label
		var queue: Array[int] = [start]
		while not queue.is_empty():
			var index: int = queue.pop_front()
			for next: int in _neighbors(index):
				if grid.roads[next] != 0 and expected[next] == 0:
					expected[next] = label
					queue.append(next)
	assert_int(label).is_greater(3)
	assert_array(RoadNetwork.components(grid)).is_equal(expected)


func test_components_of_a_grid_without_roads_or_only_paved() -> void:
	var grid := IslandGrid.new(SIZE)
	assert_int(RoadNetwork.components(grid).count(0)).is_equal(grid.roads.size())
	grid.roads[0] = IslandGrid.Road.PAVED
	grid.roads[grid.roads.size() - 1] = IslandGrid.Road.PAVED
	var labels := RoadNetwork.components(grid)
	assert_int(labels[0]).is_equal(1)
	assert_int(labels[grid.roads.size() - 1]).is_equal(2)


func _reference_distances(grid: IslandGrid, starts: PackedInt32Array) -> Dictionary[int, int]:
	var distance: Dictionary[int, int] = {}
	var queue: Array[int] = []
	for start: int in starts:
		if not distance.has(start):
			distance[start] = 0
			queue.append(start)
	while not queue.is_empty():
		var index: int = queue.pop_front()
		for next: int in _neighbors(index):
			if grid.roads[next] != 0 and not distance.has(next):
				distance[next] = distance[index] + 1
				queue.append(next)
	return distance


func test_service_reach_is_every_road_cell_within_the_radius() -> void:
	var grid := _grid()
	var front: Array[Vector2i] = []
	for x: int in range(8, 12):
		front.append(Vector2i(x, 8))
		grid.roads[grid.index(Vector2i(x, 8))] = IslandGrid.Road.DIRT
	var starts := PackedInt32Array()
	for cell: Vector2i in front:
		starts.append(grid.index(cell))
	var distance := _reference_distances(grid, starts)
	for radius: int in [0, 1, 4, 30]:
		var expected := PackedInt32Array()
		for index: int in distance:
			if distance[index] <= radius:
				expected.append(index)
		expected.sort()
		assert_array(ServiceReach.road_cells(grid, front, radius)).is_equal(expected)


func test_warehouse_field_gives_distance_and_nearest_owner() -> void:
	var grid := _grid()
	var a := grid.index(Vector2i(2, 2))
	var b := grid.index(Vector2i(20, 14))
	grid.roads[a] = IslandGrid.Road.DIRT
	grid.roads[b] = IslandGrid.Road.PAVED
	var sources: Array[Vector2i] = [Vector2i(a, 7), Vector2i(b, 9)]
	var field := WarehouseField.new(grid, sources)
	var from_a := _reference_distances(grid, PackedInt32Array([a]))
	var from_b := _reference_distances(grid, PackedInt32Array([b]))
	var both := _reference_distances(grid, PackedInt32Array([a, b]))
	for index: int in grid.roads.size():
		if not both.has(index):
			assert_int(field.distance[index]).is_equal(-1)
			continue
		assert_int(field.distance[index]).is_equal(both[index])
		var to_a: int = from_a.get(index, 1 << 30)
		var to_b: int = from_b.get(index, 1 << 30)
		if to_a != to_b:
			assert_int(field.owner[index]).is_equal(7 if to_a < to_b else 9)
