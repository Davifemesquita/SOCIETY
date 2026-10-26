class_name PavedDual
extends RefCounted
## Calçamento em grade dual (Fase 46): o paralelepípedo não é mais um ladrilho quadrado por célula. Cada canto da grade
## olha as quatro células em volta (máscara de 4 bits: 1 a de cima à esquerda, 2 a de cima à direita, 4 a de baixo à
## direita, 8 a de baixo à esquerda, no sentido do relógio visto de cima) e desenha a peça do caso — vazio, canto de
## fora (arredondado), borda reta, sela (as duas da diagonal: faixa se a simulação as liga, dois cantos se não), canto
## de dentro (concordância) ou cheio — girada. Meio-fio e sarjeta ficam dentro da peça. Tudo numa malha por ilha, que
## guarda a geometria de cada canto e refaz só os cantos que uma estrada nova atinge.

enum Piece { EMPTY, OUTER, EDGE, SADDLE, INNER, FULL }

## Raio do arredondamento (fração da meia célula) e as medidas do meio-fio e da sarjeta (m).
const ROUND := 0.8
const CURB_WIDTH_M := 0.22
const CURB_HEIGHT_M := 0.1
const GUTTER_WIDTH_M := 0.3
## Altura do calçamento sobre o chão (acima da terra pintada, abaixo de nada).
const LIFT_M := 0.07
## Segmentos de cada quarto de volta.
const ARC_STEPS := 6
## Cor do vértice: r = 1 calçamento, GUTTER_TONE na sarjeta; b = 1 no meio-fio (o shader escolhe a pedra).
const GUTTER_TONE := 0.55
## Bits das células em volta do canto (x, y): a célula (x − 1, y − 1), (x, y − 1), (x, y) e (x − 1, y).
const AROUND: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(0, 0), Vector2i(-1, 0)]


## Peça e giro (quartos de volta no sentido do relógio) de uma máscara.
static func case_of(mask: int) -> Vector2i:
	var canonical: Dictionary[int, int] = {0: Piece.EMPTY, 1: Piece.OUTER, 3: Piece.EDGE, 5: Piece.SADDLE, 7: Piece.INNER,
			15: Piece.FULL}
	for turn: int in 4:
		var back := _rotate(mask, -turn)
		if canonical.has(back):
			return Vector2i(canonical[back], turn)
	return Vector2i(Piece.EMPTY, 0)


## A máscara girada "turn" quartos no sentido do relógio.
static func _rotate(mask: int, turn: int) -> int:
	var steps := posmod(turn, 4)
	var result := mask
	for k: int in steps:
		result = ((result << 1) | (result >> 3)) & 15
	return result


## A célula conta como calçada no canto: paralelepípedo (a ponte de pedra conta, para não sair meio-fio de través na
## cabeceira; o tabuleiro dela é da RoadView e cobre o que fica embaixo). Na diagonal, cada célula fica um quadrado de
## cantos redondos e a sela entre duas ligadas vira a faixa: sem escada de quadrados.
static func paved_for_dual(grid: IslandGrid, cell: Vector2i) -> bool:
	return grid.in_bounds(cell) and grid.is_paved(cell)


static func mask_at(grid: IslandGrid, corner: Vector2i) -> int:
	var mask := 0
	for bit: int in 4:
		if paved_for_dual(grid, corner + AROUND[bit]):
			mask |= 1 << bit
	return mask


## Na sela, as duas células da diagonal estão ligadas pela simulação (a diagonal pura)?
static func saddle_linked(grid: IslandGrid, corner: Vector2i, mask: int) -> bool:
	var a := corner + (AROUND[0] if mask & 1 else AROUND[1])
	var b := corner + (AROUND[2] if mask & 1 else AROUND[3])
	return RoadNetwork.linked_diagonal(grid, a, b)


