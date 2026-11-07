class_name WinePressView
extends Node3D
## Fase 240: o lagar no vinhedo. Em cada vinhedo, nas duas células do meio de um lado — o de +X do modelo, depois o de trás e por
## fim o de −X (as colmeias da Fase 190 preferem o −X, e o silo da Fase 117 fica atrás) —, pelo `SideYard` e fora das colmeias e
## do silo (`sites`): a tina larga de pisar uvas, de aduelas com os arcos de ferro e o mosto roxo, a prensa de fuso (o estrado, o
## cesto de ripas, os dois esteios com a trave, o fuso de ferro com a barra) e dois cestos de uva (`press_mesh`, no meio das duas
## células). O recheio e as bombas deixam as células limpas (`cells`). Um MultiMesh; nada no save; refeito na obra, na demolição,
## na estrada, no trilho e ao trocar de mundo.

const KINDS: Array[StringName] = [&"vineyard"]
const ORDER: Array[Vector2i] = [SideYard.PLUS_X, SideYard.BACK, SideYard.MINUS_X]
## A tina: o raio e a altura; a prensa: a meia largura do estrado, o raio e a altura do cesto e a altura dos esteios.
const TUB_R := 0.72
const TUB_H := 0.55
const BED_HALF := 0.48
const BASKET_R := 0.34
const BASKET_H := 0.5
const POST_H := 1.65
const STAVES := 12
const WOOD := Color(0.46, 0.33, 0.22)
const WOOD_DARK := Color(0.33, 0.23, 0.15)
const IRON := Color(0.22, 0.22, 0.23)
const MUST := Color(0.46, 0.1, 0.22)
const GRAPE := Color(0.24, 0.1, 0.26)
const WICKER := Color(0.6, 0.48, 0.3)

var _simulation: Simulation
var _presses := MultiMeshInstance3D.new()
## Os lugares (o meio entre as duas células no chão, o +z para longe da parede) (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.85
	_presses.name = "WinePresses"
	_presses.multimesh = MultiMesh.new()
	_presses.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_presses.multimesh.mesh = press_mesh()
	_presses.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_presses.material_override = material
	add_child(_presses)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func press_count() -> int:
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
	_presses.multimesh.instance_count = places.size()
	for i: int in places.size():
		_presses.multimesh.set_instance_transform(i, places[i])


## Os lagares da ilha: id do vinhedo → [as duas células, o lado da área para onde elas ficam] (`SideYard.pick`), fora das colmeias
## e do silo.
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	return SideYard.remember(world, "wine_press/%d" % island_id, _search.bind(world, data, island_id))


static func _search(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	var taken: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in BeehiveView.cells(world, data, island_id):
		taken[cell] = true
	for cell: Vector2i in FarmSiloView.cells(world, data, island_id):
		taken[cell] = true
	return SideYard.pick(world, data, island_id, KINDS, ORDER, taken)


## As células dos lagares da ilha (o recheio e as bombas as deixam limpas) → o id do vinhedo.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	return SideYard.cells_of(sites(world, data, island_id))


## O lagar com o meio entre as duas células na origem (o pé no chão), a parede do vinhedo em −z (a uma meia célula): a tina de
## pisar na metade de −x, a prensa de fuso na de +x e os dois cestos de uva na frente.
static func press_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# a tina larga de aduelas, com os dois arcos de ferro, o mosto roxo e uns cachos boiando
	var tub := Vector3(-0.95, 0.0, -0.05)
	for k: int in STAVES:
		var angle := TAU * (k + 0.5) / STAVES
		var at := tub + Vector3(cos(angle) * TUB_R, TUB_H * 0.5, sin(angle) * TUB_R)
		VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.UP, -angle), at), Vector3(0.03, TUB_H * 0.5,
				TUB_R * PI / STAVES), WOOD if k % 2 == 0 else WOOD_DARK)
	for y: float in [0.12, TUB_H - 0.1]:
		VertexShapes.cylinder(tool, tub + Vector3(0.0, y, 0.0), tub + Vector3(0.0, y + 0.04, 0.0), TUB_R + 0.035, IRON, STAVES)
	VertexShapes.cylinder(tool, tub + Vector3(0.0, 0.05, 0.0), tub + Vector3(0.0, TUB_H - 0.08, 0.0), TUB_R - 0.02, MUST, STAVES)
	for k: int in 4:
		var angle := TAU * k / 4.0 + 0.6
		PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.13, 0.05, 0.1)), tub + Vector3(cos(angle) * 0.35,
				TUB_H - 0.06, sin(angle) * 0.35)), GRAPE)
	# a prensa de fuso: o estrado, o cesto de ripas, os esteios com a trave, o fuso, o bloco de apertar e a barra
	var press := Vector3(0.95, 0.0, -0.2)
	VertexShapes.box(tool, press + Vector3(0.0, 0.08, 0.0), Vector3(BED_HALF, 0.08, BED_HALF), WOOD_DARK)
	for k: int in 10:
		var angle := TAU * k / 10.0
		VertexShapes.box(tool, press + Vector3(cos(angle) * BASKET_R, 0.16 + BASKET_H * 0.5, sin(angle) * BASKET_R),
				Vector3(0.025, BASKET_H * 0.5, 0.025), WOOD)
	VertexShapes.cylinder(tool, press + Vector3(0.0, 0.17, 0.0), press + Vector3(0.0, 0.16 + BASKET_H * 0.85, 0.0),
			BASKET_R - 0.03, MUST, 10)
	VertexShapes.box(tool, press + Vector3(0.0, 0.16 + BASKET_H + 0.06, 0.0), Vector3(BASKET_R, 0.06, BASKET_R), WOOD)
	for side: float in [-1.0, 1.0]:
		VertexShapes.box(tool, press + Vector3(side * (BED_HALF - 0.05), POST_H * 0.5, 0.0), Vector3(0.06, POST_H * 0.5, 0.07),
				WOOD_DARK)
	VertexShapes.box(tool, press + Vector3(0.0, POST_H - 0.08, 0.0), Vector3(BED_HALF + 0.04, 0.08, 0.09), WOOD_DARK)
	VertexShapes.cylinder(tool, press + Vector3(0.0, 0.16 + BASKET_H + 0.12, 0.0), press + Vector3(0.0, POST_H + 0.12, 0.0), 0.05,
			IRON, 6)
	VertexShapes.strut(tool, press + Vector3(-0.55, POST_H + 0.05, 0.12), press + Vector3(0.55, POST_H + 0.05, -0.12), 0.025,
			0.025, WOOD)
	# os dois cestos de uva na frente
	for at: Vector3 in [Vector3(-0.05, 0.0, 0.6), Vector3(1.55, 0.0, 0.5)]:
		VertexShapes.cylinder(tool, at, at + Vector3(0.0, 0.32, 0.0), 0.22, WICKER, 8)
		PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.21, 0.12, 0.21)), at + Vector3(0.0, 0.33, 0.0)), GRAPE)
	tool.generate_normals()
	return tool.commit()
