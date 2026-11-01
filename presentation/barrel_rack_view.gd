class_name BarrelRackView
extends Node3D
## Fase 221: os barris na cervejaria. Na cervejaria, nas destilarias e na adega (os prédios dos tonéis da Fase 98), nas duas
## células do meio de um lado — o de −X do modelo, depois o de +X e por fim o de trás —, pelo `SideYard` e fora dos pátios de lado
## de antes (`sites`): a pirâmide de barris deitados (quatro, três e dois) sobre dois calços de madeira, com o fundo para fora
## da parede, e ao lado dois barris de pé, um com o funil em cima (`rack_mesh`, no meio das duas células). O recheio e as bombas
## deixam as células limpas (`cells`). Um MultiMesh; nada no save; refeito na obra, na demolição, na estrada, no trilho e ao
## trocar de mundo.

const KINDS: Array[StringName] = [&"brewery", &"distillery", &"rum_distillery", &"champagne_cellar"]
const ORDER: Array[Vector2i] = [SideYard.MINUS_X, SideYard.PLUS_X, SideYard.BACK]
## O barril: o raio do fundo, o bojo a mais no meio, o comprimento e os lados do torneado (o ângulo anda de +x para +z: as
## faces vão no sentido contrário ao do `VertexShapes.cylinder`).
const BARREL_R := 0.27
const BULGE := 0.05
const BARREL_L := 0.78
const SIDES := 12
const RINGS := 6
## A pirâmide: barris por fileira, de baixo para cima, e o meio dela em x; o calço.
const ROWS: Array[int] = [4, 3, 2]
const PILE_X := -0.6
const CHOCK_M := 0.1
const OAK := Color(0.55, 0.38, 0.22)
const HEAD := Color(0.62, 0.47, 0.3)
const HOOP := Color(0.2, 0.2, 0.22)
const CHOCK := Color(0.36, 0.27, 0.18)
const TIN := Color(0.6, 0.61, 0.63)

var _simulation: Simulation
var _racks := MultiMeshInstance3D.new()
## Os lugares (o meio entre as duas células no chão, o +z para longe da parede) (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.8
	_racks.name = "BarrelRacks"
	_racks.multimesh = MultiMesh.new()
	_racks.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_racks.multimesh.mesh = rack_mesh()
	_racks.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_racks.material_override = material
	add_child(_racks)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func rack_count() -> int:
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
	_racks.multimesh.instance_count = places.size()
	for i: int in places.size():
		_racks.multimesh.set_instance_transform(i, places[i])


## As pilhas da ilha: id do prédio → [as duas células, o lado da área para onde elas ficam] (`SideYard.pick`), fora dos pátios de
## lado de antes.
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	return SideYard.remember(world, "barrels/%d" % island_id, _search.bind(world, data, island_id))