## A geometria de um canto: [vértices, cores, normais] em triângulos, no mundo (a normal de cada triângulo já calculada:
## montar a malha é só juntar os arrays).
static func corner_geometry(grid: IslandGrid, corner: Vector2i) -> Array:
	var mask := mask_at(grid, corner)
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	if mask == 0:
		return [vertices, colors, PackedVector3Array()]
	var piece := case_of(mask)
	var h := grid.cell_size * 0.5
	var r := h * ROUND
	var center := Vector2(grid.origin_m) + Vector2(corner) * grid.cell_size
	var turn := Transform2D(PI * 0.5 * piece.y, center)
	var add := func(shape: PackedVector2Array, tone: float, curb: bool) -> void:
		_fill(grid, turn, shape, tone, curb, vertices, colors)
	match piece.x:
		Piece.FULL:
			add.call(_rect(-h, -h, h, h), 1.0, false)
		Piece.EDGE:
			# as duas de cima calçadas: a borda em z = 0 (a sarjeta e o meio-fio por cima do calçamento)
			add.call(_rect(-h, -h, h, 0.0), 1.0, false)
			add.call(_rect(-h, -CURB_WIDTH_M - GUTTER_WIDTH_M, h, -CURB_WIDTH_M), GUTTER_TONE, false)
			_curb_strip(grid, turn, [Vector2(-h, -CURB_WIDTH_M * 0.5), Vector2(h, -CURB_WIDTH_M * 0.5)], vertices, colors)
		Piece.OUTER:
			# a célula sozinha no canto é da faixa diagonal que passa ao lado: o canto segue a reta da faixa (sem gomo)
			if in_side_diagonal(grid, turn):
				_chamfer(grid, turn, h, vertices, colors, add)
			else:
				_outer(grid, turn, h, r, vertices, colors, add)
		Piece.INNER:
			_inner(grid, turn, h, r, vertices, colors, add)
		Piece.SADDLE:
			if saddle_linked(grid, corner, mask):
				_band(grid, turn, h, vertices, colors, add)
			else:
				_outer(grid, turn, h, r, vertices, colors, add)
				_outer(grid, turn * Transform2D(PI, Vector2.ZERO), h, r, vertices, colors, add)
	return [vertices, colors, normals_of(vertices)]


## Canto de fora (só a célula de cima à esquerda): o quarto calçado, arredondado em volta de (−r, −r).
static func _outer(grid: IslandGrid, turn: Transform2D, h: float, r: float, vertices: PackedVector3Array,
		colors: PackedColorArray, add: Callable) -> void:
	var inset := CURB_WIDTH_M + GUTTER_WIDTH_M
	add.call(_rounded_quarter(h, r, 0.0), 1.0, false)
	var gutter := _ring_between(_rounded_edge(h, r, inset), _rounded_edge(h, r, CURB_WIDTH_M))
	for shape: PackedVector2Array in gutter:
		add.call(shape, GUTTER_TONE, false)
	_curb_strip(grid, turn, _rounded_edge(h, r, CURB_WIDTH_M * 0.5), vertices, colors)


## A célula do canto de fora (a de cima à esquerda, no giro da peça) está ligada pela simulação a uma das vizinhas na
## diagonal que passa ao lado do canto (a de cima à direita ou a de baixo à esquerda dela)?
static func in_side_diagonal(grid: IslandGrid, turn: Transform2D) -> bool:
	var h := grid.cell_size * 0.5
	var cell := _cell_under(grid, turn * Vector2(-h, -h))
	for partner: Vector2 in [Vector2(h, -3.0 * h), Vector2(-3.0 * h, h)]:
		var other := _cell_under(grid, turn * partner)
		if paved_for_dual(grid, other) and RoadNetwork.linked_diagonal(grid, cell, other):
			return true
	return false


static func _cell_under(grid: IslandGrid, point: Vector2) -> Vector2i:
	return Vector2i(((point - Vector2(grid.origin_m)) / grid.cell_size).floor())


## Canto de fora numa diagonal: a faixa que passa pelo centro da célula (na direção da diagonal ao lado do canto), a
## mesma largura e o mesmo meio-fio da faixa da sela, cortada pelo quadrado da peça.
static func _chamfer(grid: IslandGrid, turn: Transform2D, h: float, vertices: PackedVector3Array, colors: PackedColorArray,
		add: Callable) -> void:
	var half := h * 0.95
	var along := Vector2(1.0, -1.0).normalized()
	var across := Vector2(1.0, 1.0).normalized()
	var origin := Vector2(-h, -h)
	var inner := half - CURB_WIDTH_M - GUTTER_WIDTH_M
	var reach := h * 4.0
	var square := _rect(-h, -h, h, h)
	var strip := func(a: float, b: float) -> PackedVector2Array:
		var shape := PackedVector2Array([origin + across * a - along * reach, origin + across * a + along * reach,
				origin + across * b + along * reach, origin + across * b - along * reach])
		var clipped := Geometry2D.intersect_polygons(shape, square)
		return clipped[0] if not clipped.is_empty() else PackedVector2Array()
	add.call(strip.call(-half, half), 1.0, false)
	add.call(strip.call(inner, half - CURB_WIDTH_M), GUTTER_TONE, false)
	var middle := half - CURB_WIDTH_M * 0.5
	var line := PackedVector2Array([origin + across * middle - along * reach, origin + across * middle + along * reach])
	for piece: PackedVector2Array in Geometry2D.intersect_polyline_with_polygon(line, square):
		_curb_strip(grid, turn, Array(piece), vertices, colors)


