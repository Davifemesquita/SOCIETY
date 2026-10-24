class_name RoadNetwork
extends RefCounted
## Leitura da rede de estradas: acesso de um prédio e componentes conectados.
## Rotas (AStarGrid2D) entram na Fase 3, com as carroças. Diagonal pura liga desde a Fase 17.

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


## Rótulo de componente por célula: 0 sem estrada, 1..n para cada trecho conectado. Desde a Fase 17 a diagonal
## pura também liga (linked_diagonal).
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
			# vizinhos sem montar um Array por célula; Fase 29: cada vizinha é lida uma vez
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
			if road_left and labels[next] == 0:
				labels[next] = next_label
				queue.append(next)
			next = index + 1
			if road_right and labels[next] == 0:
				labels[next] = next_label
				queue.append(next)
			if road_up and labels[up] == 0:
				labels[up] = next_label
				queue.append(up)
			if road_down and labels[down] == 0:
				labels[down] = next_label
				queue.append(down)
			# diagonal pura (Fase 17): a célula do canto, sem estrada nas duas vizinhas em comum; numa rua reta ou num
			# cruzamento nenhum canto liga e os quatro ficam de fora (Fase 29)
			var free_up := not road_up and up >= 0
			var free_down := not road_down and down < count
			if not ((free_up or free_down) and (not road_left or not road_right)):
				continue
			next = up - 1
			if has_left and free_up and not road_left and roads[next] != 0 and labels[next] == 0:
				labels[next] = next_label
				queue.append(next)
			next = up + 1
			if has_right and free_up and not road_right and roads[next] != 0 and labels[next] == 0:
				labels[next] = next_label
				queue.append(next)
			next = down - 1
			if has_left and free_down and not road_left and roads[next] != 0 and labels[next] == 0:
				labels[next] = next_label
				queue.append(next)
			next = down + 1
			if has_right and free_down and not road_right and roads[next] != 0 and labels[next] == 0:
				labels[next] = next_label
				queue.append(next)
	return labels


## As duas células se tocam pelo canto, as duas são estrada e nenhuma das duas células que elas têm em comum é
## (diagonal pura, Fase 17): só aí a ligação pelo canto conta. Numa esquina em L a célula do meio já liga.
static func linked_diagonal(grid: IslandGrid, a: Vector2i, b: Vector2i) -> bool:
	var delta := b - a
	if absi(delta.x) != 1 or absi(delta.y) != 1:
		return false
	return grid.has_road(a) and grid.has_road(b) and not grid.has_road(Vector2i(b.x, a.y)) \
			and not grid.has_road(Vector2i(a.x, b.y))


## Rótulos dos trechos de estrada que encostam na entrada do prédio.
static func access_labels(grid: IslandGrid, labels: PackedInt32Array, record: BuildingRecord, def: BuildingDef) -> PackedInt32Array:
	var found := PackedInt32Array()
	for cell: Vector2i in Footprint.front_cells(record.origin, def.size, record.rotation):
		if grid.has_road(cell) and not found.has(labels[grid.index(cell)]):
			found.append(labels[grid.index(cell)])
	return found
