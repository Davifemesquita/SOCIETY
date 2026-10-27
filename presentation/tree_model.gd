class_name TreeModel
extends RefCounted
## Árvores europeias de 1840 geradas no código (Fase 22), no lugar das do Kenney Nature Kit: carvalho de
## copa larga e irregular sobre galhos grossos, faia de copa oval e casca lisa e cinzenta, e pinheiro-
## silvestre de tronco alto, avermelhado em cima, com a copa só no alto. Tronco e galhos são cilindros
## afinando; a copa são massas de folhagem (icosaedros subdivididos, esticados e amassados pelo sorteio da
## variante), mais escuras embaixo. Tudo numa superfície só, com a cor no vértice, no material da folhagem
## (balança ao vento). Em metros: a TreeView não reescala. Dois níveis de detalhe: o perto (`DETAIL_NEAR`)
## e o de longe (`DETAIL_FAR`, a copa sem subdividir e o tronco de quatro faces, sem galhos).

## Fase 58: o coqueiro das ilhas tropicais, no lugar das palmeiras do Kenney: tronco curvo em gomos com anéis, a
## coroa de folhas compridas que sobem e caem, com folíolos em serra e dobradas em V, e um cacho de cocos.

enum Species { OAK, BEECH, SCOTS_PINE, COCONUT_PALM }

const DETAIL_NEAR := 0
const DETAIL_FAR := 1
## Variantes de cada espécie (sorteio diferente da copa e dos galhos).
const VARIANTS := 2
## Fase 53: folhas mais claras e saturadas (a mata do Anno é verde viva, não um bloco escuro)
const OAK_LEAF := Color(0.32, 0.5, 0.17)
const BEECH_LEAF := Color(0.44, 0.6, 0.2)
const PINE_NEEDLE := Color(0.2, 0.38, 0.18)
const OAK_BARK := Color(0.3, 0.25, 0.19)
const BEECH_BARK := Color(0.46, 0.45, 0.41)
const PINE_BARK := Color(0.33, 0.22, 0.15)
const PINE_UPPER_BARK := Color(0.62, 0.36, 0.2)
const PALM_LEAF := Color(0.3, 0.52, 0.15)
## As folhas de baixo (as mais velhas) puxam para esta cor.
const PALM_OLD_LEAF := Color(0.5, 0.52, 0.2)
const PALM_BARK := Color(0.5, 0.42, 0.32)
const PALM_RING := Color(0.42, 0.35, 0.27)
const COCONUT := Color(0.36, 0.34, 0.12)
## Coqueiro: altura do tronco (antes do sorteio), gomos do tronco, folhas da coroa e o comprimento delas, em metros.
const PALM_HEIGHT_M := 8.0
const PALM_SEGMENTS := 7
const PALM_FRONDS := 10
const PALM_FROND_M := Vector2(3.4, 4.2)
## A folhagem embaixo de cada massa fica nesta fração da cor; em cima, um pouco mais clara.
const CROWN_SHADE := 0.74
const CROWN_LIGHT := 1.12
## Quanto cada vértice da massa sai ou entra (fração do raio), para ela não ser uma bola.
const CROWN_LUMP := 0.16
## Balanço (como o das árvores do Kenney, m por m de altura).
const SWAY := 0.035
## Copa fofa (Fase 41): a normal de cada vértice da folhagem puxa para a da copa inteira (a esfera em volta do meio
## dela), e a copa vira um volume de luz macia, não um monte de bolas facetadas; tufos pequenos (o icosaedro sem
## subdividir) quebram a silhueta.
const CROWN_ROUND := 0.65
const PUFF_RADIUS := Vector2(0.55, 0.9)

static var _cache: Dictionary[String, ArrayMesh] = {}
static var _sphere_points: Array[PackedVector3Array] = []
static var _sphere_faces: Array[PackedInt32Array] = []


