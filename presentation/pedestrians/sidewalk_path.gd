class_name SidewalkPath
extends RefCounted
## Rota de pedestre (seção 9: só por estradas e calçadas): as células da estrada viram trechos
## retos, deslocados para a calçada à direita de quem anda. Quem vem em sentido contrário usa a
## outra calçada, e o meio da estrada fica para as carroças.


## Pontos da rota na altura da estrada (sobre a ponte, no rio), já na calçada. Uma célula só dá
## um ponto (não há o que andar).
static func from_cells(grid: IslandGrid, cells: PackedInt32Array, offset: float) -> PackedVector3Array:
	var centers := PackedVector3Array()
	for index: int in cells:
		centers.append(grid.surface_world(grid.cell_at(index)))
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
## calçadas: a soma dos dois deslocamentos esticada pela meia-esquadria (2 / |soma|²), que dá a soma mesma
## na esquina de 90° e o ponto certo na de 45° da diagonal (Fase 17).
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
		elif shift.length_squared() > 0.01:
			shift *= 2.0 / shift.length_squared()
		else:
			# meia-volta: fica do lado de quem chega
			shift = right_of(points[i] - points[i - 1])
		result.append(points[i] + shift * offset)
	return result


## Direita de quem anda na direção dada, no plano do chão (y para cima; a ladeira não conta).
static func right_of(direction: Vector3) -> Vector3:
	return Vector3(direction.x, 0.0, direction.z).normalized().cross(Vector3.UP)


## Comprimento total da rota, medido no chão (a ladeira não conta: o passo é horizontal).
static func length(points: PackedVector3Array) -> float:
	var total := 0.0
	for i: int in range(1, points.size()):
		total += flat_distance(points[i - 1], points[i])
	return total


static func flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(b.x - a.x, b.z - a.z).length()
