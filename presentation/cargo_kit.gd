class_name CargoKit
extends RefCounted
## Carga visível (Fase 13): sacos, barris, caixotes, toras e montes. As mesmas peças fazem as pilhas
## de estoque diante dos prédios (StockpileView) e a carga da carroça (CartView). Barril e caixote são
## do Kenney Pirate Kit (CC0, assets/models/cargo/); saco, tora e monte são gerados aqui, na cor do bem
## (cor da instância do MultiMesh). Cada peça cabe em ITEM_M e tem a base em y = 0.

const DIR := "res://assets/models/cargo/"
## Lado de uma peça (m) e quanto ela sobe quando vai por cima de outra.
const ITEM_M := 0.8
const STACK_M := 0.62
## Saco: juta clara puxada para a cor do bem.
const SACK_COLOR := Color(0.72, 0.62, 0.45)
const SACK_TINT := 0.35

static var _meshes: Dictionary[int, Mesh] = {}


## A peça do tipo de pilha (GoodDef.Pile); null para NONE ou peça do kit que faltar.
static func mesh(pile: int) -> Mesh:
	if _meshes.has(pile):
		return _meshes[pile]
	var result: Mesh = null
	match pile:
		GoodDef.Pile.SACK:
			result = _sack()
		GoodDef.Pile.BARREL:
			result = _model("barrel")
		GoodDef.Pile.CRATE:
			result = _model("crate")
		GoodDef.Pile.LOGS:
			result = _logs()
		GoodDef.Pile.HEAP:
			result = _heap()
	_meshes[pile] = result
	return result


## A peça leva a cor da instância (saco, tora e monte) ou fica com a textura do kit.
static func tinted(pile: int) -> bool:
	return pile in [GoodDef.Pile.SACK, GoodDef.Pile.LOGS, GoodDef.Pile.HEAP]


## Cor da instância para o bem.
static func color_of(good: GoodDef) -> Color:
	if good.pile == GoodDef.Pile.SACK:
		return SACK_COLOR.lerp(good.color, SACK_TINT)
	return good.color


## Onde vai a peça "index" de uma pilha de colunas × fileiras por camada, no referencial da pilha: a
## base no chão em y = 0, as colunas crescendo em x, as fileiras em z e as camadas em y.
static func slot(index: int, columns: int, rows: int) -> Vector3:
	var per_layer := columns * rows
	var in_layer := index % per_layer
	return Vector3((in_layer % columns) * ITEM_M, (index / per_layer) * STACK_M, (in_layer / columns) * ITEM_M)


static func _colored_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.95
	return material


static func _sack() -> Mesh:
	var sphere := SphereMesh.new()
	sphere.radius = ITEM_M * 0.45
	sphere.height = ITEM_M * 0.6
	sphere.radial_segments = 10
	sphere.rings = 5
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.append_from(sphere, 0, Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 0.8)), Vector3(0.0, ITEM_M * 0.3, 0.0)))
	var mesh := tool.commit()
	mesh.surface_set_material(0, _colored_material())
	return mesh


## Três toras deitadas, duas embaixo e uma em cima.
static func _logs() -> Mesh:
	var log_mesh := CylinderMesh.new()
	var radius := ITEM_M * 0.17
	log_mesh.top_radius = radius
	log_mesh.bottom_radius = radius
	log_mesh.height = ITEM_M
	log_mesh.radial_segments = 8
	log_mesh.rings = 1
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lying := Basis(Vector3.BACK, PI * 0.5)
	for center: Vector3 in [Vector3(0.0, radius, -radius * 1.05), Vector3(0.0, radius, radius * 1.05),
			Vector3(0.0, radius * 2.7, 0.0)]:
		tool.append_from(log_mesh, 0, Transform3D(lying, center))
	var mesh := tool.commit()
	mesh.surface_set_material(0, _colored_material())
	return mesh


static func _heap() -> Mesh:
	var cone := CylinderMesh.new()
	cone.top_radius = ITEM_M * 0.06
	cone.bottom_radius = ITEM_M * 0.48
	cone.height = ITEM_M * 0.5
	cone.radial_segments = 9
	cone.rings = 1
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.append_from(cone, 0, Transform3D(Basis.IDENTITY, Vector3(0.0, ITEM_M * 0.25, 0.0)))
	var mesh := tool.commit()
	mesh.surface_set_material(0, _colored_material())
	return mesh


## Peça do kit numa malha só, esticada até ITEM_M no lado maior da base, com a base em y = 0 e o
## meio da base na origem.
static func _model(piece: String) -> Mesh:
	var path := DIR + piece + ".glb"
	if not ResourceLoader.exists(path):
		return null
	var root := (load(path) as PackedScene).instantiate() as Node3D
	var parts: Array[MeshInstance3D] = []
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		parts.append(node as MeshInstance3D)
	var box := AABB()
	for index: int in parts.size():
		var local := _transform_to(root, parts[index]) * parts[index].get_aabb()
		box = local if index == 0 else box.merge(local)
	var scale := ITEM_M / maxf(maxf(box.size.x, box.size.z), 0.001)
	var bottom := Vector3(box.get_center().x, box.position.y, box.get_center().z)
	var place := Transform3D(Basis.from_scale(Vector3.ONE * scale), -bottom * scale)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for part: MeshInstance3D in parts:
		for surface: int in part.mesh.get_surface_count():
			tool.append_from(part.mesh, surface, place * _transform_to(root, part))
	root.free()
	var mesh := tool.commit()
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(DIR + "Textures/colormap.png") as Texture2D
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.roughness = 0.9
	mesh.surface_set_material(0, material)
	return mesh


static func _transform_to(root: Node3D, node: Node3D) -> Transform3D:
	var result := Transform3D.IDENTITY
	var current: Node = node
	while current != root and current is Node3D:
		result = (current as Node3D).transform * result
		current = current.get_parent()
	return result
