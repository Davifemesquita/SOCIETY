class_name CarriedGoods
extends RefCounted
## O que o pedestre leva na mão (Fase 15): cesto de vime com pão e legumes e saco de juta, gerados aqui com a
## cor no vértice, com a base em y = 0 e o meio em x = z = 0 (o shaders/carried_vat.gdshader põe na mão).

const BASKET_RADIUS_M := 0.2
const BASKET_HEIGHT_M := 0.16
const WICKER := Color(0.62, 0.46, 0.26)
const SACK_COLOR := Color(0.7, 0.6, 0.42)
const BREAD := Color(0.78, 0.55, 0.28)
const GREENS := Color(0.35, 0.55, 0.22)
const SIDES := 10


## Cesto: tronco de cone aberto (fundo mais estreito), a alça em arco por cima e o que vai dentro.
static func basket_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_color(WICKER)
	var bottom := BASKET_RADIUS_M * 0.72
	for i: int in SIDES:
		var a := TAU * i / SIDES
		var b := TAU * (i + 1) / SIDES
		var low_a := Vector3(cos(a) * bottom, 0.0, sin(a) * bottom)
		var low_b := Vector3(cos(b) * bottom, 0.0, sin(b) * bottom)
		var high_a := Vector3(cos(a) * BASKET_RADIUS_M, BASKET_HEIGHT_M, sin(a) * BASKET_RADIUS_M)
		var high_b := Vector3(cos(b) * BASKET_RADIUS_M, BASKET_HEIGHT_M, sin(b) * BASKET_RADIUS_M)
		for vertex: Vector3 in [low_a, high_a, high_b, low_a, high_b, low_b, Vector3.ZERO, low_a, low_b]:
			tool.add_vertex(vertex)
	# alça: arco de caixas finas de um lado ao outro (em x)
	var arc := 6
	for i: int in arc:
		var a := PI * i / arc
		var b := PI * (i + 1) / arc
		var p := Vector3(cos(a) * BASKET_RADIUS_M, BASKET_HEIGHT_M + sin(a) * BASKET_RADIUS_M * 0.9, 0.0)
		var q := Vector3(cos(b) * BASKET_RADIUS_M, BASKET_HEIGHT_M + sin(b) * BASKET_RADIUS_M * 0.9, 0.0)
		_strip(tool, p, q, 0.025)
	# dentro: um pão e um maço de verdura saindo pela boca
	_lump(tool, Vector3(-0.06, BASKET_HEIGHT_M, 0.02), Vector3(0.11, 0.06, 0.07), BREAD)
	_lump(tool, Vector3(0.08, BASKET_HEIGHT_M, -0.03), Vector3(0.07, 0.08, 0.07), GREENS)
	tool.generate_normals()
	return tool.commit()


## Saco de juta cheio, amarrado em cima.
static func sack_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_lump(tool, Vector3(0.0, 0.17, 0.0), Vector3(0.2, 0.17, 0.15), SACK_COLOR)
	_lump(tool, Vector3(0.0, 0.38, 0.0), Vector3(0.05, 0.06, 0.05), SACK_COLOR.darkened(0.15))
	tool.generate_normals()
	return tool.commit()


## Volume de oito faces em volta de center, com os semieixos dados.
static func _lump(tool: SurfaceTool, center: Vector3, half: Vector3, color: Color) -> void:
	tool.set_color(color)
	var points := [Vector3(half.x, 0, 0), Vector3(0, 0, half.z), Vector3(-half.x, 0, 0), Vector3(0, 0, -half.z)]
	for i: int in 4:
		var a: Vector3 = points[i]
		var b: Vector3 = points[(i + 1) % 4]
		for cap: Vector3 in [Vector3(0, half.y, 0), Vector3(0, -half.y, 0)]:
			var triangle := PackedVector3Array([a, b, cap] if cap.y > 0.0 else [b, a, cap])
			for vertex: Vector3 in triangle:
				tool.add_vertex(center + vertex)


## Fita de largura width de p a q, de pé no plano xy (vista dos dois lados pela ordem dupla).
static func _strip(tool: SurfaceTool, p: Vector3, q: Vector3, width: float) -> void:
	var out := Vector3(0.0, 0.0, width * 0.5)
	for vertex: Vector3 in [p - out, q - out, q + out, p - out, q + out, p + out,
			p - out, q + out, q - out, p - out, p + out, q + out]:
		tool.add_vertex(vertex)
