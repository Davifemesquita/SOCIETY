class_name VertexShapes
extends RefCounted
## Formas simples com cor por vértice para as malhas geradas no código (o trem da Fase 71, os bichos e as peças do
## museu da Fase 74): caixa (alinhada ou com um referencial qualquer), cilindro com tampas e triângulo, todos virados para
## fora (sentido horário visto de fora, como o Godot espera). As normais saem de SurfaceTool.generate_normals.


## Caixa centrada em center com meias medidas half (sem rotação).
static func box(tool: SurfaceTool, center: Vector3, half: Vector3, color: Color) -> void:
	oriented_box(tool, Transform3D(Basis.IDENTITY, center), half, color)


## Caixa de meias medidas half no referencial place (o meio da caixa na origem dele).
static func oriented_box(tool: SurfaceTool, place: Transform3D, half: Vector3, color: Color) -> void:
	var c: Array[Vector3] = []
	for k: int in 8:
		c.append(place * Vector3(half.x * (1 if k & 1 else -1), half.y * (1 if k & 2 else -1), half.z * (1 if k & 4 else -1)))
	for face: Array in [[2, 3, 7, 6], [0, 4, 5, 1], [1, 5, 7, 3], [0, 2, 6, 4], [4, 6, 7, 5], [0, 1, 3, 2]]:
		quad(tool, c[face[0]], c[face[1]], c[face[2]], c[face[3]], color)


## Caixa entre os pontos a e b (o comprimento), com a seção de meias medidas width e height: pernas, pescoços, varetas.
static func strut(tool: SurfaceTool, a: Vector3, b: Vector3, width: float, height: float, color: Color) -> void:
	var along := b - a
	if along.length_squared() < 1e-8:
		return
	var z := along.normalized()
	var helper := Vector3.UP if absf(z.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	var x := helper.cross(z).normalized()
	var y := z.cross(x).normalized()
	oriented_box(tool, Transform3D(Basis(x, y, z), (a + b) * 0.5), Vector3(width, height, along.length() * 0.5), color)


## Cilindro de a até b com raio radius, com as tampas.
static func cylinder(tool: SurfaceTool, a: Vector3, b: Vector3, radius: float, color: Color, sides: int = 10) -> void:
	var axis := (b - a).normalized()
	var helper := Vector3.UP if absf(axis.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var u := axis.cross(helper).normalized() * radius
	var v := axis.cross(u).normalized() * radius
	for i: int in sides:
		var p := u * cos(TAU * i / sides) + v * sin(TAU * i / sides)
		var q := u * cos(TAU * (i + 1) / sides) + v * sin(TAU * (i + 1) / sides)
		quad(tool, a + p, b + p, b + q, a + q, color)
		tri(tool, a, a + p, a + q, color)
		tri(tool, b, b + q, b + p, color)


static func quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
	tri(tool, a, b, c, color)
	tri(tool, a, c, d, color)


static func tri(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	for point: Vector3 in [a, b, c]:
		tool.set_color(color)
		tool.add_vertex(point)
