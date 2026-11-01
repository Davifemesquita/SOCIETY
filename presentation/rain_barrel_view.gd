class_name RainBarrelView
extends Node3D
## Fase 169: o barril de chuva. Numa casa de camponeses ou operários a cada BARREL_EVERY pelo id, encostado na parede de trás
## junto da quina de −X do corpo (com a ala da Fase 96 desse lado, a calha desce do beiral dela), o barril de aduelas com
## dois arcos de ferro e a água escura em cima, e a calha de lata descendo do beiral pela parede até a boca dele
## (`barrel_body_mesh` e `pipe_mesh`, um MultiMesh de cada). Só se a célula de trás onde ele fica está livre (sem prédio nem
## estrada, em terra). O recheio, as bombas, os silos e as medas deixam a célula limpa (`cells`). No lugar do modelo da casa
## (com o desvio da variação, `BuildingView.model_place`); nada no save; refeito na obra, na demolição, na subida de classe, na
## estrada e ao trocar de mundo.

const TIERS: Array[StringName] = [&"peasants", &"workers"]
const BARREL_EVERY := 2
const BARREL_REST := 0
## O barril: o raio, a altura, a distância do meio dele até a parede e da quina; a calha.
const RADIUS_M := 0.28
const HEIGHT_M := 0.85
const FROM_WALL_M := 0.36
const FROM_CORNER_M := 0.42
const PIPE_M := 0.035
## A curva da calha, onde o cano que desce da parede vira para dentro do barril.
const BEND_M := HEIGHT_M + 0.25
const STAVES := Color(0.48, 0.34, 0.2)
const IRON := Color(0.2, 0.2, 0.21)
const WATER := Color(0.12, 0.16, 0.18)
const TIN := Color(0.46, 0.47, 0.48)

var _simulation: Simulation
## O barril com o cotovelo da calha (uma peça) e o cano de lata que sobe da curva até o beiral (um cilindro de 1 m esticado
## em y por instância): refazer é só pôr as transformações (a malha inteira em GDScript custava ~120 ms com 300 barris).
var _barrels := MultiMeshInstance3D.new()
var _pipes := MultiMeshInstance3D.new()
var _count := 0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.85
	for pair: Array in [[_barrels, "RainBarrels", barrel_body_mesh()], [_pipes, "Downpipes", pipe_mesh()]]:
		var layer: MultiMeshInstance3D = pair[0]
		var name_text: String = pair[1]
		var mesh: ArrayMesh = pair[2]
		layer.name = name_text
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.mesh = mesh
		layer.material_override = material
		add_child(layer)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.house_upgraded.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func barrel_count() -> int:
	return _count


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	var bodies: Array[Transform3D] = []
	var pipes: Array[Transform3D] = []
	for id: int in _simulation.world.building_ids():
		var found: Variant = spot(_simulation, _simulation.world.building(id))
		if found is Array:
			var pair: Array = found
			var place: Transform3D = pair[0]
			var eave: float = pair[1]
			bodies.append(place)
			pipes.append(pipe_place(place, eave))
	_count = bodies.size()
	for pair: Array in [[_barrels, bodies], [_pipes, pipes]]:
		var layer: MultiMeshInstance3D = pair[0]
		var places: Array[Transform3D] = []
		var source: Array = pair[1]
		places.assign(source)
		layer.multimesh.instance_count = places.size()
		for i: int in places.size():
			layer.multimesh.set_instance_transform(i, places[i])
		layer.multimesh.custom_aabb = WorldBounds.of(_simulation.config)


## Onde fica o cano da calha do barril em place: da curva (BEND_M acima do pé) até eave, encostado na parede (o cilindro de
## 1 m esticado em y).
static func pipe_place(place: Transform3D, eave: float) -> Transform3D:
	var length := maxf(eave, BEND_M + 0.35) - BEND_M
	var foot := Vector3(0.0, BEND_M, -FROM_WALL_M + 0.06)
	return place * Transform3D(Basis.from_scale(Vector3(1.0, length, 1.0)), foot)