## A malha da espécie e variante no nível de detalhe dado, em cache.
static func mesh(species: Species, variant: int, detail: int = DETAIL_NEAR) -> ArrayMesh:
	var key := "%d/%d/%d" % [species, variant, detail]
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([species, variant, "árvore"])
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	match species:
		Species.OAK:
			_oak(tool, rng, detail)
		Species.BEECH:
			_beech(tool, rng, detail)
		Species.SCOTS_PINE:
			_pine(tool, rng, detail)
		Species.COCONUT_PALM:
			_palm(tool, rng, detail)
	var result := tool.commit()
	result.surface_set_material(0, _material(result))
	_cache[key] = result
	return result


## Carvalho: tronco curto e grosso, quatro galhos abertos e uma massa de folhagem na ponta de cada um, mais
## a do alto; copa mais larga que alta.
static func _oak(tool: SurfaceTool, rng: RandomNumberGenerator, detail: int) -> void:
	var lean := Vector3(rng.randf_range(-0.25, 0.25), 0.0, rng.randf_range(-0.25, 0.25))
	var crotch := Vector3(0.0, 3.0, 0.0) + lean
	_limb(tool, Vector3.ZERO, crotch, 0.34, 0.24, detail, OAK_BARK, OAK_BARK)
	var turn := rng.randf() * TAU
	var hull := crotch + Vector3(0.0, 2.4, 0.0)
	var tips: Array[Vector3] = []
	for i: int in 4:
		var angle := turn + i * TAU / 4.0 + rng.randf_range(-0.35, 0.35)
		var reach := rng.randf_range(1.5, 2.1)
		var tip := crotch + Vector3(cos(angle) * reach, rng.randf_range(1.3, 2.1), sin(angle) * reach)
		tips.append(tip)
		if detail == DETAIL_NEAR:
			_limb(tool, crotch - Vector3(0.0, 0.3, 0.0), tip, 0.16, 0.07, detail, OAK_BARK, OAK_BARK)
		var radius := rng.randf_range(1.4, 1.8)
		_crown(tool, rng, tip + Vector3(0.0, 0.4, 0.0), Vector3(radius, radius * 0.8, radius), OAK_LEAF, detail, hull)
	_crown(tool, rng, crotch + Vector3(0.0, 3.0, 0.0), Vector3(2.0, 1.7, 2.0), OAK_LEAF, detail, hull)
	# tufos entre as massas, para fora (só de perto)
	_puffs(tool, rng, tips, hull, OAK_LEAF, detail, 0.8)


## Faia: tronco liso e cinzento até o meio e a copa oval, mais alta que larga.
static func _beech(tool: SurfaceTool, rng: RandomNumberGenerator, detail: int) -> void:
	var lean := Vector3(rng.randf_range(-0.15, 0.15), 0.0, rng.randf_range(-0.15, 0.15))
	var top := Vector3(0.0, 4.6, 0.0) + lean
	_limb(tool, Vector3.ZERO, top, 0.26, 0.15, detail, BEECH_BARK, BEECH_BARK)
	var hull := top + Vector3(0.0, 1.6, 0.0)
	_crown(tool, rng, top + Vector3(0.0, 0.8, 0.0), Vector3(2.2, 2.0, 2.2), BEECH_LEAF, detail, hull)
	_crown(tool, rng, top + Vector3(0.0, 2.7, 0.0), Vector3(1.8, 1.7, 1.8), BEECH_LEAF, detail, hull)
	var turn := rng.randf() * TAU
	var sides: Array[Vector3] = []
	for i: int in 2:
		var angle := turn + i * PI + rng.randf_range(-0.4, 0.4)
		var side := top + Vector3(cos(angle) * 1.4, rng.randf_range(0.0, 1.2), sin(angle) * 1.4)
		sides.append(side)
		_crown(tool, rng, side, Vector3(1.5, 1.4, 1.5), BEECH_LEAF, detail, hull)
	sides.append(top + Vector3(0.0, 3.6, 0.0))
	_puffs(tool, rng, sides, hull, BEECH_LEAF, detail, 0.6)


