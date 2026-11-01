class_name SternLantern
extends RefCounted
## Fase 225: a lanterna de popa. Em cada navio de modelo (o do jogador, o do comerciante e os das rivais), no meio da ré, no alto
## do casco junto da popa (`stern_point`, pelos triângulos do casco como o bico de proa da Fase 26): o pau de madeira, o braço de
## ferro para trás e a lanterna de quatro vidros com o chapéu (`frame_mesh`), o vidro no material dos lampiões da rua
## (`glass_mesh`, `shaders/night_glow.gdshader`: apagado de dia, aceso à noite). Filho do modelo (no espaço dele), com a escala
## desfeita: as medidas são em metros. Nada no save.

const POLE_M := 1.6
const ARM_M := 0.45
## A lanterna: a meia largura e a meia altura do vidro.
const GLASS_HALF := Vector3(0.2, 0.3, 0.2)
const WOOD := Color(0.36, 0.27, 0.18)
const IRON := Color(0.14, 0.14, 0.15)


## A popa no espaço do modelo: a ré (z mínimo, a proa fica em +z), no meio da largura do casco junto dela e na altura do alto do
## casco ali (o modelo do kit não tem o meio em x = 0).
static func stern_point(points: PackedVector3Array) -> Vector3:
	var back := INF
	for point: Vector3 in points:
		back = minf(back, point.z)
	var height := 0.0
	var low_x := INF
	var high_x := -INF
	for point: Vector3 in points:
		if point.z < back + 0.3:
			height = maxf(height, point.y)
			low_x = minf(low_x, point.x)
			high_x = maxf(high_x, point.x)
	return Vector3((low_x + high_x) * 0.5, height, back)


## A lanterna pronta, filha do modelo: no meio da ré, um pouco para dentro da borda; "points", os triângulos do casco já lidos
## pelo ShipView (os mesmos do cordame). Sem casco, null.
static func node(scale_factor: float, points: PackedVector3Array) -> Node3D:
	if points.is_empty():
		return null
	var stern := stern_point(points)
	var root := Node3D.new()
	root.name = "SternLantern"
	root.position = stern + Vector3(0.0, 0.0, 0.15 / scale_factor)
	root.scale = Vector3.ONE / scale_factor
	var frame := MeshInstance3D.new()
	frame.name = "Frame"
	frame.mesh = _frame_shared()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.7
	frame.material_override = material
	root.add_child(frame)
	var glass := MeshInstance3D.new()
	glass.name = "Glass"
	glass.mesh = _glass_shared()
	glass.material_override = LampView._glow_material()
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(glass)
	return root


## O meio do vidro, com o pé do pau na origem (a popa) e a ré em −z.
static func glass_center() -> Vector3:
	return Vector3(0.0, POLE_M - GLASS_HALF.y - 0.12, -ARM_M)


## O pau, o braço e a armação da lanterna: os quatro montantes, a base, o chapéu de quatro águas e a argola.
static func frame_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := Vector3(0.0, POLE_M + 0.1, 0.0)
	VertexShapes.strut(tool, Vector3.ZERO, top, 0.05, 0.05, WOOD)
	VertexShapes.strut(tool, Vector3(0.0, POLE_M, 0.0), Vector3(0.0, POLE_M, -ARM_M), 0.025, 0.025, IRON)
	var center := glass_center()
	var half := GLASS_HALF
	VertexShapes.strut(tool, Vector3(0.0, POLE_M, -ARM_M), center + Vector3(0.0, half.y + 0.1, 0.0), 0.01, 0.01, IRON)
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var x := corner.x * (half.x + 0.012)
		var z := corner.y * (half.z + 0.012)
		VertexShapes.strut(tool, center + Vector3(x, -half.y, z), center + Vector3(x, half.y, z), 0.015, 0.015, IRON)
	VertexShapes.box(tool, center - Vector3(0.0, half.y + 0.02, 0.0), Vector3(half.x + 0.03, 0.02, half.z + 0.03), IRON)
	var eave := center.y + half.y
	var peak := center + Vector3(0.0, half.y + 0.12, 0.0)
	var corners: Array[Vector3] = []
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		corners.append(Vector3(center.x + corner.x * (half.x + 0.04), eave, center.z + corner.y * (half.z + 0.04)))
	for k: int in 4:
		VertexShapes.tri(tool, corners[k], corners[(k + 1) % 4], peak, IRON)
		VertexShapes.tri(tool, corners[k], peak, corners[(k + 1) % 4], IRON)
	tool.generate_normals()
	return tool.commit()


## O vidro aceso: a caixa no meio da armação, marcada como vidro (alfa 0) para o night_glow.
static func glass_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.box(tool, glass_center(), GLASS_HALF, Color(LampView.LAMP_COLOR, 0.0))
	tool.generate_normals()
	return tool.commit()


## As malhas feitas uma vez e divididas entre todos os navios.
static var _frame: ArrayMesh = null
static var _glass: ArrayMesh = null


static func _frame_shared() -> ArrayMesh:
	if _frame == null:
		_frame = frame_mesh()
	return _frame


static func _glass_shared() -> ArrayMesh:
	if _glass == null:
		_glass = glass_mesh()
	return _glass
