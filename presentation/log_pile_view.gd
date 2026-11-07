class_name LogPileView
extends Node3D
## Fase 171: a lenha na parede. Numa casa de camponeses ou operários a cada PILE_EVERY pelo id, encostada na parede do lado de
## +X do corpo, a pilha de lenha rachada em fiadas — as achas de ponta para fora, em tons de madeira e de miolo claro — com uma
## cobertura de tábuas inclinada por cima (`pile_mesh`). Só se a célula do lado onde ela fica está livre (sem prédio nem estrada,
## em terra): a célula sai só do lote (`_cell`), para o recheio e as bombas d'água a deixarem limpa (`cells`). No lugar do
## modelo da casa (com o desvio da variação, `BuildingView.model_place`); um MultiMesh (a peça é a mesma em todas); nada no
## save; refeito na obra, na demolição, na subida de classe, na estrada e ao trocar de mundo.

const TIERS: Array[StringName] = [&"peasants", &"workers"]
const PILE_EVERY := 3
const PILE_REST := 1
## A pilha: o comprimento ao longo da parede, as fiadas, a distância do meio dela até a parede; as achas e a cobertura.
const LENGTH_M := 1.5
const COURSES := 6
const LOG_M := 0.42
const LOG_RADIUS_M := 0.06
const FROM_WALL_M := 0.28
const BARK := Color(0.36, 0.26, 0.17)
const SPLIT := Color(0.74, 0.6, 0.4)
const BOARD := Color(0.33, 0.25, 0.17)

var _simulation: Simulation
var _piles := MultiMeshInstance3D.new()
## Os lugares das pilhas (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	_piles.name = "LogPiles"
	_piles.multimesh = MultiMesh.new()
	_piles.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_piles.multimesh.mesh = pile_mesh()
	_piles.material_override = material
	add_child(_piles)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.house_upgraded.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func pile_count() -> int:
	return places.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	places.clear()
	for id: int in _simulation.world.building_ids():
		var found: Variant = spot(_simulation, _simulation.world.building(id))
		if found is Transform3D:
			places.append(found)
	_piles.multimesh.instance_count = places.size()
	for i: int in places.size():
		_piles.multimesh.set_instance_transform(i, places[i])
	_piles.multimesh.custom_aabb = WorldBounds.of(_simulation.config)


## Onde fica a pilha da casa (mundo: o pé no chão, o x ao longo da parede, o +Z para longe dela) ou null.
static func spot(simulation: Simulation, record: BuildingRecord) -> Variant:
	if _cell(simulation.world, simulation.data, record) == null:
		return null
	var grid := simulation.world.island(record.island_id)
	var spec := BuildingKit.spec_for(simulation, record, grid.cell_size)
	if spec == null:
		return null
	var hall := spec.hall()
	var local := spec.hall_offset() + Vector3(hall.size_m().x * 0.5 + FROM_WALL_M, 0.0, 0.0)
	var def := simulation.def_of(record)
	var model := BuildingView.model_place(grid, record, Footprint.rect(record.origin, def.size, record.rotation))
	# a parede de +X: o x da pilha ao longo dela (−Z do modelo) e o +Z para fora (+X do modelo)
	var place := model * Transform3D(Basis(Vector3.FORWARD, Vector3.UP, Vector3.RIGHT), local)
	place.origin.y = grid.height_at(place.origin.x, place.origin.z)
	return place


## A célula da pilha da casa, ou null: o meio do lado de +X do lote, um pouco para fora (só pelo lote, sem o desenho da casa).
static func _cell(world: WorldState, data: GameData, record: BuildingRecord) -> Variant:
	if record == null or not record.is_house() or not TIERS.has(record.tier) or posmod(record.id, PILE_EVERY) != PILE_REST:
		return null
	var grid := world.island(record.island_id)
	var def := data.building(record.def_id)
	var half := Vector2(def.size) * grid.cell_size * 0.5
	var model := BuildingView.model_place(grid, record, Footprint.rect(record.origin, def.size, record.rotation))
	var cell := grid.world_to_cell(model * Vector3(half.x + 0.25, 0.0, 0.0))
	if not grid.in_bounds(cell) or grid.building_at(cell) != 0 or grid.has_road(cell) or not grid.is_land(cell):
		return null
	return cell


## As células das pilhas da ilha → o id da casa.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}
	if world.island(island_id) == null:
		return result
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id != island_id:
			continue
		var found: Variant = _cell(world, data, record)
		if found is Vector2i:
			var cell: Vector2i = found
			result[cell] = id
	return result


## A pilha com o pé no zero, ao longo de x, a parede em −Z: COURSES fiadas de achas de ponta para fora (o eixo em z), cada fiada
## desencontrada da de baixo, a casca escura e a ponta cortada clara; e a cobertura de duas tábuas caindo para fora.
static func pile_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := LOG_RADIUS_M * 2.05
	var count := floori(LENGTH_M / step)
	for course: int in COURSES:
		var y := LOG_RADIUS_M + course * LOG_RADIUS_M * 1.75
		var shift := step * 0.5 if course % 2 == 1 else 0.0
		for k: int in count - (course % 2):
			var x := -LENGTH_M * 0.5 + step * 0.5 + k * step + shift
			var near := Vector3(x, y, LOG_M * 0.5)
			var far := Vector3(x, y, -LOG_M * 0.5)
			VertexShapes.cylinder(tool, far, near, LOG_RADIUS_M, BARK, 5)
			VertexShapes.cylinder(tool, near, near + Vector3(0.0, 0.0, 0.004), LOG_RADIUS_M * 0.92, SPLIT, 5)
	var top := LOG_RADIUS_M + COURSES * LOG_RADIUS_M * 1.75 + 0.04
	for k: int in 2:
		var at := Vector3(0.0, top - k * 0.06, -LOG_M * 0.25 + k * LOG_M * 0.5)
		VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.RIGHT, 0.25), at), Vector3(LENGTH_M * 0.5 + 0.08, 0.015, LOG_M * 0.3),
				BOARD)
	tool.generate_normals()
	return tool.commit()