## Pinheiro-silvestre: tronco alto e fino, marrom embaixo e avermelhado no alto, com a copa em massas
## achatadas só no último terço.
static func _pine(tool: SurfaceTool, rng: RandomNumberGenerator, detail: int) -> void:
	var bend := Vector3(rng.randf_range(-0.5, 0.5), 0.0, rng.randf_range(-0.5, 0.5))
	var middle := Vector3(0.0, 5.0, 0.0) + bend * 0.4
	var top := Vector3(0.0, 9.6, 0.0) + bend
	_limb(tool, Vector3.ZERO, middle, 0.27, 0.18, detail, PINE_BARK, PINE_UPPER_BARK.lerp(PINE_BARK, 0.5))
	_limb(tool, middle, top, 0.18, 0.07, detail, PINE_UPPER_BARK.lerp(PINE_BARK, 0.5), PINE_UPPER_BARK)
	var turn := rng.randf() * TAU
	var masses := 4
	var hull := top + Vector3(0.0, -0.5, 0.0)
	var spots: Array[Vector3] = []
	for i: int in masses:
		var angle := turn + i * TAU / masses + rng.randf_range(-0.5, 0.5)
		var out := rng.randf_range(0.6, 1.3) if i > 0 else 0.0
		var spot := top + Vector3(cos(angle) * out, rng.randf_range(-1.6, 0.4) if i > 0 else 0.5, sin(angle) * out)
		spots.append(spot)
		var radius := rng.randf_range(1.3, 1.8)
		_crown(tool, rng, spot, Vector3(radius, radius * 0.5, radius), PINE_NEEDLE, detail, hull)
	_puffs(tool, rng, spots, hull, PINE_NEEDLE, detail, 0.45)


## Coqueiro: tronco curvo para um lado, em gomos com um anel escuro em cada junta e o pé alargado; no alto, a coroa de
## folhas em volta (as de cima mais em pé, as de baixo caídas e mais amarelas) e um cacho de cocos sob ela. De longe,
## menos gomos e folhas, sem cocos.
static func _palm(tool: SurfaceTool, rng: RandomNumberGenerator, detail: int) -> void:
	var height := PALM_HEIGHT_M * rng.randf_range(0.9, 1.15)
	var turn := rng.randf() * TAU
	var lean := Vector3(cos(turn), 0.0, sin(turn)) * rng.randf_range(0.8, 2.0)
	var segments := PALM_SEGMENTS if detail == DETAIL_NEAR else 3
	var last := Vector3.ZERO
	for i: int in segments:
		var t0 := float(i) / segments
		var t1 := float(i + 1) / segments
		var from := _palm_spine(height, lean, t0)
		var to := _palm_spine(height, lean, t1)
		var r_from := lerpf(0.24, 0.14, t0) + (0.1 if i == 0 else 0.0)
		var r_to := lerpf(0.24, 0.14, t1)
		_limb(tool, from, to, r_from, r_to, detail, PALM_RING if detail == DETAIL_NEAR else PALM_BARK, PALM_BARK)
		last = to
	var top := last
	var fronds := PALM_FRONDS if detail == DETAIL_NEAR else 6
	var spin := rng.randf() * TAU
	for f: int in fronds:
		var angle := spin + f * TAU / fronds + rng.randf_range(-0.25, 0.25)
		# metade de cima mais em pé, metade de baixo caída
		var upper := f % 2 == 0
		var rise := rng.randf_range(0.5, 0.9) if upper else rng.randf_range(0.0, 0.3)
		var droop := rng.randf_range(1.6, 2.4) if upper else rng.randf_range(2.4, 3.2)
		var color := PALM_LEAF if upper else PALM_LEAF.lerp(PALM_OLD_LEAF, rng.randf_range(0.2, 0.5))
		_frond(tool, top, angle, rng.randf_range(PALM_FROND_M.x, PALM_FROND_M.y), rise, droop, color, detail)
	if detail == DETAIL_NEAR:
		for c: int in 4:
			var angle := spin + c * TAU / 4.0 + 0.4
			var nut := top + Vector3(cos(angle) * 0.24, -0.35 - (c % 2) * 0.15, sin(angle) * 0.24)
			_crown(tool, rng, nut, Vector3(0.16, 0.18, 0.16), COCONUT, detail, Vector3.INF, 0)


## Ponto do tronco do coqueiro na fração t da altura: curva para o lado de lean, mais no alto.
static func _palm_spine(height: float, lean: Vector3, t: float) -> Vector3:
	return Vector3(0.0, height * t, 0.0) + lean * t * t


