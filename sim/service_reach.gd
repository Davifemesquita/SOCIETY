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
		# Fase 29: cada vizinha é lida uma vez
		var x := index % width
		var has_left := x > 0
		var has_right := x < width - 1
		var up := index - width
		var down := index + width
		var road_left := has_left and roads[index - 1] != 0
		var road_right := has_right and roads[index + 1] != 0
		var road_up := up >= 0 and roads[up] != 0
		var road_down := down < count and roads[down] != 0
		var next := index - 1
		if road_left and distance[next] == -1:
			distance[next] = steps
			queue.append(next)
		next = index + 1
		if road_right and distance[next] == -1:
			distance[next] = steps
			queue.append(next)
		if road_up and distance[up] == -1:
			distance[up] = steps
			queue.append(up)
		if road_down and distance[down] == -1:
			distance[down] = steps
			queue.append(down)
		# diagonal pura (Fase 17): a célula do canto, sem estrada nas duas vizinhas em comum; numa rua reta ou num
		# cruzamento nenhum canto liga e os quatro ficam de fora (Fase 29)
		var free_up := not road_up and up >= 0
		var free_down := not road_down and down < count
		if not ((free_up or free_down) and (not road_left or not road_right)):
			continue
		next = up - 1
		if has_left and free_up and not road_left and roads[next] != 0 and distance[next] == -1:
			distance[next] = steps
			queue.append(next)
		next = up + 1
		if has_right and free_up and not road_right and roads[next] != 0 and distance[next] == -1:
			distance[next] = steps
			queue.append(next)
		next = down - 1
		if has_left and free_down and not road_left and roads[next] != 0 and distance[next] == -1:
			distance[next] = steps
			queue.append(next)
		next = down + 1
		if has_right and free_down and not road_right and roads[next] != 0 and distance[next] == -1:
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
