class_name FirePumpView
extends Node3D
## Fase 220: a bomba de incêndio no quartel. Em cada quartel de bombeiros, nas duas células do meio de um lado — o de −X do
## modelo, depois o de +X e por fim o de trás —, pelo `SideYard` da Fase 219 e fora dos pátios de lado de antes (`sites`): a
## bomba de mão sobre rodas, de caixa vermelha, com os dois cilindros de latão e a câmara de ar, os dois braços compridos dos
## bombeadores e o timão; ao lado, o carretel da mangueira em duas rodas; na parede, a escada deitada nos ganchos e a fileira de
## baldes de couro numa trave (`pump_mesh`, no meio das duas células). O recheio e as bombas d'água deixam as células limpas
## (`cells`). Um MultiMesh; nada no save; refeito na obra, na demolição, na estrada, no trilho e ao trocar de mundo.

const KINDS: Array[StringName] = [&"fire_station"]
const ORDER: Array[Vector2i] = [SideYard.MINUS_X, SideYard.PLUS_X, SideYard.BACK]
## A bomba: o meio da caixa, as meias medidas e os raios das rodas de trás e da frente.
const BODY_AT := Vector3(-0.55, 0.78, -0.25)
const BODY_HALF := Vector3(0.62, 0.26, 0.3)
const REAR_R := 0.48
const FRONT_R := 0.36
const TRACK_M := 0.42
const HANDLE_M := 1.38
## O carretel da mangueira: o meio no chão em x e o raio das rodas.
const REEL_X := 1.35
const REEL_R := 0.42
const BUCKETS := 4
const RED := Color(0.6, 0.15, 0.11)
const RED_DARK := Color(0.42, 0.1, 0.08)
const BRASS := Color(0.7, 0.5, 0.18)
const WOOD := Color(0.5, 0.38, 0.25)
const WOOD_DARK := Color(0.34, 0.25, 0.17)
const IRON := Color(0.2, 0.2, 0.22)
const HOSE := Color(0.26, 0.18, 0.12)
const LEATHER := Color(0.32, 0.19, 0.1)

var _simulation: Simulation
var _pumps := MultiMeshInstance3D.new()
## Os lugares (o meio entre as duas células no chão, o +z para longe da parede) (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.7
	_pumps.name = "FirePumps"
	_pumps.multimesh = MultiMesh.new()
	_pumps.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_pumps.multimesh.mesh = pump_mesh()
	_pumps.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_pumps.material_override = material
	add_child(_pumps)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func pump_count() -> int:
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
	_pumps.multimesh.instance_count = places.size()
	for i: int in places.size():
		_pumps.multimesh.set_instance_transform(i, places[i])


## As bombas da ilha: id do quartel → [as duas células, o lado da área para onde elas ficam] (`SideYard.pick`), fora dos pátios
## de lado de antes (tábuas, carvão e escola).
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	var taken: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in PlaygroundView.cells(world, data, island_id):
		taken[cell] = true
	for cell: Vector2i in CoalHeapView.cells(world, data, island_id):
		taken[cell] = true
	for cell: Vector2i in PlankStackView.cells(world, data, island_id):
		taken[cell] = true
	return SideYard.pick(world, data, island_id, KINDS, ORDER, taken)


## As células das bombas da ilha (o recheio e as bombas d'água as deixam limpas) → o id do quartel.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	return SideYard.cells_of(sites(world, data, island_id))