## Canto de dentro (três calçadas, a de baixo à esquerda vazia): os três quartos e a concordância em volta de (−r, r).
static func _inner(grid: IslandGrid, turn: Transform2D, h: float, r: float, vertices: PackedVector3Array,
		colors: PackedColorArray, add: Callable) -> void:
	var inset := CURB_WIDTH_M + GUTTER_WIDTH_M
	add.call(_rect(-h, -h, 0.0, 0.0), 1.0, false)
	add.call(_rect(0.0, -h, h, h), 1.0, false)
	# o quarto vazio ganha a concordância (do canto até o arco); a sarjeta e o meio-fio seguem a borda deslocada para
	# dentro do calçamento (as retas em x = d e z = −d e o arco de raio r + d)
	var fill := PackedVector2Array([Vector2(0.0, 0.0)])
	fill.append_array(_fillet_arc(r, 0.0))
	add.call(fill, 1.0, false)
	for shape: PackedVector2Array in _ring_between(_fillet_edge(h, r, inset), _fillet_edge(h, r, CURB_WIDTH_M)):
		add.call(shape, GUTTER_TONE, false)
	_curb_strip(grid, turn, _fillet_edge(h, r, CURB_WIDTH_M * 0.5), vertices, colors)


## Sela ligada: a faixa a 45° da célula de cima à esquerda à de baixo à direita, com o meio-fio nos dois lados.
static func _band(grid: IslandGrid, turn: Transform2D, h: float, vertices: PackedVector3Array, colors: PackedColorArray,
		add: Callable) -> void:
	var half := h * 0.95
	var along := Vector2(1.0, 1.0).normalized()
	var across := Vector2(-1.0, 1.0).normalized()
	var inner := half - CURB_WIDTH_M - GUTTER_WIDTH_M
	add.call(_strip(along, across, -half, half, h), 1.0, false)
	for side: float in [-1.0, 1.0]:
		add.call(_strip(along, across, side * inner, side * (half - CURB_WIDTH_M), h), GUTTER_TONE, false)
		var middle := side * (half - CURB_WIDTH_M * 0.5)
		# a reta cortada pelo quadrado da peça (|x| e |z| até h)
		var reach := h * sqrt(2.0) - absf(middle)
		_curb_strip(grid, turn, [across * middle - along * reach, across * middle + along * reach], vertices, colors)


## Faixa entre as distâncias a e b do eixo "along", de comprimento 2 × reach (cortada pelo quadrado da peça).
static func _strip(along: Vector2, across: Vector2, a: float, b: float, h: float) -> PackedVector2Array:
	var reach := h * 1.41
	var shape := PackedVector2Array([across * a - along * reach, across * a + along * reach, across * b + along * reach,
			across * b - along * reach])
	var clipped := Geometry2D.intersect_polygons(shape, _rect(-h, -h, h, h))
	return clipped[0] if not clipped.is_empty() else PackedVector2Array()


static func _rect(x0: float, z0: float, x1: float, z1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)])


## O quarto de cima à esquerda calçado, recuado "inset" das divisas com as vazias e arredondado no canto.
static func _rounded_quarter(h: float, r: float, inset: float) -> PackedVector2Array:
	var shape := PackedVector2Array([Vector2(-h, -h)])
	shape.append_array(_reverse(_rounded_edge(h, r, inset)))
	return shape


## A borda do canto de fora a "inset" da divisa: de (−h, −inset) pela volta até (−inset, −h).
static func _rounded_edge(h: float, r: float, inset: float) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2(-h, -inset)])
	var radius := maxf(r - inset, 0.01)
	for k: int in ARC_STEPS + 1:
		var angle := PI * 0.5 * k / ARC_STEPS
		points.append(Vector2(-r, -r) + Vector2(sin(angle), cos(angle)) * radius)
	points.append(Vector2(-inset, -h))
	return points


## O arco da concordância do canto de dentro, em volta de (−r, r) com raio r + inset: de (inset, r) a (−r, −inset).
static func _fillet_arc(r: float, inset: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for k: int in ARC_STEPS + 1:
		var angle := PI * 0.5 * k / ARC_STEPS
		points.append(Vector2(-r, r) + Vector2(cos(angle), -sin(angle)) * (r + inset))
	return points


## A borda do canto de dentro deslocada "inset" para dentro do calçamento: a reta x = inset desde a borda da peça, o
## arco e a reta z = −inset até a outra borda.
static func _fillet_edge(h: float, r: float, inset: float) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2(inset, h)])
	points.append_array(_fillet_arc(r, inset))
	points.append(Vector2(-h, -inset))
	return points


## A faixa entre duas linhas paralelas (mesmo número de pontos), em quadriláteros.
static func _ring_between(a: PackedVector2Array, b: PackedVector2Array) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for k: int in mini(a.size(), b.size()) - 1:
		result.append(PackedVector2Array([a[k], a[k + 1], b[k + 1], b[k]]))
	return result


