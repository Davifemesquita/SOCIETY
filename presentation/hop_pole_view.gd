class_name HopPoleView
extends Node3D
## Fase 244: as estacas de lúpulo. Em cada fazenda de lúpulo, nas duas células do meio de um lado — o de +X do modelo, depois o de
## trás e por fim o de −X (as colmeias da Fase 190 preferem o −X, e o silo da Fase 117 fica atrás) —, pelo `SideYard` e fora das
## colmeias e do silo (`sites`): dois cavaletes em X com o feixe de estacas compridas deitado por cima, umas mais finas, outras
## mais grossas, cada uma num tom, e um feixe amarrado encostado no cavalete do canto (`pole_mesh`, no meio das duas células). O
## recheio e as bombas deixam as células limpas (`cells`). Um MultiMesh; nada no save; refeito na obra, na demolição, na estrada,
## no trilho e ao trocar de mundo.

const KINDS: Array[StringName] = [&"hop_farm"]
const ORDER: Array[Vector2i] = [SideYard.PLUS_X, SideYard.BACK, SideYard.MINUS_X]
## As estacas: o comprimento, quantas no feixe deitado e quantas no encostado; o cavalete: a altura do cruzamento.
const POLE_M := 3.6
const LYING := 14
const LEANING := 7
const TRESTLE_M := 0.75
const POLE_COLORS: Array[Color] = [Color(0.5, 0.4, 0.28), Color(0.58, 0.47, 0.33), Color(0.44, 0.35, 0.24)]
const WOOD := Color(0.38, 0.29, 0.2)
const TWINE := Color(0.7, 0.62, 0.45)

var _simulation: Simulation
var _poles := MultiMeshInstance3D.new()
## Os lugares (o meio entre as duas células no chão, o +z para longe da parede) (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	_poles.name = "HopPoles"
	_poles.multimesh = MultiMesh.new()
	_poles.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_poles.multimesh.mesh = pole_mesh()
	_poles.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_poles.material_override = material
	add_child(_poles)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func pole_count() -> int:
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
	_poles.multimesh.instance_count = places.size()
	for i: int in places.size():
		_poles.multimesh.set_instance_transform(i, places[i])


## Os feixes da ilha: id da fazenda → [as duas células, o lado da área para onde elas ficam] (`SideYard.pick`), fora das colmeias
## e do silo.
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	return SideYard.remember(world, "hop_poles/%d" % island_id, _search.bind(world, data, island_id))


static func _search(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	var taken: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in BeehiveView.cells(world, data, island_id):
		taken[cell] = true
	for cell: Vector2i in FarmSiloView.cells(world, data, island_id):
		taken[cell] = true
	return SideYard.pick(world, data, island_id, KINDS, ORDER, taken)


## As células dos feixes da ilha (o recheio e as bombas as deixam limpas) → o id da fazenda.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	return SideYard.cells_of(sites(world, data, island_id))


## Os feixes com o meio entre as duas células na origem (o pé no chão), a parede da fazenda em −z (a uma meia célula): os dois
## cavaletes em X, as estacas deitadas ao longo de x no vão deles, em duas camadas, e o feixe amarrado de pé, encostado na parede
## no canto de +x.
static func pole_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x: float in [-1.05, 1.05]:
		for lean: float in [-1.0, 1.0]:
			VertexShapes.strut(tool, Vector3(x, 0.0, -0.1 + lean * 0.45), Vector3(x, TRESTLE_M + 0.25, -0.1 - lean * 0.2), 0.03,
					0.03, WOOD)
	# as estacas deitadas no vão dos cavaletes (o X se cruza a TRESTLE_M), em duas camadas
	for k: int in LYING:
		var layer := 0 if k < LYING - 5 else 1
		var index := k if layer == 0 else k - (LYING - 5)
		var count := LYING - 5 if layer == 0 else 5
		var z := -0.1 + (index - (count - 1) * 0.5) * 0.075
		var y := TRESTLE_M - 0.02 + layer * 0.07
		var radius := 0.03 + 0.008 * (k % 3)
		var shift := 0.12 * float(posmod(k * 5, 7) - 3) / 3.0
		VertexShapes.cylinder(tool, Vector3(-POLE_M * 0.5 + shift, y + radius, z), Vector3(POLE_M * 0.5 + shift, y + radius, z),
				radius, POLE_COLORS[k % 3], 5)
	# o feixe de pé, amarrado com duas voltas de barbante, encostado na parede no canto de +x
	var foot := Vector3(1.6, 0.0, -0.6)
	var top := Vector3(1.5, POLE_M * 0.9, -0.88)
	for k: int in LEANING:
		var angle := TAU * k / LEANING
		var spread := Vector3(cos(angle), 0.0, sin(angle)) * 0.06
		VertexShapes.cylinder(tool, foot + spread * 1.6, top + spread, 0.028, POLE_COLORS[(k + 1) % 3], 5)
	for t: float in [0.3, 0.7]:
		var at := foot.lerp(top, t)
		VertexShapes.cylinder(tool, at - Vector3(0.0, 0.02, 0.0), at + Vector3(0.0, 0.02, 0.0), 0.11, TWINE, 8)
	tool.generate_normals()
	return tool.commit()
