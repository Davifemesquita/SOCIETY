class_name WheelbarrowView
extends Node3D
## Fase 172: o carrinho de mão. No pátio de chão batido (Fase 165) de um prédio de produção a cada BARROW_EVERY pelo id (fora as
## fazendas de campo, que não têm pátio), parado na célula livre encostada no meio da face de trás, de terra e sem estrada,
## trilho nem árvore, girado à toa: a caixa de tábuas afunilada, a roda na frente, as duas pernas e os dois braços para trás
## (`barrow_mesh`). O recheio e as bombas d'água deixam a célula limpa (`cells`). Um MultiMesh; nada no save; refeito na obra,
## na demolição, na estrada e ao trocar de mundo.

const BARROW_EVERY := 2
const BARROW_REST := 1
const WOOD := Color(0.48, 0.35, 0.22)
const WOOD_DARK := Color(0.36, 0.26, 0.17)
const IRON := Color(0.18, 0.18, 0.19)

var _simulation: Simulation
var _barrows := MultiMeshInstance3D.new()
## Os lugares dos carrinhos (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.85
	_barrows.name = "Wheelbarrows"
	_barrows.multimesh = MultiMesh.new()
	_barrows.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_barrows.multimesh.mesh = barrow_mesh()
	_barrows.material_override = material
	add_child(_barrows)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func barrow_count() -> int:
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
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		var found := cells(world, _simulation.data, island_id)
		for cell: Vector2i in found:
			var middle := grid.cell_world(cell)
			var turn := float(posmod(found[cell] * 53, 360)) * PI / 180.0
			places.append(Transform3D(Basis(Vector3.UP, turn), Vector3(middle.x, grid.height_at(middle.x, middle.z), middle.z)))
	_barrows.multimesh.instance_count = places.size()
	for i: int in places.size():
		_barrows.multimesh.set_instance_transform(i, places[i])
	_barrows.multimesh.custom_aabb = WorldBounds.of(_simulation.config)


## A célula do carrinho de cada oficina da ilha → o id dela: a encostada no meio da face de trás, livre.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}
	var grid := world.island(island_id)
	if grid == null:
		return result
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id != island_id or posmod(id, BARROW_EVERY) != BARROW_REST:
			continue
		var def := data.building(record.def_id)
		if def == null or not def.is_production() or def.module_id != &"":
			continue
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		var cell := SpoilTipView._beside(area, -Footprint.front_direction(record.rotation))
		if not grid.in_bounds(cell) or not grid.is_land(cell):
			continue
		var index := grid.index(cell)
		if grid.occupancy[index] != 0 or grid.roads[index] != IslandGrid.Road.NONE or grid.rails[index] != 0 \
				or (not grid.flat and grid.trees[index] > 0):
			continue
		result[cell] = id
	return result


## O carrinho com o pé no zero, a roda em −Z: a caixa de tábuas mais larga em cima (o fundo e os quatro lados), a roda de
## raios com o aro de ferro, as duas pernas de trás e os dois braços saindo para trás com os punhos.
static func barrow_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bed := 0.32
	# a caixa: o fundo e as quatro tábuas abrindo para cima
	VertexShapes.box(tool, Vector3(0.0, bed, 0.05), Vector3(0.24, 0.02, 0.32), WOOD_DARK)
	for side: float in [-1.0, 1.0]:
		VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.BACK, side * 0.35), Vector3(side * 0.3, bed + 0.12, 0.05)),
				Vector3(0.015, 0.13, 0.34), WOOD)
	VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.RIGHT, -0.5), Vector3(0.0, bed + 0.12, -0.33)),
			Vector3(0.3, 0.13, 0.015), WOOD)
	VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.RIGHT, 0.2), Vector3(0.0, bed + 0.1, 0.39)),
			Vector3(0.32, 0.11, 0.015), WOOD)
	# a roda na frente, de lado (o eixo em x)
	var hub := Vector3(0.0, 0.18, -0.5)
	VertexShapes.cylinder(tool, hub - Vector3(0.03, 0.0, 0.0), hub + Vector3(0.03, 0.0, 0.0), 0.18, IRON, 12)
	VertexShapes.cylinder(tool, hub - Vector3(0.04, 0.0, 0.0), hub + Vector3(0.04, 0.0, 0.0), 0.05, WOOD_DARK, 6)
	# os braços: do eixo da roda, por baixo da caixa, até os punhos atrás
	for side: float in [-1.0, 1.0]:
		var front := hub + Vector3(side * 0.07, 0.0, 0.0)
		var grip := Vector3(side * 0.26, 0.52, 0.98)
		VertexShapes.strut(tool, front, grip, 0.022, 0.022, WOOD_DARK)
		VertexShapes.cylinder(tool, grip, grip + Vector3(0.0, 0.04, 0.12), 0.025, WOOD, 5)
		# a perna de trás, do braço ao chão
		var hip := front.lerp(grip, 0.62)
		VertexShapes.strut(tool, hip, Vector3(hip.x, 0.0, hip.z - 0.04), 0.018, 0.018, WOOD_DARK)
	tool.generate_normals()
	return tool.commit()
