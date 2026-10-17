class_name ServiceReach
extends RefCounted
## Alcance de um serviço pela estrada: busca em largura a partir das células da frente, até o
## raio. A diagonal pura (Fase 17) conta um passo, como o lado. Serve à cobertura real (DerivedState) e à prévia de um serviço ainda não construído.


## Células de estrada alcançadas (índices da grade), em ordem crescente. Anda por índice da
## grade: roda para cada serviço a cada estrada nova.
static func road_cells(grid: IslandGrid, front: Array[Vector2i], radius: int) -> PackedInt32Array:
	var roads := grid.roads
	var width := grid.size.x
	var count := roads.size()
	# distância por célula (-1 = não alcançada); cada célula entra na fila uma vez só, então a
	# fila é o alcance
	var distance := PackedInt32Array()
	distance.resize(count)
	distance.fill(-1)
	var queue := PackedInt32Array()
	for cell: Vector2i in front:
		if grid.has_road(cell) and distance[grid.index(cell)] == -1:
			distance[grid.index(cell)] = 0
			queue.append(grid.index(cell))
	var head := 0
	while head < queue.size():
		var index := queue[head]
		head += 1
		var steps := distance[index] + 1
		if steps > radius:
			continue
		var x := index % width
		var next := index - 1
		if x > 0 and roads[next] != 0 and distance[next] == -1:
			distance[next] = steps
			queue.append(next)
		next = index + 1
		if x < width - 1 and roads[next] != 0 and distance[next] == -1:
			distance[next] = steps
			queue.append(next)
		next = index - width
		if next >= 0 and roads[next] != 0 and distance[next] == -1:
			distance[next] = steps
			queue.append(next)
		next = index + width
		if next < count and roads[next] != 0 and distance[next] == -1:
			distance[next] = steps
			queue.append(next)
		# diagonal pura (Fase 17): a célula do canto, sem estrada nas duas vizinhas em comum
		var road_left := x > 0 and roads[index - 1] != 0
		var road_right := x < width - 1 and roads[index + 1] != 0
		var road_up := index - width >= 0 and roads[index - width] != 0
		var road_down := index + width < count and roads[index + width] != 0
		next = index - width - 1
		if x > 0 and next >= 0 and next < count and not road_left and not road_up and roads[next] != 0 and distance[next] == -1:
			distance[next] = steps
			queue.append(next)
		next = index - width + 1
		if x < width - 1 and next >= 0 and next < count and not road_right and not road_up and roads[next] != 0 and distance[next] == -1:
			distance[next] = steps
			queue.append(next)
		next = index + width - 1
		if x > 0 and next >= 0 and next < count and not road_left and not road_down and roads[next] != 0 and distance[next] == -1:
			distance[next] = steps
			queue.append(next)
		next = index + width + 1
		if x < width - 1 and next >= 0 and next < count and not road_right and not road_down and roads[next] != 0 and distance[next] == -1:
			distance[next] = steps
			queue.append(next)
	queue.sort()
	return queue


## Casas cuja frente encosta numa das células alcançadas.
static func houses(world: WorldState, data: GameData, island_id: int, reach: PackedInt32Array, candidates: Array[int]) -> Array[int]:
	var grid := world.island(island_id)
	var reached: Dictionary[int, bool] = {}
	for index: int in reach:
		reached[index] = true
	var covered: Array[int] = []
	for house_id: int in candidates:
		var house := world.building(house_id)
		if house.island_id != island_id:
			continue
		for cell: Vector2i in Footprint.front_cells(house.origin, data.building(house.def_id).size, house.rotation):
			if grid.in_bounds(cell) and reached.has(grid.index(cell)):
				covered.append(house_id)
				break
	return covered


static func radius_of(def: BuildingDef, config: GameConfig) -> int:
	return def.service_radius_cells if def.service_radius_cells > 0 else config.service_radius_cells
