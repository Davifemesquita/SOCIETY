class_name ShipTimberView
extends Node3D
## Fase 247: a madeira curvada no estaleiro. Em cada estaleiro, nas duas células do meio de um lado — o de −X do modelo, depois o de
## trás e por fim o de +X —, pelo `SideYard` e nunca no lado do mar, onde desce a carreira da Fase 115 (`sites`): a pilha de tábuas
## compridas sobre os dormentes e as cavernas curvas de madeira, em U, deitadas umas sobre as outras e uma de pé encostada na
## parede, esperando a vez de entrar no casco (`timber_mesh`, no meio das duas células). O recheio e as bombas deixam as células
## limpas (`cells`). Um MultiMesh; nada no save; refeito na obra, na demolição, na estrada, no trilho e ao trocar de mundo.

const KINDS: Array[StringName] = [&"shipyard"]
const ORDER: Array[Vector2i] = [SideYard.MINUS_X, SideYard.BACK, SideYard.PLUS_X]
## As tábuas: o comprimento, quantas por camada e as camadas; as cavernas: o meio vão, a altura dos braços e quantas.
const PLANK_M := 3.2
const PLANKS := 5
const PLANK_LAYERS := 3
const RIB_HALF_M := 0.4
const RIB_ARM_M := 0.75
const RIBS := 3
const RIB_STEPS := 6
const PLANK := ShipwayView.PLANK_WOOD
const FRAME := ShipwayView.FRAME_WOOD
const SLEEPER := ShipwayView.KEEL_WOOD

var _simulation: Simulation
var _timbers := MultiMeshInstance3D.new()
## Os lugares (o meio entre as duas células no chão, o +z para longe da parede) (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	_timbers.name = "ShipTimbers"
	_timbers.multimesh = MultiMesh.new()
	_timbers.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_timbers.multimesh.mesh = timber_mesh()
	_timbers.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_timbers.material_override = material
	add_child(_timbers)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func timber_count() -> int:
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
		var found := sites(world, _simulation.data, island_id)
		for id: int in found:
			var site: Array = found[id]
			var pair: Array[Vector2i] = site[0]
			var side: Vector2i = site[1]
			places.append(SideYard.place(grid, pair, side))
	_timbers.multimesh.instance_count = places.size()
	for i: int in places.size():
		_timbers.multimesh.set_instance_transform(i, places[i])


## As pilhas da ilha: id do estaleiro → [as duas células, o lado da área para onde elas ficam] (`SideYard.pick`), fora do lado do
## mar (a fileira inteira de células encostada no estaleiro por ali fica tomada).
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	return SideYard.remember(world, "ship_timber/%d" % island_id, _search.bind(world, data, island_id))


static func _search(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	var taken: Dictionary[Vector2i, bool] = {}
	var grid := world.island(island_id)
	for id: int in world.building_ids():
		var record := world.building(id)
		if record.island_id != island_id or record.def_id not in KINDS:
			continue
		var def := data.building(record.def_id)
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		var sea := HarborView.seaward(world, grid.rect_world(area), area, grid.cell_size, record.rotation)
		var step := Vector2i(roundi(sea.x), roundi(sea.z))
		for x: int in range(area.position.x - 1, area.end.x + 1):
			for y: int in range(area.position.y - 1, area.end.y + 1):
				var cell := Vector2i(x, y)
				if not area.has_point(cell) and area.has_point(cell - step):
					taken[cell] = true
	return SideYard.pick(world, data, island_id, KINDS, ORDER, taken)


## As células das pilhas da ilha (o recheio e as bombas as deixam limpas) → o id do estaleiro.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	return SideYard.cells_of(sites(world, data, island_id))


## A madeira com o meio entre as duas células na origem (o pé no chão), a parede do estaleiro em −z (a uma meia célula): a pilha
## de tábuas ao longo de x junto da parede, sobre três dormentes, e na frente as cavernas em U deitadas umas sobre as outras, com
## uma de pé encostada na ponta da pilha.
static func timber_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var back := -0.55
	for x: float in [-PLANK_M * 0.4, 0.0, PLANK_M * 0.4]:
		VertexShapes.box(tool, Vector3(x, 0.05, back), Vector3(0.06, 0.05, 0.4), SLEEPER)
	for layer: int in PLANK_LAYERS:
		for k: int in PLANKS - layer % 2:
			var z := back - 0.32 + k * 0.16 + 0.08 * (layer % 2)
			var shift := 0.06 * float(posmod(k * 3 + layer, 5) - 2)
			VertexShapes.box(tool, Vector3(shift, 0.12 + layer * 0.055, z), Vector3(PLANK_M * 0.5, 0.025, 0.07),
					PLANK.darkened(0.06 * ((k + layer) % 3)))
	# as cavernas: o U de vigas no plano xz, deitado, a abertura para +x
	for k: int in RIBS:
		var at := Vector3(-0.3 + 0.08 * k, 0.05 + k * 0.1, 0.42)
		_rib(tool, Transform3D(Basis(Vector3.UP, 0.08 * (k - 1)), at))
	# e uma de pé encostada na ponta da pilha, a abertura para cima
	_rib(tool, Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(PLANK_M * 0.5 + 0.2, 0.05, -0.2)))
	tool.generate_normals()
	return tool.commit()


## Uma caverna em U no plano xz do lugar: o fundo em arco em volta da origem e os dois braços saindo para +x.
static func _rib(tool: SurfaceTool, place: Transform3D) -> void:
	var last := Vector3.ZERO
	for s: int in RIB_STEPS + 1:
		var angle := PI * 0.5 + PI * s / RIB_STEPS
		var point := Vector3(cos(angle) * RIB_HALF_M * 0.6 + RIB_HALF_M * 0.6, 0.0, sin(angle) * RIB_HALF_M)
		if s > 0:
			VertexShapes.strut(tool, place * last, place * point, 0.05, 0.05, FRAME)
		last = point
	for side: float in [-1.0, 1.0]:
		var foot := Vector3(RIB_HALF_M * 0.6, 0.0, side * RIB_HALF_M)
		VertexShapes.strut(tool, place * foot, place * (foot + Vector3(RIB_ARM_M, 0.0, side * 0.03)), 0.045, 0.045, FRAME)
