class_name Footprint
extends RefCounted
## Geometria de um prédio na grade: retângulo girado e face de entrada.
## Rotação 0 põe a frente em −Z (y menor); cada passo gira 90° no sentido horário visto de cima:
## 0 = −Z, 1 = +X, 2 = +Z, 3 = −X.

const FRONT_DIRECTIONS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]


static func rotated_size(size: Vector2i, rotation: int) -> Vector2i:
	return Vector2i(size.y, size.x) if rotation % 2 == 1 else size


static func rect(origin: Vector2i, size: Vector2i, rotation: int) -> Rect2i:
	return Rect2i(origin, rotated_size(size, rotation))


## Origem que deixa a célula dada no centro do prédio (usada pelo cursor).
static func origin_centered_on(cell: Vector2i, size: Vector2i, rotation: int) -> Vector2i:
	var rotated := rotated_size(size, rotation)
	return cell - Vector2i(rotated.x / 2, rotated.y / 2)


static func front_direction(rotation: int) -> Vector2i:
	return FRONT_DIRECTIONS[posmod(rotation, 4)]


## As células logo à frente da face de entrada, fora do prédio.
static func front_cells(origin: Vector2i, size: Vector2i, rotation: int) -> Array[Vector2i]:
	var area := rect(origin, size, rotation)
	var cells: Array[Vector2i] = []
	match posmod(rotation, 4):
		0:
			for x: int in range(area.position.x, area.end.x):
				cells.append(Vector2i(x, area.position.y - 1))
		1:
			for y: int in range(area.position.y, area.end.y):
				cells.append(Vector2i(area.end.x, y))
		2:
			for x: int in range(area.position.x, area.end.x):
				cells.append(Vector2i(x, area.end.y))
		3:
			for y: int in range(area.position.y, area.end.y):
				cells.append(Vector2i(area.position.x - 1, y))
	return cells


## A célula do meio da frente, onde fica a porta.
static func entrance_cell(origin: Vector2i, size: Vector2i, rotation: int) -> Vector2i:
	var cells := front_cells(origin, size, rotation)
	return cells[cells.size() / 2]
