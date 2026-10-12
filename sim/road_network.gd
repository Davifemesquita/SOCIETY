class_name RoadNetwork
extends RefCounted
## Leitura da rede de estradas: acesso de um prédio e componentes conectados.
## Rotas (AStarGrid2D) entram na Fase 3, com as carroças.

const NEIGHBORS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


## O prédio tem estrada encostada na face de entrada.
static func has_access(grid: IslandGrid, record: BuildingRecord, def: BuildingDef) -> bool:
	for cell: Vector2i in Footprint.front_cells(record.origin, def.size, record.rotation):
		if grid.has_road(cell):
			return true
	return false


## Rótulo de componente por célula: 0 sem estrada, 1..n para cada trecho conectado.
static func components(grid: IslandGrid) -> PackedInt32Array:
	var labels := PackedInt32Array()
	labels.resize(grid.roads.size())
	var next_label := 0
	for start: int in grid.roads.size():
		if grid.roads[start] == IslandGrid.Road.NONE or labels[start] != 0:
			continue
		next_label += 1
		labels[start] = next_label
		var queue: Array[Vector2i] = [grid.cell_at(start)]
		var head := 0
		while head < queue.size():
			var cell := queue[head]
			head += 1
			for offset: Vector2i in NEIGHBORS:
				var neighbor := cell + offset
				if grid.has_road(neighbor) and labels[grid.index(neighbor)] == 0:
					labels[grid.index(neighbor)] = next_label
					queue.append(neighbor)
	return labels


## Rótulos dos trechos de estrada que encostam na entrada do prédio.
static func access_labels(grid: IslandGrid, labels: PackedInt32Array, record: BuildingRecord, def: BuildingDef) -> PackedInt32Array:
	var found := PackedInt32Array()
	for cell: Vector2i in Footprint.front_cells(record.origin, def.size, record.rotation):
		if grid.has_road(cell) and not found.has(labels[grid.index(cell)]):
			found.append(labels[grid.index(cell)])
	return found
