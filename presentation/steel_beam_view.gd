class_name SteelBeamView
extends Node3D
## Fase 243: as vigas de aço empilhadas. Em cada fábrica de vigas de aço, nas duas células do meio de um lado — o de −X do modelo,
## depois o de trás e por fim o de +X (a boca do forno da Fase 137 fica no +X) —, pelo `SideYard` e fora do carrinho de mão da
## Fase 172 (`sites`): a pilha de vigas de ferro em I ao longo da parede, em camadas sobre os dormentes de madeira, a de cima mais
## curta e uma viga solta deitada no chão na frente (`pile_mesh`, no meio das duas células). O recheio e as bombas deixam as
## células limpas (`cells`). Um MultiMesh; nada no save; refeito na obra, na demolição, na estrada, no trilho e ao trocar de mundo.

const KINDS: Array[StringName] = [&"steel_beam_works"]
const ORDER: Array[Vector2i] = [SideYard.MINUS_X, SideYard.BACK, SideYard.PLUS_X]
## A viga: o comprimento, a altura, a largura da aba e a grossura da aba e da alma; a pilha: quantas por camada, o passo e as camadas.
const BEAM_M := 3.3
const BEAM_H := 0.24
const FLANGE_W := 0.13
const FLANGE_T := 0.025
const WEB_T := 0.018
const PER_LAYER := 4
const STEP_M := 0.2
const LAYERS := 3
const SLEEPER_H := 0.1
const IRON := Color(0.34, 0.34, 0.36)
const RUST := Color(0.34, 0.22, 0.16)
const WOOD := Color(0.4, 0.3, 0.2)

var _simulation: Simulation
var _piles := MultiMeshInstance3D.new()
## Os lugares (o meio entre as duas células no chão, o +z para longe da parede) (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.7
	material.metallic = 0.4
	_piles.name = "SteelBeams"
	_piles.multimesh = MultiMesh.new()
	_piles.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_piles.multimesh.mesh = pile_mesh()
	_piles.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_piles.material_override = material
	add_child(_piles)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
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
	var world := _simulation.world
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		var found := sites(world, _simulation.data, island_id)
		for id: int in found:
			var site: Array = found[id]
			var pair: Array[Vector2i] = site[0]
			var side: Vector2i = site[1]
			places.append(SideYard.place(grid, pair, side))
	_piles.multimesh.instance_count = places.size()
	for i: int in places.size():
		_piles.multimesh.set_instance_transform(i, places[i])


## As pilhas da ilha: id da fábrica → [as duas células, o lado da área para onde elas ficam] (`SideYard.pick`), fora do carrinho
## de mão.
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	return SideYard.remember(world, "steel_beams/%d" % island_id, _search.bind(world, data, island_id))


static func _search(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	var taken: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in WheelbarrowView.cells(world, data, island_id):
		taken[cell] = true
	return SideYard.pick(world, data, island_id, KINDS, ORDER, taken)


## As células das pilhas da ilha (o recheio e as bombas as deixam limpas) → o id da fábrica.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	return SideYard.cells_of(sites(world, data, island_id))


## A pilha com o meio entre as duas células na origem (o pé no chão), a parede da fábrica em −z (a uma meia célula): os dormentes
## atravessados, as vigas ao longo de x em camadas (cada camada sobre dois dormentes, a de cima mais curta) e uma viga solta no
## chão na frente, virada um pouco.
static func pile_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var back := -0.65
	var y := 0.0
	for layer: int in LAYERS:
		var count := PER_LAYER - (1 if layer == LAYERS - 1 else 0)
		var width := (count - 1) * STEP_M
		for x: float in [-BEAM_M * 0.32, BEAM_M * 0.32]:
			VertexShapes.box(tool, Vector3(x, y + SLEEPER_H * 0.5, back + width * 0.5), Vector3(0.07, SLEEPER_H * 0.5,
					width * 0.5 + 0.12), WOOD)
		y += SLEEPER_H
		for k: int in count:
			var length := BEAM_M * (0.86 if layer == LAYERS - 1 else 1.0)
			_beam(tool, Transform3D(Basis.IDENTITY, Vector3(0.04 * (k % 2), y, back + k * STEP_M)), length,
					RUST if (k + layer) % 3 == 0 else IRON)
		y += BEAM_H
	_beam(tool, Transform3D(Basis(Vector3.UP, 0.12), Vector3(0.1, 0.0, 0.6)), BEAM_M * 0.8, RUST)
	tool.generate_normals()
	return tool.commit()


## Uma viga em I deitada ao longo de x, com o pé em place: a aba de baixo, a alma de pé e a aba de cima.
static func _beam(tool: SurfaceTool, place: Transform3D, length: float, color: Color) -> void:
	var half := length * 0.5
	VertexShapes.oriented_box(tool, place * Transform3D(Basis.IDENTITY, Vector3(0.0, FLANGE_T * 0.5, 0.0)), Vector3(half,
			FLANGE_T * 0.5, FLANGE_W * 0.5), color)
	VertexShapes.oriented_box(tool, place * Transform3D(Basis.IDENTITY, Vector3(0.0, BEAM_H * 0.5, 0.0)), Vector3(half,
			BEAM_H * 0.5 - FLANGE_T, WEB_T * 0.5), color)
	VertexShapes.oriented_box(tool, place * Transform3D(Basis.IDENTITY, Vector3(0.0, BEAM_H - FLANGE_T * 0.5, 0.0)), Vector3(half,
			FLANGE_T * 0.5, FLANGE_W * 0.5), color)
