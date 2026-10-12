class_name GridSpace
extends RefCounted
## Conversão entre células da grade e metros do mundo 3D. A célula (0, 0) começa na origem
## e o eixo y da grade é o Z do mundo.


static func cell_center(cell: Vector2i, cell_size: float) -> Vector3:
	return Vector3((cell.x + 0.5) * cell_size, 0.0, (cell.y + 0.5) * cell_size)


static func rect_center(area: Rect2i, cell_size: float) -> Vector3:
	return Vector3((area.position.x + area.size.x * 0.5) * cell_size, 0.0, (area.position.y + area.size.y * 0.5) * cell_size)


static func world_to_cell(point: Vector3, cell_size: float) -> Vector2i:
	return Vector2i(floori(point.x / cell_size), floori(point.z / cell_size))


## Retângulo entre duas células quaisquer, incluindo as duas.
static func rect_between(a: Vector2i, b: Vector2i) -> Rect2i:
	var top_left := Vector2i(mini(a.x, b.x), mini(a.y, b.y))
	return Rect2i(top_left, (a - b).abs() + Vector2i.ONE)
