class_name GlassCrateView
extends Node3D
## Fase 248: os caixotes de vidro. Em cada vidraria e janelaria, nas duas células do meio de um lado — o de −X do modelo, depois o de
## trás e por fim o de +X (a boca do forno da vidraria, Fase 137, fica no +X) —, pelo `SideYard` e fora do carrinho de mão da Fase
## 172 (`sites`): o cavalete em A com as chapas de vidro de pé encostadas dos dois lados e os caixotes de ripas com palha, as
## vidraças saindo por cima, dois no chão e um em cima (`crate_mesh`, no meio das duas células). O recheio e as bombas deixam as
## células limpas (`cells`). Um MultiMesh; nada no save; refeito na obra, na demolição, na estrada, no trilho e ao trocar de mundo.

const KINDS: Array[StringName] = [&"glassworks", &"window_works"]
const ORDER: Array[Vector2i] = [SideYard.MINUS_X, SideYard.BACK, SideYard.PLUS_X]
## O cavalete: o meio em x, o comprimento e a altura; as chapas: as meias medidas e quantas de cada lado; o caixote: as meias
## medidas.
const RACK_X := -0.9
const RACK_M := 1.4
const RACK_H := 1.25
const PANE_HALF := Vector3(0.55, 0.5, 0.008)
const PANES := 3
const CRATE_HALF := Vector3(0.28, 0.22, 0.22)
const WOOD := Color(0.5, 0.38, 0.25)
const WOOD_DARK := Color(0.38, 0.28, 0.18)
const STRAW := Color(0.82, 0.7, 0.4)
const GLASS := Color(0.7, 0.84, 0.84)

var _simulation: Simulation
var _crates := MultiMeshInstance3D.new()
## Os lugares (o meio entre as duas células no chão, o +z para longe da parede) (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.55
	_crates.name = "GlassCrates"
	_crates.multimesh = MultiMesh.new()
	_crates.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_crates.multimesh.mesh = crate_mesh()
	_crates.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_crates.material_override = material
	add_child(_crates)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func crate_count() -> int:
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
	_crates.multimesh.instance_count = places.size()
	for i: int in places.size():
		_crates.multimesh.set_instance_transform(i, places[i])


## Os pátios da ilha: id da oficina → [as duas células, o lado da área para onde elas ficam] (`SideYard.pick`), fora do carrinho
## de mão.
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	return SideYard.remember(world, "glass_crates/%d" % island_id, _search.bind(world, data, island_id))


static func _search(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	var taken: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in WheelbarrowView.cells(world, data, island_id):
		taken[cell] = true
	return SideYard.pick(world, data, island_id, KINDS, ORDER, taken)


## As células dos pátios da ilha (o recheio e as bombas as deixam limpas) → o id da oficina.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	return SideYard.cells_of(sites(world, data, island_id))


## O pátio com o meio entre as duas células na origem (o pé no chão), a parede da oficina em −z (a uma meia célula): o cavalete em
## A ao longo de x na metade de −x, com as chapas encostadas dos dois lados, e os caixotes com palha e vidraças na de +x.
static func crate_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rack_z := -0.4
	VertexShapes.box(tool, Vector3(RACK_X, 0.04, rack_z), Vector3(RACK_M * 0.5, 0.04, 0.06), WOOD_DARK)
	for x: float in [RACK_X - RACK_M * 0.45, RACK_X + RACK_M * 0.45]:
		for side: float in [-1.0, 1.0]:
			VertexShapes.strut(tool, Vector3(x, 0.0, rack_z + side * 0.42), Vector3(x, RACK_H, rack_z), 0.03, 0.03, WOOD)
	VertexShapes.box(tool, Vector3(RACK_X, RACK_H - 0.02, rack_z), Vector3(RACK_M * 0.5, 0.03, 0.03), WOOD)
	# as chapas: de pé no pé do cavalete, deitadas contra ele, cada uma um pouco mais para fora
	for side: float in [-1.0, 1.0]:
		for k: int in PANES:
			var lean := -side * (0.3 - 0.04 * k)
			var foot := Vector3(RACK_X + 0.04 * (k - 1), 0.0, rack_z + side * (0.3 + 0.03 * k))
			var place := Transform3D(Basis(Vector3.RIGHT, lean), foot) * Transform3D(Basis.IDENTITY, Vector3(0.0, PANE_HALF.y, 0.0))
			VertexShapes.oriented_box(tool, place, PANE_HALF, GLASS)
	# os caixotes: dois no chão e um em cima, cada um com a palha e duas vidraças saindo por cima
	for at: Vector3 in [Vector3(0.75, 0.0, -0.45), Vector3(1.4, 0.0, -0.4), Vector3(1.05, CRATE_HALF.y * 2.0, -0.42)]:
		_crate(tool, at)
	tool.generate_normals()
	return tool.commit()


## Um caixote de ripas com o pé em at: o corpo, as ripas mais escuras em volta, a palha e duas vidraças saindo por cima.
static func _crate(tool: SurfaceTool, at: Vector3) -> void:
	VertexShapes.box(tool, at + Vector3(0.0, CRATE_HALF.y, 0.0), CRATE_HALF, WOOD)
	for y: float in [0.06, CRATE_HALF.y * 2.0 - 0.06]:
		VertexShapes.box(tool, at + Vector3(0.0, y, 0.0), CRATE_HALF + Vector3(0.012, -CRATE_HALF.y + 0.03, 0.012), WOOD_DARK)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(CRATE_HALF.x * 0.9, 0.06, CRATE_HALF.z * 0.9)),
			at + Vector3(0.0, CRATE_HALF.y * 2.0, 0.0)), STRAW)
	for k: int in 2:
		VertexShapes.box(tool, at + Vector3(-0.08 + 0.16 * k, CRATE_HALF.y * 2.0 + 0.08, 0.0), Vector3(0.006, 0.14,
				CRATE_HALF.z * 0.8), GLASS)
