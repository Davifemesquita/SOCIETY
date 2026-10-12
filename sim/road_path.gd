class_name RoadPath
extends RefCounted
## Traçado da estrada arrastada: um L entre as duas células, sem diagonal.
## Anda primeiro no eixo da maior distância, que é o que o jogador costuma querer.


static func l_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = [from]
	var delta := to - from
	var corner := Vector2i(to.x, from.y) if absi(delta.x) >= absi(delta.y) else Vector2i(from.x, to.y)
	_walk(cells, from, corner)
	_walk(cells, corner, to)
	return cells


static func _walk(cells: Array[Vector2i], from: Vector2i, to: Vector2i) -> void:
	var step := (to - from).sign()
	var cell := from
	while cell != to:
		cell += step
		cells.append(cell)
