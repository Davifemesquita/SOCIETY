class_name SideYard
extends RefCounted
## As duas células encostadas no meio de um lado de um prédio (Fase 219; antes, a busca das tábuas da Fase 215 e a do carvão
## da Fase 216, que a repetia): a busca do lado livre, na ordem pedida no referencial do modelo, e o lugar no mundo do meio das
## duas células, com o +z para longe da parede.

const MAX_RELIEF_M := 0.8
## Os lados no referencial do modelo (o +Z é o fundo; a frente, a da estrada, fica em −Z).
const MINUS_X := Vector2i(-1, 0)
const PLUS_X := Vector2i(1, 0)
const BACK := Vector2i(0, 1)


## Para cada prédio de def_ids na ilha (pela ordem dos ids), o primeiro lado de order (no referencial do modelo) com as duas
## células do meio livres e fora de taken → [as duas células, o lado na grade]. As células escolhidas entram em taken.
static func pick(world: WorldState, data: GameData, island_id: int, def_ids: Array[StringName], order: Array[Vector2i],
		taken: Dictionary[Vector2i, bool]) -> Dictionary[int, Array]:
	var result: Dictionary[int, Array] = {}
	var grid := world.island(island_id)
	if grid == null:
		return result
	var ids: Array[int] = []
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id == island_id and record.def_id in def_ids:
			ids.append(id)
	if ids.is_empty():
		return result
	ids.sort()
	if not grid.flat:
		taken.merge(ForecourtView.cells(world, data, island_id))
		taken.merge(AvenueView.cells(world, island_id))
	for id: int in ids:
		var record := world.buildings[id]
		var area := Footprint.rect(record.origin, data.building(record.def_id).size, record.rotation)
		var model := BuildingView.model_place(grid, record, area)
		# os eixos do modelo na grade
		var plus_x := Vector2i(roundi(model.basis.x.x), roundi(model.basis.x.z))
		var plus_z := Vector2i(roundi(model.basis.z.x), roundi(model.basis.z.z))
		for local: Vector2i in order:
			var side := plus_x * local.x + plus_z * local.y
			var cells := pair(area, side)
			if not is_free(grid, cells[0], taken) or not is_free(grid, cells[1], taken):
				continue
			for cell: Vector2i in cells:
				taken[cell] = true
			result[id] = [cells, side]
			break
	return result


## As duas células do meio do lado side, encostadas na área.
static func pair(area: Rect2i, side: Vector2i) -> Array[Vector2i]:
	var middle := area.position + area.size / 2
	if side.x > 0:
		return [Vector2i(area.end.x, middle.y - 1), Vector2i(area.end.x, middle.y)]
	if side.x < 0:
		return [Vector2i(area.position.x - 1, middle.y - 1), Vector2i(area.position.x - 1, middle.y)]
	if side.y > 0:
		return [Vector2i(middle.x - 1, area.end.y), Vector2i(middle.x, area.end.y)]
	return [Vector2i(middle.x - 1, area.position.y - 1), Vector2i(middle.x, area.position.y - 1)]


## A célula serve: de terra, sem prédio, estrada, trilho nem árvore, fora de taken e quase plana.
static func is_free(grid: IslandGrid, cell: Vector2i, taken: Dictionary[Vector2i, bool]) -> bool:
	if not grid.in_bounds(cell) or taken.has(cell):
		return false
	var index := grid.index(cell)
	# a ilha plana (testes, saves antigos) não tem chão nem árvores na grade
	if not grid.is_land(cell) or grid.occupancy[index] != 0 or grid.roads[index] != IslandGrid.Road.NONE \
			or grid.rails[index] != 0 or (not grid.flat and grid.trees[index] > 0):
		return false
	var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
	return corners.y - corners.x <= MAX_RELIEF_M


## As células escolhidas → o id do prédio.
static func cells_of(found: Dictionary[int, Array]) -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}
	for id: int in found:
		var site: Array = found[id]
		var cells: Array[Vector2i] = site[0]
		for cell: Vector2i in cells:
			result[cell] = id
	return result


## O meio das duas células no chão (o mais baixo dos cantos delas), com o x ao longo da parede e o +z para fora dela (base de
## mão direita: x = cima × fora).
static func place(grid: IslandGrid, cells: Array[Vector2i], side: Vector2i) -> Transform3D:
	var at := (grid.cell_world(cells[0]) + grid.cell_world(cells[1])) * 0.5
	at.y = minf(BuildingKit.corner_range(grid, Rect2i(cells[0], Vector2i.ONE)).x,
			BuildingKit.corner_range(grid, Rect2i(cells[1], Vector2i.ONE)).x)
	return Transform3D(Basis(Vector3(side.y, 0.0, -side.x), Vector3.UP, Vector3(side.x, 0.0, side.y)), at)
