class_name ServiceReach
extends RefCounted
## Alcance de um serviço pela estrada: busca em largura a partir das células da frente, até o
## raio. Serve à cobertura real (DerivedState) e à prévia de um serviço ainda não construído.


## Células de estrada alcançadas (índices da grade), em ordem crescente. Anda por índice da
## grade: roda para cada serviço a cada estrada nova.
static func road_cells(grid: IslandGrid, front: Array[Vector2i], radius: int) -> PackedInt32Array:
	var roads := grid.roads
	var width := grid.size.x
	var count := roads.size()
	var distance: Dictionary[int, int] = {}
	var queue := PackedInt32Array()
	for cell: Vector2i in front:
		if grid.has_road(cell) and not distance.has(grid.index(cell)):
			distance[grid.index(cell)] = 0
			queue.append(grid.index(cell))
	var head := 0
	while head < queue.size():
		var index := queue[head]
		head += 1
		var steps: int = distance[index]
		if steps >= radius:
			continue
		var x := index % width
		for next: int in [index - 1 if x > 0 else -1, index + 1 if x < width - 1 else -1, index - width, index + width]:
			if next >= 0 and next < count and roads[next] != 0 and not distance.has(next):
				distance[next] = steps + 1
				queue.append(next)
	var reach := PackedInt32Array(distance.keys())
	reach.sort()
	return reach


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
