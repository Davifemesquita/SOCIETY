class_name ExhibitModels
extends RefCounted
## Os bichos do zoológico e as peças do museu (Fase 74), gerados no código com cor por vértice (sem asset): cada peça
## de coleção (ExhibitDef) tem a sua malha, feita uma vez e guardada. Frente em -Z, origem no chão (bicho) ou no tampo
## do pedestal (peça). Peça sem forma própria vira um caixote.

## Fase 75: os bichos que andam no cercado (as araras ficam no poleiro) e para onde cada um olha na malha (o giro com que
## foi feito; a manada de zebras, para a frente).
const FACING: Dictionary[StringName, float] = {&"elephant": 0.4, &"giraffe": -0.5, &"lion": 0.7, &"tiger": 0.7,
		&"zebras": 0.0}

static var _meshes: Dictionary[StringName, Mesh] = {}
static var _footprints: Dictionary[StringName, Rect2] = {}


static func mesh(exhibit_id: StringName) -> Mesh:
	if _meshes.has(exhibit_id):
		return _meshes[exhibit_id]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	match exhibit_id:
		&"elephant":
			_elephant(tool)
		&"giraffe":
			_giraffe(tool)
		&"lion":
			_cat(tool, Color(0.78, 0.6, 0.35), true, false)
		&"tiger":
			_cat(tool, Color(0.86, 0.46, 0.16), false, true)
		&"zebras":
			_zebra(tool, Vector3(-0.5, 0.0, 0.3), 0.2)
			_zebra(tool, Vector3(0.55, 0.0, -0.4), -0.5)
		&"parrots":
			_parrots(tool)
		&"amphora":
			_amphora(tool)
		&"fossil":
			_ammonite(tool)
		&"mummy":
			_sarcophagus(tool)
		&"old_master":
			_painting(tool)
		&"ship_model":
			_ship(tool)
		&"telescope":
			_telescope(tool)
		_:
			VertexShapes.box(tool, Vector3(0.0, 0.3, 0.0), Vector3(0.3, 0.3, 0.3), Color(0.5, 0.4, 0.3))
	tool.generate_normals()
	var made := tool.commit()
	_meshes[exhibit_id] = made
	return made


static func roams(exhibit_id: StringName) -> bool:
	return FACING.has(exhibit_id)