## A bomba, o carretel, a escada e os baldes com o meio entre as duas células na origem (o pé no chão), a parede do quartel em −z
## (a uma meia célula): a bomba na metade de −x, de frente para +x, e o carretel na de +x.
static func pump_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# a caixa vermelha com a beira de cima mais escura, nas duas rodas de trás e nas duas da frente
	VertexShapes.box(tool, BODY_AT, BODY_HALF, RED)
	VertexShapes.box(tool, BODY_AT + Vector3(0.0, BODY_HALF.y, 0.0), Vector3(BODY_HALF.x + 0.03, 0.03, BODY_HALF.z + 0.03),
			RED_DARK)
	var rear_x := BODY_AT.x - BODY_HALF.x + 0.15
	var front_x := BODY_AT.x + BODY_HALF.x - 0.05
	for side: float in [-1.0, 1.0]:
		_wheel(tool, Vector3(rear_x, REAR_R, BODY_AT.z + side * TRACK_M), REAR_R, side)
		_wheel(tool, Vector3(front_x, FRONT_R, BODY_AT.z + side * TRACK_M), FRONT_R, side)
	VertexShapes.strut(tool, Vector3(rear_x, REAR_R, BODY_AT.z - TRACK_M), Vector3(rear_x, REAR_R, BODY_AT.z + TRACK_M), 0.025,
			0.025, IRON)
	VertexShapes.strut(tool, Vector3(front_x, FRONT_R, BODY_AT.z - TRACK_M), Vector3(front_x, FRONT_R, BODY_AT.z + TRACK_M),
			0.025, 0.025, IRON)
	# os dois cilindros de latão e a câmara de ar entre eles
	var deck := BODY_AT.y + BODY_HALF.y
	for dx: float in [-0.22, 0.22]:
		VertexShapes.cylinder(tool, Vector3(BODY_AT.x + dx, deck, BODY_AT.z), Vector3(BODY_AT.x + dx, deck + 0.3, BODY_AT.z), 0.07,
				BRASS, 10)
	VertexShapes.cylinder(tool, Vector3(BODY_AT.x, deck, BODY_AT.z), Vector3(BODY_AT.x, deck + 0.42, BODY_AT.z), 0.09, BRASS, 10)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.09, 0.07, 0.09)), Vector3(BODY_AT.x, deck + 0.42,
			BODY_AT.z)), BRASS)
	# os braços dos bombeadores: duas varas compridas dos dois lados, no eixo sobre a caixa
	var pivot_y := deck + 0.36
	for side: float in [-1.0, 1.0]:
		var z := BODY_AT.z + side * (BODY_HALF.z + 0.06)
		VertexShapes.strut(tool, Vector3(BODY_AT.x, deck, z), Vector3(BODY_AT.x, pivot_y, z), 0.025, 0.025, IRON)
		VertexShapes.strut(tool, Vector3(BODY_AT.x - HANDLE_M * 0.5, pivot_y - 0.06, z), Vector3(BODY_AT.x + HANDLE_M * 0.5,
				pivot_y + 0.06, z), 0.03, 0.03, WOOD)
	for end: float in [-1.0, 1.0]:
		var x := BODY_AT.x + end * HANDLE_M * 0.5
		VertexShapes.strut(tool, Vector3(x, pivot_y + end * 0.06, BODY_AT.z - BODY_HALF.z - 0.06), Vector3(x, pivot_y + end * 0.06,
				BODY_AT.z + BODY_HALF.z + 0.06), 0.022, 0.022, WOOD)
	# o timão saindo da frente até o chão
	VertexShapes.strut(tool, Vector3(front_x + 0.05, FRONT_R, BODY_AT.z), Vector3(front_x + 0.62, 0.06, BODY_AT.z), 0.03, 0.03,
			WOOD_DARK)
	# o carretel da mangueira: duas rodas, o eixo e o tambor com a mangueira enrolada
	for side: float in [-1.0, 1.0]:
		_wheel(tool, Vector3(REEL_X, REEL_R, BODY_AT.z + side * 0.36), REEL_R, side)
	VertexShapes.cylinder(tool, Vector3(REEL_X, REEL_R, BODY_AT.z - 0.3), Vector3(REEL_X, REEL_R, BODY_AT.z + 0.3), 0.22, HOSE, 12)
	for k: int in 5:
		var z := BODY_AT.z - 0.24 + k * 0.12
		VertexShapes.cylinder(tool, Vector3(REEL_X, REEL_R, z - 0.02), Vector3(REEL_X, REEL_R, z + 0.02), 0.235, HOSE.darkened(0.25),
				12)
	VertexShapes.strut(tool, Vector3(REEL_X - 0.05, REEL_R, BODY_AT.z), Vector3(REEL_X + 0.55, 0.06, BODY_AT.z), 0.025, 0.025,
			WOOD_DARK)
	# na parede: a escada deitada nos ganchos e a trave com os baldes de couro
	var wall := -0.96
	for y: float in [2.12, 2.48]:
		VertexShapes.strut(tool, Vector3(-1.85, y, wall), Vector3(0.55, y, wall), 0.03, 0.025, WOOD)
	for k: int in 9:
		var x := -1.7 + k * 0.28
		VertexShapes.strut(tool, Vector3(x, 2.12, wall), Vector3(x, 2.48, wall), 0.014, 0.014, WOOD_DARK)
	VertexShapes.strut(tool, Vector3(0.75, 1.75, wall), Vector3(1.85, 1.75, wall), 0.03, 0.03, WOOD_DARK)
	for k: int in BUCKETS:
		var at := Vector3(0.88 + k * 0.28, 1.42, wall + 0.12)
		VertexShapes.cylinder(tool, at, at + Vector3(0.0, 0.26, 0.0), 0.1, LEATHER, 10)
		VertexShapes.cylinder(tool, at + Vector3(0.0, 0.24, 0.0), at + Vector3(0.0, 0.27, 0.0), 0.11, LEATHER.darkened(0.3), 10)
	tool.generate_normals()
	return tool.commit()


## Uma roda de raios no plano x-y com o eixo em z: o aro em doze lanços, seis raios e o cubo; side diz para que lado fica o cubo.
static func _wheel(tool: SurfaceTool, center: Vector3, radius: float, side: float) -> void:
	var rim := 12
	for k: int in rim:
		var a0 := TAU * k / rim
		var a1 := TAU * (k + 1) / rim
		VertexShapes.strut(tool, center + Vector3(cos(a0), sin(a0), 0.0) * radius, center + Vector3(cos(a1), sin(a1), 0.0) * radius,
				0.022, 0.02, WOOD_DARK)
	for k: int in 6:
		var angle := TAU * k / 6.0 + 0.2
		VertexShapes.strut(tool, center, center + Vector3(cos(angle), sin(angle), 0.0) * radius, 0.012, 0.012, WOOD)
	VertexShapes.cylinder(tool, center - Vector3(0.0, 0.0, 0.05 * side), center + Vector3(0.0, 0.0, 0.07 * side), 0.06, IRON, 8)