## Uma folha do coqueiro: a nervura sai do alto, sobe rise e cai droop até a ponta (length metros para fora), e a lâmina
## em volta dela tem os folíolos em serra (largura alternando), dobrada em V para baixo e afinando até a ponta.
static func _frond(tool: SurfaceTool, top: Vector3, angle: float, length: float, rise: float, droop: float, color: Color,
		detail: int) -> void:
	var out := Vector3(cos(angle), 0.0, sin(angle))
	var side := Vector3(-out.z, 0.0, out.x)
	var steps := 10 if detail == DETAIL_NEAR else 4
	var spine: Array[Vector3] = []
	for s: int in steps + 1:
		var t := float(s) / steps
		spine.append(top + out * length * t + Vector3.UP * (rise * 4.0 * t * (1.0 - t) - droop * t * t))
	for s: int in steps:
		var t0 := float(s) / steps
		var t1 := float(s + 1) / steps
		var w0 := _frond_width(t0, s, detail)
		var w1 := _frond_width(t1, s + 1, detail)
		var along := (spine[s + 1] - spine[s]).normalized()
		var normal := side.cross(along).normalized()
		if normal.y < 0.0:
			normal = -normal
		var shade := lerpf(0.85, 1.05, t0)
		var tint := Color(color.r * shade, color.g * shade, color.b * shade)
		for edge: float in [-1.0, 1.0]:
			var fold := Vector3.DOWN * 0.18
			var a := spine[s]
			var b := spine[s + 1]
			var c := spine[s + 1] + side * edge * w1 + fold * w1
			var d := spine[s] + side * edge * w0 + fold * w0
			var tilted := (normal + side * edge * 0.35).normalized()
			for point: Vector3 in [a, b, c, a, c, d]:
				tool.set_normal(tilted)
				tool.set_color(tint)
				tool.add_vertex(point)


## Meia largura da lâmina na fração t da folha: cresce, afina até a ponta e, de perto, alterna (os folíolos em serra).
static func _frond_width(t: float, step: int, detail: int) -> float:
	var width := 0.55 * sin(PI * sqrt(t))
	if detail == DETAIL_NEAR and step % 2 == 1:
		width *= 0.4
	return maxf(width, 0.0)


## Tronco ou galho: cilindro afinando de from (raio r_from) a to, com a cor indo de uma à outra.
static func _limb(tool: SurfaceTool, from: Vector3, to: Vector3, r_from: float, r_to: float, detail: int, color_from: Color, color_to: Color) -> void:
	var sides := 6 if detail == DETAIL_NEAR else 4
	var axis := (to - from).normalized()
	var side := axis.cross(Vector3.FORWARD if absf(axis.y) > 0.9 else Vector3.UP).normalized()
	var other := axis.cross(side)
	for i: int in sides:
		var a := TAU * i / sides
		var b := TAU * (i + 1) / sides
		var na := side * cos(a) + other * sin(a)
		var nb := side * cos(b) + other * sin(b)
		var quad: Array[Array] = [
			[from + na * r_from, na, color_from], [to + nb * r_to, nb, color_to], [from + nb * r_from, nb, color_from],
			[from + na * r_from, na, color_from], [to + na * r_to, na, color_to], [to + nb * r_to, nb, color_to],
		]
		for corner: Array in quad:
			var normal: Vector3 = corner[1]
			var color: Color = corner[2]
			var point: Vector3 = corner[0]
			tool.set_normal(normal)
			tool.set_color(color)
			tool.add_vertex(point)


