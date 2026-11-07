class_name QuayMastView
extends Node3D
## Fase 147: os mastros do cais. Na ponta de cada lado do cais de pedra dos entrepostos (o lanço mais longe do prédio de
## cada lado, `masts`), MAST_IN_M para dentro da beira, um mastro de madeira caiada sobre o soco de pedra, com a bola no
## alto e uma flâmula comprida de rabo de andorinha (`pennant_mesh`) presa nele. A flâmula é uma `WindFlag` (Fase 22): o
## `WeatherView` a gira para o lado do vento e a faz tremular, e com o ar parado ela cai. As cores se alternam pelo mastro
## (PENNANTS). Nós de verdade (poucos: dois por entreposto); nada no save; refeitos na obra, na demolição e ao trocar de
## mundo.

const MAST_M := 7.0
const MAST_IN_M := 1.6
const BASE_M := Vector3(0.6, 0.5, 0.6)
## A flâmula: o comprimento, a altura junto do mastro e o corte do rabo de andorinha (fração do comprimento).
const PENNANT_M := Vector2(2.8, 0.7)
const FORK := 0.22
const PENNANTS: Array[Color] = [Color(0.72, 0.12, 0.1), Color(0.14, 0.26, 0.55), Color(0.92, 0.88, 0.8)]
const WOOD := Color(0.88, 0.86, 0.8)
const STONE := Color(0.6, 0.58, 0.54)
const GILT := Color(0.8, 0.64, 0.25)

var _simulation: Simulation
var _nodes: Array[Node3D] = []
var _mast_mesh: ArrayMesh
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var painted := StandardMaterial3D.new()
	painted.vertex_color_use_as_albedo = true
	painted.vertex_color_is_srgb = true
	painted.roughness = 0.7
	_mast_mesh = mast_mesh()
	_mast_mesh.surface_set_material(0, painted)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func mast_count() -> int:
	return _nodes.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	for node: Node3D in _nodes:
		remove_child(node)
		node.queue_free()
	_nodes.clear()
	var world := _simulation.world
	for id: int in world.building_ids():
		var record := world.building(id)
		if not _simulation.def_of(record).is_trading_post:
			continue
		for foot: Vector3 in masts(_simulation, record):
			_add_mast(foot, PENNANTS[_nodes.size() % PENNANTS.size()])


func _add_mast(foot: Vector3, color: Color) -> void:
	var root := Node3D.new()
	root.name = "Mast%d" % _nodes.size()
	root.position = foot
	var body := MeshInstance3D.new()
	body.mesh = _mast_mesh
	root.add_child(body)
	var cloth_material := StandardMaterial3D.new()
	cloth_material.albedo_color = color
	cloth_material.roughness = 0.9
	cloth_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var flag := WindFlag.new()
	flag.name = "Flag"
	flag.position = Vector3(0.07, MAST_M - 0.45, 0.0)
	var cloth := MeshInstance3D.new()
	cloth.name = "Cloth"
	cloth.mesh = pennant_mesh()
	cloth.material_override = cloth_material
	cloth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flag.add_child(cloth)
	flag.add_to_group(WindFlag.GROUP)
	root.add_child(flag)
	add_child(root)
	_nodes.append(root)


## Os pés dos mastros do entreposto (no alto do capeamento): no lanço do cais de pedra mais longe do prédio de cada lado,
## MAST_IN_M para dentro da beira; nada do lado sem cais além da frente do prédio.
static func masts(simulation: Simulation, record: BuildingRecord) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var segments := HarborView.stone_quay(simulation, record)
	if segments.is_empty():
		return result
	var plan := HarborView.walkway(simulation, record)
	var half: Vector2 = plan["half"]
	var start: Vector3 = plan["start"]
	var direction: Vector3 = plan["direction"]
	var across := Vector3(-direction.z, 0.0, direction.x)
	var width := (half.y if direction.x != 0.0 else half.x) * 2.0
	for side: float in [-1.0, 1.0]:
		var best: Array = []
		var best_t := width * 0.5 + HarborView.STONE_QUAY_STEP_M
		for segment: Array in segments:
			var front: Vector3 = segment[0]
			var t := (front - start).dot(across) * side
			if t > best_t:
				best_t = t
				best = segment
		if best.is_empty():
			continue
		var edge: Vector3 = best[0]
		var outward: Vector3 = best[1]
		result.append(edge - outward * MAST_IN_M + Vector3(0.0, HarborView.COPING_M.x, 0.0))
	return result


## O mastro com o pé no zero: o soco de pedra, o mastro caiado afinando, os anéis de ferro e a bola dourada no alto.
static func mast_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.box(tool, Vector3(0.0, BASE_M.y * 0.5, 0.0), BASE_M * 0.5, STONE)
	VertexShapes.box(tool, Vector3(0.0, BASE_M.y + 0.04, 0.0), Vector3(BASE_M.x * 0.55, 0.04, BASE_M.z * 0.55), STONE.darkened(0.1))
	var low := BASE_M.y
	var sections := 4
	for k: int in sections:
		var y0 := lerpf(low, MAST_M, float(k) / sections)
		var y1 := lerpf(low, MAST_M, float(k + 1) / sections)
		var radius := lerpf(0.09, 0.05, float(k) / sections)
		VertexShapes.cylinder(tool, Vector3(0.0, y0, 0.0), Vector3(0.0, y1, 0.0), radius, WOOD, 8)
	for y: float in [low + 0.3, MAST_M * 0.55]:
		VertexShapes.cylinder(tool, Vector3(0.0, y, 0.0), Vector3(0.0, y + 0.06, 0.0), 0.1, Color(0.2, 0.2, 0.21), 8)
	VertexShapes.box(tool, Vector3(0.0, MAST_M + 0.12, 0.0), Vector3(0.11, 0.11, 0.11), GILT)
	tool.generate_normals()
	return tool.commit()


## A flâmula ao longo de +x a partir do mastro, no plano xy: larga junto dele e afinando até a ponta, com o rabo de
## andorinha cortado no fim.
static func pennant_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var length := PENNANT_M.x
	var half := PENNANT_M.y * 0.5
	var notch := length * (1.0 - FORK)
	var tip_half := half * 0.35
	var points: Array[Vector3] = [Vector3(0.0, half, 0.0), Vector3(length, tip_half, 0.0), Vector3(notch, 0.0, 0.0),
			Vector3(length, -tip_half, 0.0), Vector3(0.0, -half, 0.0)]
	for triangle: Array in [[0, 1, 2], [0, 2, 4], [4, 2, 3]]:
		for index: int in triangle:
			tool.set_normal(Vector3.BACK)
			tool.add_vertex(points[index])
	return tool.commit()
