class_name PostBoxView
extends Node3D
## Fase 181: a caixa de correio. Numa célula de paralelepípedo a cada tantas pelo desenho da grade (`posmod(7x + 13y,
## POST_EVERY)`, sem sorteio), fora das células dos postes de gás (`LampView.LAMP_EVERY`) e da escada diagonal, a caixa de ferro
## fundido redonda e vermelha encostada no lado da calçada (o mesmo lado e afastamento do poste, `LampView._sidewalk_side`), a
## boca virada para a rua (`spots`, `box_mesh`: o soco, o fuste, o rebordo, o chapéu, a boca e a plaquinha). Um MultiMesh; nada
## no save; refeito quando as estradas mudam e ao trocar de mundo.

const POST_EVERY := 17
const POST_REST := 5
## A caixa: o raio do fuste, a altura dele e as cores.
const BODY_RADIUS_M := 0.2
const BODY_M := 1.0
const SIDES := 14
const RED := Color(0.6, 0.09, 0.07)
const DARK := Color(0.16, 0.14, 0.13)
const SLOT := Color(0.04, 0.03, 0.03)
const PLATE := Color(0.86, 0.8, 0.64)

var _simulation: Simulation
var _boxes := MultiMeshInstance3D.new()
## Os lugares das caixas (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.45
	material.metallic = 0.25
	_boxes.name = "PostBoxes"
	_boxes.multimesh = MultiMesh.new()
	_boxes.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_boxes.multimesh.mesh = box_mesh()
	_boxes.material_override = material
	add_child(_boxes)
	EventBus.roads_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func box_count() -> int:
	return places.size()


func _mark(_island_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	places.clear()
	for island_id: int in _simulation.world.islands.size():
		places.append_array(spots(_simulation.world.island(island_id)))
	_boxes.multimesh.instance_count = places.size()
	for i: int in places.size():
		_boxes.multimesh.set_instance_transform(i, places[i])
	_boxes.multimesh.custom_aabb = WorldBounds.of(_simulation.config)


## As caixas da ilha (mundo: o pé na rua, o +Z da caixa, a boca, virado para o meio da rua).
static func spots(grid: IslandGrid) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for cell: Vector2i in grid.road_cells():
		if not grid.is_paved(cell) or posmod(cell.x * 7 + cell.y * 13, POST_EVERY) != POST_REST:
			continue
		if posmod(cell.x + cell.y * 3, LampView.LAMP_EVERY) == 0 or not RoadView.diagonal_links(grid, cell).is_empty():
			continue
		var side := LampView._sidewalk_side(grid, cell)
		if side == Vector2i.ZERO:
			continue
		var outward := Vector3(side.x, 0.0, side.y)
		var base := grid.surface_world(cell) + outward * LampView.LAMP_OFFSET_M
		# a boca (+Z da caixa) para a rua, o lado oposto da calçada
		result.append(Transform3D(Basis.looking_at(outward, Vector3.UP), base))
	return result


## A caixa com o pé no zero e a boca para +Z: o soco escuro, o fuste vermelho, o rebordo, o chapéu abaulado com o botão, a boca
## escura sob o rebordo e a plaquinha clara mais embaixo.
static func box_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r := BODY_RADIUS_M
	_lathe(tool, [Vector2(r + 0.05, 0.0), Vector2(r + 0.05, 0.06), Vector2(r + 0.02, 0.1)], DARK)
	_lathe(tool, [Vector2(r + 0.02, 0.1), Vector2(r, 0.14), Vector2(r, BODY_M), Vector2(r + 0.04, BODY_M + 0.03),
			Vector2(r + 0.04, BODY_M + 0.07), Vector2(r * 0.97, BODY_M + 0.11), Vector2(r * 0.85, BODY_M + 0.17),
			Vector2(r * 0.62, BODY_M + 0.215), Vector2(r * 0.32, BODY_M + 0.24), Vector2(r * 0.12, BODY_M + 0.255),
			Vector2(0.0, BODY_M + 0.26)], RED)
	# a boca: uma fenda escura saindo um pouco do fuste, logo abaixo do rebordo
	VertexShapes.box(tool, Vector3(0.0, BODY_M - 0.12, r - 0.005), Vector3(0.09, 0.012, 0.02), SLOT)
	VertexShapes.box(tool, Vector3(0.0, BODY_M - 0.095, r + 0.005), Vector3(0.11, 0.012, 0.02), RED)
	# a plaquinha dos horários
	VertexShapes.box(tool, Vector3(0.0, BODY_M * 0.62, r - 0.01), Vector3(0.07, 0.05, 0.02), PLATE)
	tool.generate_normals()
	return tool.commit()


## Sólido de revolução em volta de +y pelo perfil [raio, altura] de baixo para cima, as faces para fora (o mesmo sentido do
## VertexShapes.cylinder: x = −sen, z = −cos).
static func _lathe(tool: SurfaceTool, profile: Array[Vector2], color: Color) -> void:
	for k: int in profile.size() - 1:
		var low := profile[k]
		var high := profile[k + 1]
		for i: int in SIDES:
			var a0 := TAU * i / SIDES
			var a1 := TAU * (i + 1) / SIDES
			var p0 := Vector3(-sin(a0), 0.0, -cos(a0))
			var p1 := Vector3(-sin(a1), 0.0, -cos(a1))
			VertexShapes.quad(tool, p0 * low.x + Vector3.UP * low.y, p0 * high.x + Vector3.UP * high.y,
					p1 * high.x + Vector3.UP * high.y, p1 * low.x + Vector3.UP * low.y, color)