## Massa de folhagem: a esfera do nível de detalhe esticada até radii, com cada vértice amassado pelo
## sorteio, mais escura embaixo e a normal de bola (luz macia).
static func _crown(tool: SurfaceTool, rng: RandomNumberGenerator, center: Vector3, radii: Vector3, leaf: Color, detail: int,
		hull := Vector3.INF, level := -1) -> void:
	if level < 0:
		level = 1 if detail == DETAIL_NEAR else 0
	var points := _sphere(level)
	var faces := _sphere_faces[level]
	# a massa sorteia no gerador dela: os dois níveis de detalhe gastam o da árvore igual
	var lumps := RandomNumberGenerator.new()
	lumps.seed = rng.randi()
	var tint := lumps.randf_range(0.92, 1.08)
	var placed := PackedVector3Array()
	placed.resize(points.size())
	for i: int in points.size():
		placed[i] = points[i] * radii * (1.0 + lumps.randf_range(-CROWN_LUMP, CROWN_LUMP))
	for face: int in faces.size():
		var point := placed[faces[face]]
		var unit := points[faces[face]]
		var shade := lerpf(CROWN_SHADE, CROWN_LIGHT, unit.y * 0.5 + 0.5) * tint
		var normal := (unit / radii).normalized()
		if hull != Vector3.INF:
			# a normal da copa inteira: luz macia de volume
			var away := center + point - hull
			if away.length_squared() > 1e-4:
				normal = normal.lerp(away.normalized(), CROWN_ROUND).normalized()
		tool.set_normal(normal)
		tool.set_color(Color(leaf.r * shade, leaf.g * shade, leaf.b * shade))
		tool.add_vertex(center + point)


## Tufos pequenos (o icosaedro sem subdividir) entre os pontos dados, empurrados para fora do meio da copa: quebram a
## silhueta de bolas. Só no nível de perto.
static func _puffs(tool: SurfaceTool, rng: RandomNumberGenerator, anchors: Array[Vector3], hull: Vector3, leaf: Color,
		detail: int, out: float) -> void:
	if detail != DETAIL_NEAR:
		return
	var count := anchors.size()
	for i: int in count:
		var between := anchors[i].lerp(anchors[(i + 1) % count], 0.5)
		var away := between - hull
		away.y *= 0.5
		var spot := between + away.normalized() * out * rng.randf_range(0.8, 1.2)
		var radius := rng.randf_range(PUFF_RADIUS.x, PUFF_RADIUS.y)
		_crown(tool, rng, spot, Vector3(radius, radius * 0.85, radius), leaf.lightened(0.06), detail, hull, 0)


## Pontos da esfera unitária (icosaedro subdividido level vezes) e as faces em índices.
static func _sphere(level: int) -> PackedVector3Array:
	if _sphere_points.is_empty():
		var t := (1.0 + sqrt(5.0)) / 2.0
		var base := PackedVector3Array()
		for p: Vector3 in [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
				Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
				Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]:
			base.append(p.normalized())
		var faces := PackedInt32Array([0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11, 1, 5, 9, 5, 11, 4,
				11, 10, 2, 10, 7, 6, 7, 1, 8, 3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9, 4, 9, 5, 2, 4, 11,
				6, 2, 10, 8, 6, 7, 9, 8, 1])
		_sphere_points.append(base)
		_sphere_faces.append(faces)
		# uma subdivisão: cada triângulo vira quatro, com os pontos do meio das arestas na esfera
		var points := base.duplicate()
		var middle := {}
		var finer := PackedInt32Array()
		for f: int in range(0, faces.size(), 3):
			var corners := [faces[f], faces[f + 1], faces[f + 2]]
			var mids: Array[int] = []
			for e: int in 3:
				var a: int = corners[e]
				var b: int = corners[(e + 1) % 3]
				var edge := Vector2i(mini(a, b), maxi(a, b))
				if not middle.has(edge):
					middle[edge] = points.size()
					points.append(((points[a] + points[b]) * 0.5).normalized())
				mids.append(middle[edge])
			finer.append_array([corners[0], mids[0], mids[2], corners[1], mids[1], mids[0],
					corners[2], mids[2], mids[1], mids[0], mids[1], mids[2]])
		_sphere_points.append(points)
		_sphere_faces.append(finer)
	return _sphere_points[level]


static func _material(result: ArrayMesh) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/foliage.gdshader") as Shader
	material.set_shader_parameter(&"albedo", Color.WHITE)
	material.set_shader_parameter(&"use_vertex_color", true)
	material.set_shader_parameter(&"model_height", maxf(result.get_aabb().end.y, 0.1))
	material.set_shader_parameter(&"sway", SWAY)
	return material
