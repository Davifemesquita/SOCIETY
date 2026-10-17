class_name RoadPath
extends RefCounted
## Traçado da estrada arrastada: um L entre as duas células, ou (Fase 17) a diagonal.
## O L anda primeiro no eixo da maior distância, que é o que o jogador costuma querer.


static func l_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = [from]
	var delta := to - from
	var corner := Vector2i(to.x, from.y) if absi(delta.x) >= absi(delta.y) else Vector2i(from.x, to.y)
	_walk(cells, from, corner)
	_walk(cells, corner, to)
	return cells


## Traçado diagonal (Fase 17): a escada de células que se tocam pelo canto enquanto as duas distâncias
## sobram, e depois o resto em linha reta. O passo diagonal liga pelo canto onde é diagonal pura (RoadNetwork.linked_diagonal).
static func diagonal_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = [from]
	var cell := from
	while cell != to:
		cell += (to - cell).sign()
		cells.append(cell)
	return cells


static func _walk(cells: Array[Vector2i], from: Vector2i, to: Vector2i) -> void:
	var step := (to - from).sign()
	var cell := from
	while cell != to:
		cell += step
		cells.append(cell)
