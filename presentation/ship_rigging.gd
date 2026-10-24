class_name ShipRigging
extends RefCounted
## Convés e cordame (Fase 26): o cordame e a carga no convés dos navios de modelo (Kenney Pirate Kit), que vêm
## só com mastros, velas e bandeiras. Tudo no espaço do modelo (o ShipView o estica e gira), lido do próprio
## modelo: o alto de cada mastro é a bandeira dele, e a borda e o bico de proa saem dos vértices do casco.
## Assim o mesmo código serve aos três navios do kit. A proa do modelo fica em +z.

## Altura do convés, em unidades do modelo (a mesma nos três navios do kit).
const DECK_Y := 2.1
## Ovéns: quantos de cada lado por mastro, quanto abaixo da bandeira eles saem e o espaço entre os pés na
## borda, puxando para a popa a partir do través do mastro.
const SHROUDS := 3
const SHROUD_DROP := 0.35
const SHROUD_SPREAD := 0.45
## O estai entre dois mastros chega ao de vante nesta fração da altura dele acima do convés.
const STAY_FOOT := 0.35
## Raio do cabo no mundo (m) e a barriga dos estais (fração do vão).
const ROPE_RADIUS_M := 0.03
const STAY_SAG := 0.01
const ROPE_COLOR := Color(0.24, 0.18, 0.12)
## Carga no convés: uma peça por porão ocupado, em duas filas (± DECK_CARGO_X do meio) a partir de
## DECK_CARGO_AHEAD à frente do mastro grande, uma a cada DECK_CARGO_STEP (unidades do modelo).
const DECK_CARGO_X := 1.2
const DECK_CARGO_AHEAD := 0.9
const DECK_CARGO_STEP := 0.75
## A borda no corte do casco: os pontos a mais de RAIL_BAND da largura do mais largo contam para a altura dela
## (o costado bojudo é mais largo um pouco abaixo da amurada; os mastros, no meio, ficam de fora).
const RAIL_BAND := 0.7


## O alto dos mastros: a origem de cada bandeira no espaço do modelo, da proa para a popa.
static func mast_tops(model: Node3D) -> Array[Vector3]:
	var tops: Array[Vector3] = []
	for node: Node in model.find_children("flag*", "Node3D", true, false):
		tops.append(ShipView._transform_to(model, node as Node3D).origin)
	tops.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.z > b.z)
	return tops


## Os triângulos do casco no espaço do modelo (sem velas e bandeiras), três vértices cada, sem índice.
static func hull_points(model: Node3D) -> PackedVector3Array:
	var points := PackedVector3Array()
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var name := String(node.name)
		if name.begins_with("flag") or name.begins_with("sail"):
			continue
		var mesh: MeshInstance3D = node
		var place := ShipView._transform_to(model, mesh)
		for surface: int in mesh.mesh.get_surface_count():
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			if indices.is_empty():
				for vertex: Vector3 in vertices:
					points.append(place * vertex)
			else:
				for index: int in indices:
					points.append(place * vertices[index])
	return points


## A borda em z: a meia largura (x) e a altura (y) do alto dela, no corte do casco pelo plano desse z (as
## arestas dos triângulos que o atravessam). O casco tem poucos vértices — uma face comprida atravessa metros
## sem nenhum —, então o corte é que dá a borda onde o cabo chega.
static func rail_at(points: PackedVector3Array, z: float) -> Vector2:
	var cut := PackedVector2Array()
	for t: int in range(0, points.size() - 2, 3):
		for edge: int in 3:
			var a := points[t + edge]
			var b := points[t + (edge + 1) % 3]
			if (a.z - z) * (b.z - z) > 0.0 or is_equal_approx(a.z, b.z):
				continue
			var at := a.lerp(b, (z - a.z) / (b.z - a.z))
			cut.append(Vector2(absf(at.x), at.y))
	var widest := 0.0
	for point: Vector2 in cut:
		widest = maxf(widest, point.x)
	var height := 0.0
	for point: Vector2 in cut:
		if point.x > widest * RAIL_BAND:
			height = maxf(height, point.y)
	return Vector2(widest, height)


## O bico de proa: o vértice mais à vante, no meio, na altura mais alta dele.
static func bow_point(points: PackedVector3Array) -> Vector3:
	var front := -INF
	for point: Vector3 in points:
		front = maxf(front, point.z)
	var height := 0.0
	for point: Vector3 in points:
		if point.z > front - 0.3:
			height = maxf(height, point.y)
	return Vector3(0.0, height, front)


## Os cabos (cada um uma lista de pontos, para o HarborView.rope_mesh): os ovéns de cada mastro até a borda
## dos dois lados, o estai do mastro de proa ao bico de proa, os estais de cada mastro ao de vante e o
## brandal do último à popa.
static func spans(tops: Array[Vector3], points: PackedVector3Array) -> Array[PackedVector3Array]:
	var result: Array[PackedVector3Array] = []
	if tops.is_empty():
		return result
	for top: Vector3 in tops:
		var from := top - Vector3(0.0, SHROUD_DROP, 0.0)
		for side: float in [-1.0, 1.0]:
			for k: int in SHROUDS:
				var z := top.z - SHROUD_SPREAD * k
				var rail := rail_at(points, z)
				result.append(PackedVector3Array([from, Vector3(side * rail.x, rail.y, z)]))
	result.append(HarborView.rope_span(tops[0], bow_point(points), STAY_SAG))
	for i: int in range(1, tops.size()):
		var ahead := tops[i - 1]
		var foot := Vector3(0.0, DECK_Y + (ahead.y - DECK_Y) * STAY_FOOT, ahead.z)
		result.append(HarborView.rope_span(tops[i], foot, STAY_SAG))
	var back := -INF
	for point: Vector3 in points:
		back = maxf(back, -point.z)
	var stern_z := -back + 0.2
	result.append(HarborView.rope_span(tops[-1], Vector3(0.0, rail_at(points, stern_z).y, stern_z), STAY_SAG))
	return result


## O mastro grande: o mais alto.
static func main_mast(tops: Array[Vector3]) -> Vector3:
	var best := Vector3.ZERO
	for top: Vector3 in tops:
		if top.y > best.y:
			best = top
	return best


## Onde vai a peça "index" da carga no convés (o pé dela), alternando os lados à frente do mastro grande.
static func deck_slot(main: Vector3, index: int) -> Vector3:
	var side := -1.0 if index % 2 == 0 else 1.0
	return Vector3(side * DECK_CARGO_X, DECK_Y, main.z + DECK_CARGO_AHEAD + DECK_CARGO_STEP * float(index >> 1))


## O cordame pronto, filho do modelo (no espaço dele): "scale_factor" é quanto o ShipView estica o modelo, para
## o cabo sair com ROPE_RADIUS_M no mundo. Sem bandeira no modelo, null.
static func rigging(model: Node3D, scale_factor: float, material: Material) -> MeshInstance3D:
	var tops := mast_tops(model)
	if tops.is_empty():
		return null
	var node := MeshInstance3D.new()
	node.name = "Rigging"
	node.mesh = HarborView.rope_mesh(spans(tops, hull_points(model)), material, ROPE_RADIUS_M / scale_factor)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node
