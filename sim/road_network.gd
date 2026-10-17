class_name RoadNetwork
extends RefCounted
## Leitura da rede de estradas: acesso de um prédio e componentes conectados.
## Rotas (AStarGrid2D) entram na Fase 3, com as carroças.

const NEIGHBORS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


## O prédio tem estrada encostada na face de entrada.
static func has_access(grid: IslandGrid, record: BuildingRecord, def: BuildingDef) -> bool:
	# a decoração (Fase 16) não pede estrada: fica bem até no meio da praça
	if def.kind == BuildingDef.Kind.DECORATION:
		return true
	var roads := grid.roads
	for index: int in Footprint.front_indices(grid.size, record.origin, def.size, record.rotation):
		if roads[index] != IslandGrid.Road.NONE:
			return true
	return false


## Rótulo de componente por célula: 0 sem estrada, 1..n para cada trecho conectado.
## Anda por índice da grade: roda sobre a ilha inteira a cada estrada nova.
static func components(grid: IslandGrid) -> PackedInt32Array:
	var roads := grid.roads
	var width := grid.size.x
	var count := roads.size()
	var labels := PackedInt32Array()
	labels.resize(count)
	var next_label := 0
	var queue := PackedInt32Array()
	# pula de estrada em estrada pelo find (em C++): varrer as células da ilha em GDScript custava
	# mais que a busca; um ponteiro por tipo de estrada, sempre o menor, mantém a ordem crescente
	var next_dirt := roads.find(IslandGrid.Road.DIRT)
	var next_paved := roads.find(IslandGrid.Road.PAVED)
	while next_dirt != -1 or next_paved != -1:
		var start := next_dirt if next_paved == -1 or (next_dirt != -1 and next_dirt < next_paved) else next_paved
		if start == next_dirt:
			next_dirt = roads.find(IslandGrid.Road.DIRT, start + 1)
		else:
			next_paved = roads.find(IslandGrid.Road.PAVED, start + 1)
		if labels[start] != 0:
			continue
		next_label += 1
		labels[start] = next_label
		queue.clear()
		queue.append(start)
		var head := 0
		while head < queue.size():
			var index := queue[head]
			head += 1
			# vizinhos sem montar um Array por célula
			var x := index % width
			var next := index - 1
			if x > 0 and roads[next] != 0 and labels[next] == 0:
				labels[next] = next_label
				queue.append(next)
			next = index + 1
			if x < width - 1 and roads[next] != 0 and labels[next] == 0:
				labels[next] = next_label
				queue.append(next)
			next = index - width
			if next >= 0 and roads[next] != 0 and labels[next] == 0:
				labels[next] = next_label
				queue.append(next)
			next = index + width
			if next < count and roads[next] != 0 and labels[next] == 0:
				labels[next] = next_label
				queue.append(next)
	return labels


## Rótulos dos trechos de estrada que encostam na entrada do prédio.
static func access_labels(grid: IslandGrid, labels: PackedInt32Array, record: BuildingRecord, def: BuildingDef) -> PackedInt32Array:
	var found := PackedInt32Array()
	for cell: Vector2i in Footprint.front_cells(record.origin, def.size, record.rotation):
		if grid.has_road(cell) and not found.has(labels[grid.index(cell)]):
			found.append(labels[grid.index(cell)])
	return found
