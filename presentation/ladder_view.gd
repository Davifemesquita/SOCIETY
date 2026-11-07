class_name LadderView
extends Node3D
## Fase 214: a escada de mão. Numa casa a cada LADDER_EVERY pelo id (resto LADDER_REST), de telhado de duas águas (sem a ala da
## Fase 96), encostada na parede de −X do corpo (a de +X tem a lenha da Fase 171; a casinha do cão da Fase 197 fica no mesmo
## lado, mas na frente), na metade de trás, do chão até o beiral (`spot`): a escada de madeira de dois banzos com os degraus,
## inclinada contra a parede, e o balde de lata no pé (`ladder_mesh`, esticada até a altura do beiral). Só se a célula do lado
## está livre (`_cell`, só pelo lote): o recheio e as bombas a deixam (`cells`). No lugar do modelo (`BuildingView.model_place`);
## um MultiMesh; nada no save; refeito na obra, na demolição, na subida de classe, na estrada e ao trocar de mundo.

const LADDER_EVERY := 7
const LADDER_REST := 4
## Do meio da parede para trás, até o pé da escada; o afastamento do pé da parede e a altura de referência da malha.
const BACK_M := 0.9
const FOOT_OUT_M := 0.7
const HEIGHT_M := 4.0
const RUNG_STEP_M := 0.3
const WIDTH_M := 0.42
const WOOD := Color(0.5, 0.38, 0.24)
const WOOD_DARK := Color(0.38, 0.28, 0.18)
const TIN := Color(0.6, 0.61, 0.63)

var _simulation: Simulation
var _ladders := MultiMeshInstance3D.new()
## Os lugares das escadas (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.85
	_ladders.name = "Ladders"
	_ladders.multimesh = MultiMesh.new()
	_ladders.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_ladders.multimesh.mesh = ladder_mesh()
	_ladders.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_ladders.material_override = material
	add_child(_ladders)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.house_upgraded.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func ladder_count() -> int:
	return places.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	places.clear()
	var world := _simulation.world
	for id: int in world.building_ids():
		var found: Variant = spot(_simulation, world.building(id))
		if found is Transform3D:
			var place: Transform3D = found
			places.append(place)
	_ladders.multimesh.instance_count = places.size()
	for i: int in places.size():
		_ladders.multimesh.set_instance_transform(i, places[i])


## O lugar da escada da casa (o pé no chão, o +z para longe da parede, o y esticado até o beiral), ou null.
static func spot(simulation: Simulation, record: BuildingRecord) -> Variant:
	if _cell(simulation.world, simulation.data, record) == null:
		return null
	var grid := simulation.world.island(record.island_id)
	var spec := BuildingKit.spec_for(simulation, record, grid.cell_size)
	if spec == null or spec.roof not in [BuildingKit.Roof.GABLE_X, BuildingKit.Roof.GABLE_Z] or spec.wing != 0:
		return null
	var hall := spec.hall()
	var def := simulation.def_of(record)
	var model := BuildingView.model_place(grid, record, Footprint.rect(record.origin, def.size, record.rotation))
	var wall := spec.hall_offset() + Vector3(-hall.size_m().x * 0.5, 0.0, BACK_M)
	var eave := hall.height_m
	# o −X do modelo é o +z da escada (para fora da parede); o x dela corre ao longo da parede
	var basis := Basis(Vector3(0.0, 0.0, 1.0), Vector3.UP, Vector3(-1.0, 0.0, 0.0)) * Basis.from_scale(Vector3(1.0, eave / HEIGHT_M,
			1.0))
	var place := model * Transform3D(basis, wall)
	place.origin.y = maxf(grid.height_at(place.origin.x, place.origin.z), model.origin.y - 0.6)
	return place


## A célula da escada, só pelo lote, ou null: casa do resto certo e a célula do lado de −X, na metade de trás, livre.
static func _cell(world: WorldState, data: GameData, record: BuildingRecord) -> Variant:
	if record == null or not record.is_house() or posmod(record.id, LADDER_EVERY) != LADDER_REST:
		return null
	var grid := world.island(record.island_id)
	var def := data.building(record.def_id)
	var half := Vector2(def.size) * grid.cell_size * 0.5
	var model := BuildingView.model_place(grid, record, Footprint.rect(record.origin, def.size, record.rotation))
	var cell := grid.world_to_cell(model * Vector3(-half.x - FOOT_OUT_M * 0.5, 0.0, BACK_M))
	if not grid.in_bounds(cell) or grid.building_at(cell) != 0 or grid.has_road(cell) or not grid.is_land(cell):
		return null
	return cell


## As células das escadas da ilha → o id da casa.
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


## A escada com o pé no chão a FOOT_OUT_M da parede (em +z) e o alto na parede (z = 0) em HEIGHT_M: os dois banzos, os degraus a
## cada RUNG_STEP_M e o balde de lata no pé, fora da escada (a malha se estica em y até o beiral; o balde baixa junto, pouco).
static func ladder_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var foot := Vector3(0.0, 0.0, FOOT_OUT_M)
	var top := Vector3(0.0, HEIGHT_M, 0.05)
	for side: float in [-1.0, 1.0]:
		var x := Vector3(side * WIDTH_M * 0.5, 0.0, 0.0)
		VertexShapes.strut(tool, foot + x, top + x + Vector3(0.0, 0.25, 0.0), 0.03, 0.022, WOOD)
	var rungs := int(HEIGHT_M / RUNG_STEP_M)
	for k: int in range(1, rungs):
		var t := float(k) / rungs
		var at := foot.lerp(top, t)
		VertexShapes.strut(tool, at - Vector3(WIDTH_M * 0.5, 0.0, 0.0), at + Vector3(WIDTH_M * 0.5, 0.0, 0.0), 0.016, 0.016,
				WOOD_DARK)
	# o balde de lata ao lado do pé, de boca para cima, com a alça
	var pail := Vector3(WIDTH_M * 0.5 + 0.28, 0.0, FOOT_OUT_M - 0.05)
	VertexShapes.cylinder(tool, pail, pail + Vector3(0.0, 0.26, 0.0), 0.13, TIN, 10)
	VertexShapes.strut(tool, pail + Vector3(-0.12, 0.26, 0.0), pail + Vector3(0.0, 0.36, 0.0), 0.006, 0.006, WOOD_DARK)
	VertexShapes.strut(tool, pail + Vector3(0.0, 0.36, 0.0), pail + Vector3(0.12, 0.26, 0.0), 0.006, 0.006, WOOD_DARK)
	tool.generate_normals()
	return tool.commit()
