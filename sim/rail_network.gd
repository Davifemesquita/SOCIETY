class_name RailNetwork
extends RefCounted
## Ferrovia (Fase 70): os trilhos de uma ilha em grupos ligados (célula com célula vizinha de lado) e os grupos que um
## prédio toca (trilho encostado num lado do lote). Função pura da grade.

const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


## O número do grupo de cada célula (0 = sem trilho; os grupos começam em 1).
static func groups(grid: IslandGrid) -> PackedInt32Array:
	var labels := PackedInt32Array()
	labels.resize(grid.rails.size())
	var next := 0
	for start: int in grid.rails.size():
		if grid.rails[start] == 0 or labels[start] != 0:
			continue
		next += 1
		labels[start] = next
		var queue: Array[int] = [start]
		while not queue.is_empty():
			var at: int = queue.pop_back()
			var cell := grid.cell_at(at)
			for side: Vector2i in SIDES:
				var near := cell + side
				if not grid.in_bounds(near):
					continue
				var index := grid.index(near)
				if grid.rails[index] != 0 and labels[index] == 0:
					labels[index] = next
					queue.append(index)
	return labels


## Os grupos de trilho encostados no lote do prédio (sem repetir).
static func touching(grid: IslandGrid, labels: PackedInt32Array, record: BuildingRecord, def: BuildingDef) -> PackedInt32Array:
	var found := PackedInt32Array()
	for cell: Vector2i in side_cells(grid, record, def):
		var group := labels[grid.index(cell)]
		if group != 0 and not found.has(group):
			found.append(group)
	return found


## As células encostadas num lado do lote (sem os cantos de fora: o trilho encosta num lado), dentro da grade.
static func side_cells(grid: IslandGrid, record: BuildingRecord, def: BuildingDef) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var ring := area.grow(1)
	for y: int in range(ring.position.y, ring.end.y):
		for x: int in range(ring.position.x, ring.end.x):
			var cell := Vector2i(x, y)
			if area.has_point(cell) or not grid.in_bounds(cell):
				continue
			if (x < area.position.x or x >= area.end.x) and (y < area.position.y or y >= area.end.y):
				continue
			cells.append(cell)
	return cells


## Trem na tela (Fase 71): o caminho mais curto pelo trilho, célula a célula (vizinhas de lado), de uma célula de trilho
## encostada no lote de from até uma encostada no lote de to; vazio se nenhum trilho liga os dois.
static func route(grid: IslandGrid, from: BuildingRecord, from_def: BuildingDef, to: BuildingRecord, to_def: BuildingDef) -> Array[Vector2i]:
	var goals: Dictionary[int, bool] = {}
	for cell: Vector2i in side_cells(grid, to, to_def):
		if grid.has_rail(cell):
			goals[grid.index(cell)] = true
	var came: Dictionary[int, int] = {}
	var queue: Array[int] = []
	for cell: Vector2i in side_cells(grid, from, from_def):
		if grid.has_rail(cell):
			came[grid.index(cell)] = -1
			queue.append(grid.index(cell))
	var head := 0
	while head < queue.size():
		var at := queue[head]
		head += 1
		if goals.has(at):
			var path: Array[Vector2i] = []
			while at != -1:
				path.push_front(grid.cell_at(at))
				at = came[at]
			return path
		var cell := grid.cell_at(at)
		for side: Vector2i in SIDES:
			var near := cell + side
			if not grid.in_bounds(near) or not grid.has_rail(near):
				continue
			var index := grid.index(near)
			if not came.has(index):
				came[index] = at
				queue.append(index)
	return []
