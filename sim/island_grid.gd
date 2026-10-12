class_name IslandGrid
extends RefCounted
## Mapa espacial de uma ilha: ocupação por prédio e estradas, em arrays compactos.
## Célula (x, y) fica no índice y * width + x. Ocupação 0 = livre; senão, o id do prédio.

enum Road { NONE = 0, DIRT = 1 }

var size: Vector2i
var occupancy: PackedInt32Array
var roads: PackedByteArray


func _init(grid_size: Vector2i) -> void:
	size = grid_size
	occupancy.resize(size.x * size.y)
	roads.resize(size.x * size.y)


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func contains_rect(area: Rect2i) -> bool:
	return Rect2i(Vector2i.ZERO, size).encloses(area)


func index(cell: Vector2i) -> int:
	return cell.y * size.x + cell.x


func cell_at(cell_index: int) -> Vector2i:
	return Vector2i(cell_index % size.x, cell_index / size.x)


func building_at(cell: Vector2i) -> int:
	return occupancy[index(cell)] if in_bounds(cell) else 0


func has_road(cell: Vector2i) -> bool:
	return in_bounds(cell) and roads[index(cell)] != Road.NONE


func fill_building(area: Rect2i, building_id: int) -> void:
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			occupancy[y * size.x + x] = building_id


func set_road(cell: Vector2i, road: Road) -> void:
	roads[index(cell)] = road


func road_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for i: int in roads.size():
		if roads[i] != Road.NONE:
			cells.append(cell_at(i))
	return cells