## Fase 75: a pegada do bicho no chão (x e z) com ele de frente para -Z: os vértices da malha desfeito o giro de FACING.
static func footprint(exhibit_id: StringName) -> Rect2:
	if _footprints.has(exhibit_id):
		return _footprints[exhibit_id]
	var yaw: float = FACING.get(exhibit_id, 0.0)
	var unturn := Basis(Vector3.UP, -yaw)
	var vertices: PackedVector3Array = (mesh(exhibit_id) as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var area := Rect2()
	for k: int in vertices.size():
		var point := unturn * vertices[k]
		var flat := Vector2(point.x, point.z)
		area = Rect2(flat, Vector2.ZERO) if k == 0 else area.expand(flat)
	_footprints[exhibit_id] = area
	return area


## Bicho de quatro patas: o corpo numa altura (pernas), as quatro pernas, o pescoço saindo da frente do corpo até a
## cabeça e o rabo. Devolve onde fica a cabeça (para orelhas, juba, tromba).
static func _quadruped(tool: SurfaceTool, at: Vector3, yaw: float, body: Vector3, leg_m: float, leg_w: float,
		neck_to: Vector3, head: Vector3, color: Color) -> Vector3:
	var turn := Basis(Vector3.UP, yaw)
	var center := at + turn * Vector3(0.0, leg_m + body.y, 0.0)
	VertexShapes.oriented_box(tool, Transform3D(turn, center), body, color)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var foot := at + turn * Vector3(sx * (body.x - leg_w), 0.0, sz * (body.z - leg_w * 1.5))
			VertexShapes.strut(tool, foot, foot + Vector3(0.0, leg_m + body.y * 0.5, 0.0), leg_w, leg_w, color.darkened(0.1))
	var neck_from := center + turn * Vector3(0.0, body.y * 0.5, -body.z * 0.85)
	var head_at := center + turn * neck_to
	VertexShapes.strut(tool, neck_from, head_at, body.x * 0.45, body.x * 0.45, color)
	VertexShapes.oriented_box(tool, Transform3D(turn, head_at), head, color)
	var tail_from := center + turn * Vector3(0.0, body.y * 0.6, body.z)
	VertexShapes.strut(tool, tail_from, tail_from + turn * Vector3(0.0, -body.y * 1.4, body.z * 0.35), 0.03, 0.03,
			color.darkened(0.25))
	return head_at


static func _elephant(tool: SurfaceTool) -> void:
	var grey := Color(0.52, 0.51, 0.52)
	var turn := Basis(Vector3.UP, FACING[&"elephant"])
	var head := _quadruped(tool, Vector3.ZERO, FACING[&"elephant"], Vector3(0.7, 0.65, 1.15), 1.0, 0.24,
			Vector3(0.0, 0.55, -1.35), Vector3(0.42, 0.45, 0.38), grey)
	# tromba descendo da frente da cabeça, orelhas grandes dos lados e as presas
	VertexShapes.strut(tool, head + turn * Vector3(0.0, -0.1, -0.35), head + turn * Vector3(0.0, -1.35, -0.6), 0.1, 0.1, grey)
	for side: float in [-1.0, 1.0]:
		VertexShapes.oriented_box(tool, Transform3D(turn, head + turn * Vector3(side * 0.48, 0.0, 0.1)),
				Vector3(0.06, 0.4, 0.32), grey.darkened(0.08))
		VertexShapes.strut(tool, head + turn * Vector3(side * 0.15, -0.3, -0.3), head + turn * Vector3(side * 0.2, -0.55, -0.75),
				0.04, 0.04, Color(0.92, 0.9, 0.82))


static func _giraffe(tool: SurfaceTool) -> void:
	var coat := Color(0.86, 0.68, 0.36)
	var turn := Basis(Vector3.UP, FACING[&"giraffe"])
	var head := _quadruped(tool, Vector3.ZERO, FACING[&"giraffe"], Vector3(0.38, 0.38, 0.75), 1.5, 0.08,
			Vector3(0.0, 2.1, -1.05), Vector3(0.12, 0.13, 0.3), coat)
	# manchas no corpo e os ossicones
	for spot: Vector3 in [Vector3(0.39, 0.1, -0.3), Vector3(-0.39, -0.1, 0.25), Vector3(0.39, -0.15, 0.4), Vector3(-0.39, 0.15, -0.35)]:
		VertexShapes.oriented_box(tool, Transform3D(turn, Vector3(0.0, 1.5 + 0.38, 0.0) + turn * spot), Vector3(0.02, 0.12, 0.14),
				Color(0.5, 0.3, 0.15))
	for side: float in [-1.0, 1.0]:
		VertexShapes.strut(tool, head + turn * Vector3(side * 0.06, 0.1, 0.1), head + turn * Vector3(side * 0.07, 0.3, 0.12),
				0.025, 0.025, Color(0.4, 0.28, 0.16))


## Leão (com juba) ou tigre (com listras).
static func _cat(tool: SurfaceTool, coat: Color, mane: bool, stripes: bool) -> void:
	var yaw: float = FACING[&"lion"]
	var turn := Basis(Vector3.UP, yaw)
	var head := _quadruped(tool, Vector3.ZERO, yaw, Vector3(0.28, 0.27, 0.72), 0.5, 0.08, Vector3(0.0, 0.35, -0.95),
			Vector3(0.2, 0.2, 0.22), coat)
	if mane:
		VertexShapes.oriented_box(tool, Transform3D(turn, head + turn * Vector3(0.0, 0.0, 0.1)), Vector3(0.32, 0.32, 0.18),
				Color(0.48, 0.3, 0.14))
	if stripes:
		for k: int in 5:
			var z := -0.5 + k * 0.25
			VertexShapes.oriented_box(tool, Transform3D(turn, Vector3(0.0, 0.5 + 0.27, 0.0) + turn * Vector3(0.0, 0.0, z)),
					Vector3(0.29, 0.28, 0.035), Color(0.12, 0.1, 0.08))


static func _zebra(tool: SurfaceTool, at: Vector3, yaw: float) -> void:
	var white := Color(0.9, 0.9, 0.88)
	var turn := Basis(Vector3.UP, yaw)
	var head := _quadruped(tool, at, yaw, Vector3(0.28, 0.3, 0.62), 0.75, 0.07, Vector3(0.0, 0.55, -0.85),
			Vector3(0.12, 0.14, 0.28), white)
	for k: int in 5:
		var z := -0.45 + k * 0.22
		VertexShapes.oriented_box(tool, Transform3D(turn, at + Vector3(0.0, 0.75 + 0.3, 0.0) + turn * Vector3(0.0, 0.0, z)),
				Vector3(0.29, 0.31, 0.03), Color(0.1, 0.1, 0.1))
	VertexShapes.oriented_box(tool, Transform3D(turn, head + turn * Vector3(0.0, 0.16, 0.05)), Vector3(0.03, 0.06, 0.2),
			Color(0.1, 0.1, 0.1))


## Poleiro com três araras.
static func _parrots(tool: SurfaceTool) -> void:
	var wood := Color(0.42, 0.3, 0.18)
	for side: float in [-1.0, 1.0]:
		VertexShapes.strut(tool, Vector3(side * 0.9, 0.0, 0.0), Vector3(side * 0.9, 1.6, 0.0), 0.05, 0.05, wood)
	VertexShapes.strut(tool, Vector3(-1.0, 1.6, 0.0), Vector3(1.0, 1.6, 0.0), 0.04, 0.04, wood)
	var colors: Array[Color] = [Color(0.85, 0.12, 0.1), Color(0.12, 0.35, 0.85), Color(0.15, 0.65, 0.2)]
	for k: int in 3:
		var at := Vector3(-0.55 + k * 0.55, 1.64, 0.0)
		VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.RIGHT, 0.35), at + Vector3(0.0, 0.18, 0.0)),
				Vector3(0.08, 0.16, 0.08), colors[k])
		VertexShapes.box(tool, at + Vector3(0.0, 0.38, -0.04), Vector3(0.07, 0.07, 0.07), colors[k])
		VertexShapes.box(tool, at + Vector3(0.0, 0.36, -0.13), Vector3(0.03, 0.03, 0.04), Color(0.95, 0.85, 0.3))
		VertexShapes.strut(tool, at + Vector3(0.0, 0.05, 0.05), at + Vector3(0.0, -0.3, 0.12), 0.04, 0.015, colors[k].darkened(0.2))


