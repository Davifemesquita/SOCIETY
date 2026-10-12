class_name SidewalkPath
extends RefCounted
## Rota de pedestre (seção 9: só por estradas e calçadas): as células da estrada viram trechos
## retos, deslocados para a calçada à direita de quem anda. Quem vem em sentido contrário usa a
## outra calçada, e o meio da estrada fica para as carroças.


## Pontos da rota no chão (y = 0), já na calçada. Uma célula só dá um ponto (não há o que andar).
static func from_cells(grid: IslandGrid, cells: PackedInt32Array, cell_size: float, offset: float) -> PackedVector3Array:
	var centers := PackedVector3Array()
	for index: int in cells:
		var center := GridSpace.cell_center(grid.cell_at(index), cell_size)
		centers.append(Vector3(center.x, 0.0, center.z))
	return offset_polyline(simplify(centers), offset)


## Tira os pontos do meio de trechos retos: sobram as pontas e as esquinas.
static func simplify(points: PackedVector3Array) -> PackedVector3Array:
	if points.size() <= 2:
		return points
	var result := PackedVector3Array([points[0]])
	for i: int in range(1, points.size() - 1):
		var before := (points[i] - points[i - 1]).normalized()
		var after := (points[i + 1] - points[i]).normalized()
		if not before.is_equal_approx(after):
			result.append(points[i])
	result.append(points[points.size() - 1])
	return result


## Desloca a linha para a direita de quem anda. Na esquina, o ponto é o encontro das duas
## calçadas (soma dos dois deslocamentos, que são perpendiculares numa grade).
static func offset_polyline(points: PackedVector3Array, offset: float) -> PackedVector3Array:
	if points.size() < 2:
		return points
	var result := PackedVector3Array()
	for i: int in points.size():
		var shift := Vector3.ZERO
		if i > 0:
			shift += right_of(points[i] - points[i - 1])
		if i < points.size() - 1:
			shift += right_of(points[i + 1] - points[i])
		if i == 0 or i == points.size() - 1:
			shift = shift.normalized()
		result.append(points[i] + shift * offset)
	return result


## Direita de quem anda na direção dada, no plano do chão (y para cima).
static func right_of(direction: Vector3) -> Vector3:
	return direction.normalized().cross(Vector3.UP)


## Comprimento total da rota.
static func length(points: PackedVector3Array) -> float:
	var total := 0.0
	for i: int in range(1, points.size()):
		total += points[i].distance_to(points[i - 1])
	return total