static func _reverse(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for k: int in range(points.size() - 1, -1, -1):
		result.append(points[k])
	return result


## Um polígono plano do calçamento (ou da sarjeta) triangulado, no chão, de frente para cima.
static func _fill(grid: IslandGrid, turn: Transform2D, shape: PackedVector2Array, tone: float, curb: bool,
		vertices: PackedVector3Array, colors: PackedColorArray) -> void:
	if shape.size() < 3:
		return
	var world := PackedVector2Array()
	for point: Vector2 in shape:
		world.append(turn * point)
	var indices := Geometry2D.triangulate_polygon(world)
	if indices.is_empty():
		indices = Geometry2D.triangulate_polygon(_reverse(world))
		world = _reverse(world)
	var color := Color(tone, 0.0, 1.0 if curb else 0.0)
	# a sarjeta fica um centímetro acima do calçamento que ela cobre (sem brigar com ele)
	var up := LIFT_M + (0.01 if tone < 1.0 else 0.0)
	for k: int in range(0, indices.size(), 3):
		var a := _lift(grid, world[indices[k]], up)
		var b := _lift(grid, world[indices[k + 1]], up)
		var c := _lift(grid, world[indices[k + 2]], up)
		_triangle_up(vertices, colors, a, b, c, color)


## O meio-fio ao longo da linha (do meio dele): o tampo CURB_HEIGHT_M acima do calçamento e os dois lados.
static func _curb_strip(grid: IslandGrid, turn: Transform2D, line: Array, vertices: PackedVector3Array,
		colors: PackedColorArray) -> void:
	var color := Color(1.0, 0.0, 1.0)
	var points := PackedVector2Array()
	for point: Vector2 in line:
		points.append(turn * point)
	for k: int in points.size() - 1:
		var a := points[k]
		var b := points[k + 1]
		var side := (b - a).orthogonal().normalized() * CURB_WIDTH_M * 0.5
		var corners: Array[Vector2] = [a - side, b - side, b + side, a + side]
		var low: Array[Vector3] = []
		var high: Array[Vector3] = []
		for corner: Vector2 in corners:
			low.append(_lift(grid, corner, LIFT_M - 0.02))
			high.append(_lift(grid, corner, LIFT_M + CURB_HEIGHT_M))
		_triangle_up(vertices, colors, high[0], high[1], high[2], color)
		_triangle_up(vertices, colors, high[0], high[2], high[3], color)
		# os dois lados compridos
		for pair: Vector2i in [Vector2i(0, 1), Vector2i(2, 3)]:
			_quad_side(vertices, colors, low[pair.x], low[pair.y], high[pair.y], high[pair.x], color)


static func _lift(grid: IslandGrid, point: Vector2, up: float) -> Vector3:
	return Vector3(point.x, grid.height_at(point.x, point.y) + up, point.y)


## Triângulo de frente para cima (o Godot vê a frente no sentido do relógio).
static func _triangle_up(vertices: PackedVector3Array, colors: PackedColorArray, a: Vector3, b: Vector3, c: Vector3,
		color: Color) -> void:
	if (b - a).cross(c - a).y < 0.0:
		vertices.append_array([a, b, c])
	else:
		vertices.append_array([a, c, b])
	colors.append_array([color, color, color])


## Face de pé do meio-fio, nos dois sentidos (o lado de fora e o de dentro aparecem).
static func _quad_side(vertices: PackedVector3Array, colors: PackedColorArray, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		color: Color) -> void:
	vertices.append_array([a, b, c, a, c, d, a, c, b, a, d, c])
	for k: int in 12:
		colors.append(color)


## A normal de cada triângulo (a mesma nos três vértices), no sentido em que o Godot vê a frente.
static func normals_of(vertices: PackedVector3Array) -> PackedVector3Array:
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	for k: int in range(0, vertices.size(), 3):
		var normal := (vertices[k + 2] - vertices[k]).cross(vertices[k + 1] - vertices[k]).normalized()
		normals[k] = normal
		normals[k + 1] = normal
		normals[k + 2] = normal
	return normals


## Uma malha a partir da geometria dos cantos (null se não há calçamento): só junta os arrays.
static func build_mesh(parts: Dictionary) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var normals := PackedVector3Array()
	for part: Array in parts.values():
		var part_vertices: PackedVector3Array = part[0]
		var part_colors: PackedColorArray = part[1]
		var part_normals: PackedVector3Array = part[2]
		vertices.append_array(part_vertices)
		colors.append_array(part_colors)
		normals.append_array(part_normals)
	if vertices.is_empty():
		return null
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