static func _amphora(tool: SurfaceTool) -> void:
	var clay := Color(0.72, 0.38, 0.2)
	VertexShapes.cylinder(tool, Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.08, 0.0), 0.12, clay.darkened(0.2), 12)
	VertexShapes.cylinder(tool, Vector3(0.0, 0.08, 0.0), Vector3(0.0, 0.25, 0.0), 0.2, clay, 12)
	VertexShapes.cylinder(tool, Vector3(0.0, 0.25, 0.0), Vector3(0.0, 0.55, 0.0), 0.28, clay, 12)
	VertexShapes.cylinder(tool, Vector3(0.0, 0.55, 0.0), Vector3(0.0, 0.66, 0.0), 0.2, Color(0.1, 0.08, 0.07), 12)
	VertexShapes.cylinder(tool, Vector3(0.0, 0.66, 0.0), Vector3(0.0, 0.88, 0.0), 0.09, clay, 12)
	VertexShapes.cylinder(tool, Vector3(0.0, 0.88, 0.0), Vector3(0.0, 0.93, 0.0), 0.13, clay, 12)
	for side: float in [-1.0, 1.0]:
		VertexShapes.strut(tool, Vector3(side * 0.09, 0.84, 0.0), Vector3(side * 0.24, 0.62, 0.0), 0.025, 0.04, clay.darkened(0.1))


## Amonite de pé num suporte: a concha em disco com as voltas em tons.
static func _ammonite(tool: SurfaceTool) -> void:
	var bone := Color(0.84, 0.8, 0.68)
	VertexShapes.box(tool, Vector3(0.0, 0.05, 0.0), Vector3(0.3, 0.05, 0.15), Color(0.25, 0.2, 0.16))
	var middle := Vector3(0.0, 0.5, 0.0)
	for ring: int in 3:
		var radius := 0.42 - ring * 0.12
		var depth := 0.09 + ring * 0.015
		VertexShapes.cylinder(tool, middle - Vector3(0.0, 0.0, depth), middle + Vector3(0.0, 0.0, depth), radius,
				bone.darkened(ring * 0.15), 16)


