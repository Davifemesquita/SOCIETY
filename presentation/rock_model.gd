class_name RockModel
extends RefCounted
## Fase 56: rocha gerada no código para os rochedos do mar e as faces das falésias (as pedras do Kenney são de 1,6 m e
## lisas). Uma icosfera subdividida, com o raio mexido por ruído e cortada por alguns planos (as faces chatas de rocha
## partida), em faces de normal chapada. Medida normalizada: x e z de −1 a 1, y de BOTTOM a 1 (a parte abaixo de zero
## fica enterrada no chão ou na água). VARIANTS formas, cada uma sempre igual (semente fixa).

const VARIANTS := 4
const BOTTOM := -0.4
## Quantas vezes a icosfera é subdividida (2 = 320 triângulos).
const SUBDIVISIONS := 2
## Planos de corte por rocha e a distância do centro onde cortam (fração do raio).
const CUTS := 6
const CUT_RANGE := Vector2(0.62, 0.86)
## O corte do topo, quase horizontal, nesta faixa do raio.
const TOP_CUT := Vector2(0.5, 0.7)

static var _cache: Dictionary[int, ArrayMesh] = {}


## A malha da variante (feita uma vez).
static func mesh(variant: int) -> ArrayMesh:
	var key := posmod(variant, VARIANTS)
	if not _cache.has(key):
		_cache[key] = _build(key)
	return _cache[key]


static func _build(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([variant, &"rocha"])
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 1.0
	noise.fractal_octaves = 3
	var sphere := _icosphere()
	var points: PackedVector3Array = sphere[0]
	var triangles: PackedInt32Array = sphere[1]
	var cuts: Array[Vector4] = []
	for c: int in CUTS:
		var normal := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.6, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
		cuts.append(Vector4(normal.x, normal.y, normal.z, rng.randf_range(CUT_RANGE.x, CUT_RANGE.y)))
	# o topo sempre cortado quase na horizontal: bloco de rocha, não ponta
	var top := Vector3(rng.randf_range(-0.3, 0.3), 1.0, rng.randf_range(-0.3, 0.3)).normalized()
	cuts.append(Vector4(top.x, top.y, top.z, rng.randf_range(TOP_CUT.x, TOP_CUT.y)))
	# um pouco alongada de lado (rocha em pé, não bola)
	var stretch := Vector3(rng.randf_range(0.8, 1.2), rng.randf_range(0.95, 1.15), rng.randf_range(0.8, 1.2))
	for i: int in points.size():
		var p := points[i]
		var radius := 1.0 + 0.28 * noise.get_noise_3dv(p * 1.6) + 0.1 * noise.get_noise_3dv(p * 4.3 + Vector3(7.0, 0.0, 3.0))
		p *= radius
		for cut: Vector4 in cuts:
			var n := Vector3(cut.x, cut.y, cut.z)
			var over := p.dot(n) - cut.w
			if over > 0.0:
				p -= n * over
		points[i] = p * stretch
	# normaliza: x e z até 1, y de BOTTOM a 1
	var low := Vector3.INF
	var high := -Vector3.INF
	for p: Vector3 in points:
		low = low.min(p)
		high = high.max(p)
	var half := maxf(maxf(-low.x, high.x), maxf(-low.z, high.z))
	for i: int in points.size():
		var p := points[i]
		points[i] = Vector3(p.x / half, BOTTOM + (p.y - low.y) / (high.y - low.y) * (1.0 - BOTTOM), p.z / half)
	return _faceted(points, triangles)


## Malha de faces chapadas: cada triângulo com a própria normal, de frente para fora (o Godot desenha a frente no
## sentido horário).
static func _faceted(points: PackedVector3Array, triangles: PackedInt32Array) -> ArrayMesh:
	var center := Vector3.ZERO
	for p: Vector3 in points:
		center += p
	center /= points.size()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	for t: int in range(0, triangles.size(), 3):
		var a := points[triangles[t]]
		var b := points[triangles[t + 1]]
		var c := points[triangles[t + 2]]
		var cross := (b - a).cross(c - a)
		if cross.length_squared() < 1e-12:
			continue
		if cross.dot((a + b + c) / 3.0 - center) > 0.0:
			var swap := b
			b = c
			c = swap
			cross = -cross
		var normal := -cross.normalized()
		vertices.append_array(PackedVector3Array([a, b, c]))
		normals.append_array(PackedVector3Array([normal, normal, normal]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result


## Icosfera de raio 1, subdividida SUBDIVISIONS vezes (os pontos do meio de cada aresta, sem repetir): [pontos,
## triângulos].
static func _icosphere() -> Array:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var points := PackedVector3Array([Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
			Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
			Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)])
	for i: int in points.size():
		points[i] = points[i].normalized()
	var faces := PackedInt32Array([0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11, 1, 5, 9, 5, 11, 4, 11, 10, 2, 10, 7, 6,
			7, 1, 8, 3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9, 4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1])
	for level: int in SUBDIVISIONS:
		var middles: Dictionary[Vector2i, int] = {}
		var next := PackedInt32Array()
		for f: int in range(0, faces.size(), 3):
			var corners := [faces[f], faces[f + 1], faces[f + 2]]
			var mids: Array[int] = []
			for e: int in 3:
				var a: int = corners[e]
				var b: int = corners[(e + 1) % 3]
				var key := Vector2i(mini(a, b), maxi(a, b))
				if not middles.has(key):
					middles[key] = points.size()
					points.append(((points[a] + points[b]) * 0.5).normalized())
				mids.append(middles[key])
			next.append_array(PackedInt32Array([corners[0], mids[0], mids[2], corners[1], mids[1], mids[0],
					corners[2], mids[2], mids[1], mids[0], mids[1], mids[2]]))
		faces = next
	return [points, faces]