## [onde fica o barril da casa (mundo: o pé no chão, o +Z para longe da parede de trás), a altura do beiral acima do pé] ou
## null: só nas casas de camponeses e operários do resto certo, com a célula de trás livre (`_cell`). Sempre na quina de −X do
## corpo; se a ala da Fase 96 está desse lado, a calha desce do beiral dela, um andar mais baixo.
static func spot(simulation: Simulation, record: BuildingRecord) -> Variant:
	if _cell(simulation.world, simulation.data, record) == null:
		return null
	var grid := simulation.world.island(record.island_id)
	var spec := BuildingKit.spec_for(simulation, record, grid.cell_size)
	if spec == null:
		return null
	var hall := spec.hall()
	var size := hall.size_m()
	var local := spec.hall_offset() + Vector3(-(size.x * 0.5 - FROM_CORNER_M), 0.0, size.y * 0.5 + FROM_WALL_M)
	var def := simulation.def_of(record)
	var model := BuildingView.model_place(grid, record, Footprint.rect(record.origin, def.size, record.rotation))
	var place := model * Transform3D(Basis.IDENTITY, local)
	# o pé no chão de verdade (o piso do modelo fica no canto alto do lote)
	place.origin.y = grid.height_at(place.origin.x, place.origin.z)
	var eave := hall.height_m - (hall.floor_m() if hall.wing < 0 and hall.floors() >= 2 else 0.0)
	return [place, model.origin.y + eave - place.origin.y]


## A célula do barril da casa, ou null: o meio dela sai do lote (a quina de −X de trás, um pouco para fora), sem o desenho da
## casa — o recheio a confere só com o mundo; a célula é a mesma com as folgas do corpo, que são de centímetros.
static func _cell(world: WorldState, data: GameData, record: BuildingRecord) -> Variant:
	if record == null or not record.is_house() or not TIERS.has(record.tier) or posmod(record.id, BARREL_EVERY) != BARREL_REST:
		return null
	var grid := world.island(record.island_id)
	var def := data.building(record.def_id)
	var half := Vector2(def.size) * grid.cell_size * 0.5
	var model := BuildingView.model_place(grid, record, Footprint.rect(record.origin, def.size, record.rotation))
	var cell := grid.world_to_cell(model * Vector3(-(half.x - FROM_CORNER_M - 0.15), 0.0, half.y + FROM_WALL_M))
	if not grid.in_bounds(cell) or grid.building_at(cell) != 0 or grid.has_road(cell) or not grid.is_land(cell):
		return null
	return cell


## As células dos barris da ilha → o id da casa.
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


## O barril com o pé no zero e a parede em −Z: as aduelas, os dois arcos, a água escura um palmo abaixo da boca e o cotovelo da
## calha, da curva (BEND_M) até dentro do barril; o cano que sobe da curva é o pipe_mesh.
static func barrel_body_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.cylinder(tool, Vector3.ZERO, Vector3(0.0, HEIGHT_M, 0.0), RADIUS_M, STAVES, 12)
	for height: float in [0.18, 0.68]:
		VertexShapes.cylinder(tool, Vector3(0.0, height - 0.025, 0.0), Vector3(0.0, height + 0.025, 0.0), RADIUS_M + 0.012,
				IRON, 12)
	VertexShapes.cylinder(tool, Vector3(0.0, HEIGHT_M - 0.1, 0.0), Vector3(0.0, HEIGHT_M - 0.09, 0.0), RADIUS_M - 0.02, WATER, 12)
	var bend := Vector3(0.0, BEND_M, -FROM_WALL_M + 0.06)
	VertexShapes.cylinder(tool, bend, Vector3(0.0, HEIGHT_M + 0.08, 0.0), PIPE_M, TIN, 6)
	tool.generate_normals()
	return tool.commit()


## O cano de lata da calha: 1 m de altura do zero para cima (a instância o estica até o beiral).
static func pipe_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.cylinder(tool, Vector3.ZERO, Vector3(0.0, 1.0, 0.0), PIPE_M, TIN, 6)
	tool.generate_normals()
	return tool.commit()
