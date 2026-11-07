class_name StreetLaundryView
extends Node3D
## Fase 192: a roupa sobre a rua. Entre duas casas de operários frente a frente com uma rua de uma célula no meio (a casa do
## outro lado da rua, virada para ela), num par a cada LINE_EVERY pelo id da casa de menor id, o varal atravessa a rua no alto,
## de uma fachada à outra, caindo em curva (`HarborView.rope_span`), com a roupa pendurada nele (`lines`, `_cloths`, nas cores
## da roupa dos varais dos quintais). Uma malha só para o arquipélago (são poucos varais); nada no save; refeito na obra, na
## demolição, na subida de classe, na estrada e ao trocar de mundo.

const TIERS: Array[StringName] = [&"workers"]
const LINE_EVERY := 2
const LINE_REST := 0
## A altura do varal na fachada, a barriga do cabo e a roupa: quantas peças, a largura e o comprimento delas.
const HEIGHT_M := 4.6
const SAG := 0.06
const CLOTHS := 3
const CLOTH_M := Vector2(0.5, 0.7)
const ROPE := Color(0.82, 0.78, 0.68)

var _simulation: Simulation
var _mesh := MeshInstance3D.new()
## Os varais: [ponta numa fachada, ponta na outra] (testes).
var spans: Array[Array] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.95
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh.name = "StreetLaundry"
	_mesh.material_override = material
	add_child(_mesh)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.house_upgraded.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func line_count() -> int:
	return spans.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	spans = lines(_simulation)
	if spans.is_empty():
		_mesh.mesh = null
		return
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k: int in spans.size():
		var from: Vector3 = spans[k][0]
		var to: Vector3 = spans[k][1]
		var points := HarborView.rope_span(from, to, SAG)
		_rope(tool, points)
		_cloths(tool, points, k)
	tool.generate_normals()
	_mesh.mesh = tool.commit()


## Os varais de todas as ilhas: [ponta na fachada da casa de menor id, ponta na fachada da da frente], no alto.
static func lines(simulation: Simulation) -> Array[Array]:
	var result: Array[Array] = []
	var world := simulation.world
	for id: int in world.building_ids():
		var record := world.building(id)
		if not record.is_house() or record.tier not in TIERS or posmod(record.id, LINE_EVERY) != LINE_REST:
			continue
		var grid := world.island(record.island_id)
		var def := simulation.def_of(record)
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		var front := Footprint.front_direction(record.rotation)
		# a célula da rua diante do meio da frente e a do outro lado dela
		var middle := area.position + area.size / 2
		var reach := absi(front.x) * (area.size.x / 2 + 1) + absi(front.y) * (area.size.y / 2 + 1)
		var road := middle + front * reach
		if not grid.in_bounds(road + front) or not grid.has_road(road) or grid.has_road(road + front):
			continue
		var other := world.building(grid.occupancy[grid.index(road + front)])
		if other == null or other.id == record.id or not other.is_house() or other.tier not in TIERS:
			continue
		if Footprint.front_direction(other.rotation) != -front:
			continue
		var heading := Vector3(front.x, 0.0, front.y)
		var edge := grid.cell_world(road) - heading * grid.cell_size * 0.5
		var far := grid.cell_world(road) + heading * grid.cell_size * 0.5
		edge.y = grid.height_at(edge.x, edge.z) + HEIGHT_M
		far.y = grid.height_at(far.x, far.z) + HEIGHT_M
		result.append([edge, far])
	return result


static func _rope(tool: SurfaceTool, points: PackedVector3Array) -> void:
	for i: int in points.size() - 1:
		VertexShapes.strut(tool, points[i], points[i + 1], 0.012, 0.012, ROPE)


## A roupa pendurada no varal k: CLOTHS peças espalhadas ao longo dele, cada uma presa no cabo e caindo, nas cores dos varais.
static func _cloths(tool: SurfaceTool, points: PackedVector3Array, k: int) -> void:
	var count := points.size() - 1
	for c: int in CLOTHS:
		var t := (c + 1.0) / (CLOTHS + 1.0)
		var at := t * count
		var i := mini(floori(at), count - 1)
		var top := points[i].lerp(points[i + 1], at - i)
		var along := (points[i + 1] - points[i]).normalized()
		var half := along * CLOTH_M.x * 0.5 * (0.7 + 0.3 * float((k + c) % 2))
		var drop := Vector3(0.0, -CLOTH_M.y * (0.75 + 0.25 * float((k * 3 + c) % 3) / 2.0), 0.0)
		var color: Color = YardView.CLOTH_COLORS[(k * 3 + c) % YardView.CLOTH_COLORS.size()]
		VertexShapes.quad(tool, top - half, top + half, top + half + drop, top - half + drop, color)