static func _search(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	var taken: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in FirePumpView.cells(world, data, island_id):
		taken[cell] = true
	for cell: Vector2i in PlaygroundView.cells(world, data, island_id):
		taken[cell] = true
	for cell: Vector2i in CoalHeapView.cells(world, data, island_id):
		taken[cell] = true
	for cell: Vector2i in PlankStackView.cells(world, data, island_id):
		taken[cell] = true
	return SideYard.pick(world, data, island_id, KINDS, ORDER, taken)


## As células das pilhas da ilha (o recheio e as bombas as deixam limpas) → o id do prédio.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	return SideYard.cells_of(sites(world, data, island_id))


## A pirâmide e os barris de pé com o meio entre as duas células na origem (o pé no chão), a parede em −z (a uma meia célula).
static func rack_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pitch := (BARREL_R + BULGE) * 2.0
	var center_z := -1.0 + 0.08 + BARREL_L * 0.5
	var width := ROWS[0] * pitch
	# os dois calços debaixo da primeira fileira
	for dz: float in [-BARREL_L * 0.3, BARREL_L * 0.3]:
		VertexShapes.box(tool, Vector3(PILE_X, CHOCK_M * 0.5, center_z + dz), Vector3(width * 0.5 + 0.05, CHOCK_M * 0.5, 0.06),
				CHOCK)
	# os barris deitados, o fundo para fora da parede, cada fileira nos vãos da de baixo
	var lying := Basis(Vector3.RIGHT, PI * 0.5)
	var y := CHOCK_M + BARREL_R + BULGE * 0.6
	var count := 0
	for row: int in ROWS.size():
		var barrels := ROWS[row]
		for k: int in barrels:
			var x := PILE_X + (k - (barrels - 1) * 0.5) * pitch
			_barrel(tool, Transform3D(lying, Vector3(x, y, center_z - BARREL_L * 0.5)), 0.92 + 0.08 * float(posmod(count * 7, 5)) / 4.0)
			count += 1
		y += pitch * 0.866
	# os dois barris de pé, um com o funil de lata em cima
	for k: int in 2:
		var at := Vector3(1.05 + k * 0.62, 0.0, -1.0 + 0.4 + k * 0.18)
		_barrel(tool, Transform3D(Basis.IDENTITY, at), 0.96 - 0.06 * k)
		if k == 1:
			var top := at + Vector3(0.0, BARREL_L, 0.0)
			VertexShapes.cylinder(tool, top, top + Vector3(0.0, 0.12, 0.0), 0.03, TIN, 8)
			_funnel(tool, top + Vector3(0.0, 0.12, 0.0))
	tool.generate_normals()
	return tool.commit()


## Um barril com o fundo de baixo em place (o eixo em y, BARREL_L de comprido): as aduelas torneadas com o bojo, os dois fundos e
## quatro arcos de ferro; tone escurece ou clareia a madeira.
static func _barrel(tool: SurfaceTool, place: Transform3D, tone: float) -> void:
	var rings: Array[Array] = []
	for r: int in RINGS + 1:
		var t := float(r) / RINGS
		var radius := BARREL_R + BULGE * sin(PI * t)
		var ring: Array[Vector3] = []
		for s: int in SIDES:
			var angle := TAU * s / SIDES
			ring.append(Vector3(cos(angle) * radius, t * BARREL_L, sin(angle) * radius))
		rings.append(ring)
	for r: int in RINGS:
		var hoop := r == 0 or r == RINGS - 1 or r == 1 or r == RINGS - 2
		var color := HOOP if hoop and (r == 0 or r == RINGS - 1) else OAK * tone
		var low: Array[Vector3] = rings[r]
		var high: Array[Vector3] = rings[r + 1]
		for s: int in SIDES:
			var n := (s + 1) % SIDES
			VertexShapes.quad(tool, place * low[s], place * low[n], place * high[n], place * high[s], color)
	# os fundos
	var bottom: Array[Vector3] = rings[0]
	var top: Array[Vector3] = rings[RINGS]
	for s: int in SIDES:
		var n := (s + 1) % SIDES
		VertexShapes.tri(tool, place * Vector3.ZERO, place * bottom[n], place * bottom[s], HEAD * tone)
		VertexShapes.tri(tool, place * Vector3(0.0, BARREL_L, 0.0), place * top[s], place * top[n], HEAD * tone)
	# os dois arcos do meio, um pouco saltados
	for t: float in [0.3, 0.7]:
		var radius := BARREL_R + BULGE * sin(PI * t) + 0.008
		for s: int in SIDES:
			var a0 := TAU * s / SIDES
			var a1 := TAU * (s + 1) / SIDES
			var p := Vector3(cos(a0) * radius, t * BARREL_L, sin(a0) * radius)
			var q := Vector3(cos(a1) * radius, t * BARREL_L, sin(a1) * radius)
			var up := Vector3(0.0, 0.025, 0.0)
			VertexShapes.quad(tool, place * (p - up), place * (q - up), place * (q + up), place * (p + up), HOOP)


## O funil de lata, a boca em cima.
static func _funnel(tool: SurfaceTool, at: Vector3) -> void:
	for s: int in 10:
		var a0 := TAU * s / 10.0
		var a1 := TAU * (s + 1) / 10.0
		var p0 := Vector3(cos(a0), 0.0, sin(a0))
		var p1 := Vector3(cos(a1), 0.0, sin(a1))
		VertexShapes.quad(tool, at + p0 * 0.03, at + p0 * 0.13 + Vector3(0.0, 0.12, 0.0), at + p1 * 0.13 + Vector3(0.0, 0.12, 0.0),
				at + p1 * 0.03, TIN)
		VertexShapes.quad(tool, at + p0 * 0.03, at + p1 * 0.03, at + p1 * 0.13 + Vector3(0.0, 0.12, 0.0),
				at + p0 * 0.13 + Vector3(0.0, 0.12, 0.0), TIN.darkened(0.3))