static func _sarcophagus(tool: SurfaceTool) -> void:
	var gold := Color(0.82, 0.64, 0.22)
	VertexShapes.box(tool, Vector3(0.0, 0.08, 0.0), Vector3(0.3, 0.08, 0.2), Color(0.3, 0.25, 0.2))
	VertexShapes.box(tool, Vector3(0.0, 0.95, 0.0), Vector3(0.24, 0.8, 0.16), gold)
	VertexShapes.box(tool, Vector3(0.0, 1.55, -0.12), Vector3(0.14, 0.17, 0.06), Color(0.85, 0.7, 0.5))
	for k: int in 3:
		VertexShapes.box(tool, Vector3(0.0, 0.65 + k * 0.25, -0.165), Vector3(0.22, 0.04, 0.01), Color(0.1, 0.25, 0.6))
	VertexShapes.box(tool, Vector3(0.0, 1.6, 0.02), Vector3(0.22, 0.24, 0.14), Color(0.1, 0.25, 0.6))


## Quadro de mestre antigo num cavalete: moldura dourada e a pintura em manchas.
static func _painting(tool: SurfaceTool) -> void:
	var wood := Color(0.4, 0.27, 0.15)
	for side: float in [-1.0, 1.0]:
		VertexShapes.strut(tool, Vector3(side * 0.35, 0.0, -0.15), Vector3(side * 0.12, 1.7, 0.0), 0.03, 0.03, wood)
	VertexShapes.strut(tool, Vector3(0.0, 0.0, 0.45), Vector3(0.0, 1.6, 0.05), 0.03, 0.03, wood)
	var frame := Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3(0.0, 1.15, -0.08))
	VertexShapes.oriented_box(tool, frame, Vector3(0.5, 0.4, 0.03), Color(0.78, 0.6, 0.2))
	VertexShapes.oriented_box(tool, frame * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, -0.025)), Vector3(0.42, 0.32, 0.01),
			Color(0.22, 0.3, 0.2))
	VertexShapes.oriented_box(tool, frame * Transform3D(Basis.IDENTITY, Vector3(0.12, 0.05, -0.04)), Vector3(0.14, 0.18, 0.005),
			Color(0.75, 0.55, 0.4))
	VertexShapes.oriented_box(tool, frame * Transform3D(Basis.IDENTITY, Vector3(-0.2, 0.18, -0.04)), Vector3(0.16, 0.08, 0.005),
			Color(0.55, 0.65, 0.8))


static func _ship(tool: SurfaceTool) -> void:
	var wood := Color(0.45, 0.28, 0.14)
	VertexShapes.box(tool, Vector3(0.0, 0.05, 0.0), Vector3(0.12, 0.05, 0.3), Color(0.25, 0.2, 0.15))
	VertexShapes.box(tool, Vector3(0.0, 0.22, 0.0), Vector3(0.14, 0.1, 0.42), wood)
	VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.UP, PI * 0.25), Vector3(0.0, 0.22, -0.45)),
			Vector3(0.1, 0.1, 0.1), wood)
	for z: float in [-0.2, 0.15]:
		VertexShapes.strut(tool, Vector3(0.0, 0.3, z), Vector3(0.0, 0.95, z), 0.015, 0.015, wood)
		VertexShapes.box(tool, Vector3(0.0, 0.66, z), Vector3(0.22, 0.2, 0.01), Color(0.93, 0.9, 0.82))


static func _telescope(tool: SurfaceTool) -> void:
	var brass := Color(0.78, 0.6, 0.28)
	var top := Vector3(0.0, 1.0, 0.0)
	for k: int in 3:
		var foot := Vector3(cos(TAU * k / 3.0) * 0.4, 0.0, sin(TAU * k / 3.0) * 0.4)
		VertexShapes.strut(tool, foot, top, 0.025, 0.025, Color(0.35, 0.25, 0.15))
	VertexShapes.cylinder(tool, top + Vector3(0.0, 0.0, 0.45), top + Vector3(0.0, 0.5, -0.6), 0.08, brass, 12)
	VertexShapes.cylinder(tool, top + Vector3(0.0, -0.07, 0.6), top + Vector3(0.0, 0.0, 0.45), 0.05, brass.darkened(0.2), 12)
