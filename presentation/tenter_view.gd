class_name TenterView
extends Node3D
## Fase 208: as ramas de tecido. Em três células em fila encostadas no meio de um lado de cada tecelagem (o de trás, o de −X ou
## o de +X da frente; o primeiro em que as três são de terra, sem prédio, estrada, trilho nem árvore, fora do largo e da
## alameda, e quase planas: `sites`, como o pátio de tijolos da olaria da Fase 159), duas ramas de madeira paralelas, de
## comprido ao longo da parede, com os panos tingidos esticados entre a travessa de cima e a de baixo (`tenter_mesh`: um
## vermelho de garança e um azul de anil, presos nos ganchos). O recheio e as bombas deixam as células limpas (`cells`). Um
## MultiMesh (uma instância por tecelagem); nada no save; refeito na obra, na demolição, na estrada, no trilho e ao trocar de
## mundo.

const WEAVERY := &"weavery"
const MAX_RELIEF_M := 0.8
## A rama: o comprimento (quase as três células), a altura das travessas, os esteios e o afastamento entre as duas.
const LENGTH_M := 5.0
const TOP_M := 1.65
const BOTTOM_M := 0.45
const POSTS := 5
const SPACING_M := 0.95
const WOOD := Color(0.42, 0.31, 0.2)
const MADDER := Color(0.66, 0.16, 0.12)
const INDIGO := Color(0.17, 0.24, 0.5)
const HOOK := Color(0.2, 0.2, 0.21)

var _simulation: Simulation
var _tenters := MultiMeshInstance3D.new()
## Os lugares das ramas (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_tenters.name = "Tenters"
	_tenters.multimesh = MultiMesh.new()
	_tenters.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_tenters.multimesh.mesh = tenter_mesh()
	_tenters.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_tenters.material_override = material
	add_child(_tenters)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func tenter_count() -> int:
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
			var middle_cell: Vector2i = site[0]
			var side: Vector2i = site[1]
			var along := Vector2i(side.y, side.x)
			var corners := BuildingKit.corner_range(grid, Rect2i((middle_cell - along).min(middle_cell + along),
					Vector2i.ONE + along.abs() * 2))
			var middle := grid.cell_world(middle_cell)
			# o x das ramas ao longo da parede, o +Z para fora dela (base de mão direita: x = cima × fora)
			var x := Vector3(side.y, 0.0, -side.x)
			var z := Vector3(side.x, 0.0, side.y)
			places.append(Transform3D(Basis(x, Vector3.UP, z), Vector3(middle.x, corners.x, middle.z)))
	_tenters.multimesh.instance_count = places.size()
	for i: int in places.size():
		_tenters.multimesh.set_instance_transform(i, places[i])


## As ramas da ilha: id da tecelagem → [a célula do meio da fila, o lado da área para onde ela fica]. As três células são a do
## meio e as duas ao longo da parede.
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	var result: Dictionary[int, Array] = {}
	var grid := world.island(island_id)
	if grid == null:
		return result
	var ids: Array[int] = []
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id == island_id and record.def_id == WEAVERY:
			ids.append(id)
	if ids.is_empty():
		return result
	ids.sort()
	var taken: Dictionary[Vector2i, bool] = {}
	if not grid.flat:
		taken.merge(ForecourtView.cells(world, data, island_id))
		taken.merge(AvenueView.cells(world, island_id))
	for id: int in ids:
		var record := world.buildings[id]
		var area := Footprint.rect(record.origin, data.building(record.def_id).size, record.rotation)
		var front := Footprint.front_direction(record.rotation)
		var right := Vector2i(-front.y, front.x)
		for side: Vector2i in [-front, -right, right]:
			var middle := SpoilTipView._beside(area, side)
			var along := Vector2i(side.y, side.x)
			var cells: Array[Vector2i] = [middle - along, middle, middle + along]
			var free := true
			for cell: Vector2i in cells:
				if not grid.in_bounds(cell) or taken.has(cell):
					free = false
					break
				var index := grid.index(cell)
				# a ilha plana (testes, saves antigos) não tem chão nem árvores na grade
				if not grid.is_land(cell) or grid.occupancy[index] != 0 or grid.roads[index] != IslandGrid.Road.NONE \
						or grid.rails[index] != 0 or (not grid.flat and grid.trees[index] > 0):
					free = false
					break
			if not free:
				continue
			var corners := BuildingKit.corner_range(grid, Rect2i((middle - along).min(middle + along),
					Vector2i.ONE + along.abs() * 2))
			if corners.y - corners.x > MAX_RELIEF_M:
				continue
			for cell: Vector2i in cells:
				taken[cell] = true
			result[id] = [middle, side]
			break
	return result


## As três células de cada fila de ramas da ilha (o recheio e as bombas as deixam limpas) → o id da tecelagem.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}
	var found := sites(world, data, island_id)
	for weavery_id: int in found:
		var site: Array = found[weavery_id]
		var middle: Vector2i = site[0]
		var side: Vector2i = site[1]
		var along := Vector2i(side.y, side.x)
		for cell: Vector2i in [middle - along, middle, middle + along]:
			result[cell] = weavery_id
	return result


## As duas ramas com o pé em y = 0, de comprido em x, uma a −SPACING_M / 2 e outra a +SPACING_M / 2 em z: os esteios, a travessa
## de cima e a de baixo, o pano esticado entre elas (o de dentro vermelho, o de fora azul) e os ganchos no alto do pano.
static func tenter_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := LENGTH_M * 0.5
	for k: int in 2:
		var z := (k - 0.5) * SPACING_M
		var cloth := MADDER if k == 0 else INDIGO
		for p: int in POSTS:
			var x := lerpf(-half, half, float(p) / (POSTS - 1))
			VertexShapes.box(tool, Vector3(x, (TOP_M + 0.1) * 0.5, z), Vector3(0.05, (TOP_M + 0.1) * 0.5, 0.05), WOOD)
		for y: float in [TOP_M, BOTTOM_M]:
			VertexShapes.box(tool, Vector3(0.0, y, z), Vector3(half + 0.05, 0.035, 0.03), WOOD)
		# o pano, um pouco para fora das travessas, quase da ponta à ponta
		var a := Vector3(-half + 0.12, BOTTOM_M + 0.05, z + 0.04)
		var b := Vector3(half - 0.12, BOTTOM_M + 0.05, z + 0.04)
		var c := Vector3(half - 0.12, TOP_M - 0.05, z + 0.04)
		var d := Vector3(-half + 0.12, TOP_M - 0.05, z + 0.04)
		VertexShapes.quad(tool, a, b, c, d, cloth)
		# a ourela mais escura em cima e embaixo e os ganchos
		VertexShapes.box(tool, Vector3(0.0, TOP_M - 0.08, z + 0.045), Vector3(half - 0.12, 0.03, 0.004), cloth.darkened(0.3))
		VertexShapes.box(tool, Vector3(0.0, BOTTOM_M + 0.08, z + 0.045), Vector3(half - 0.12, 0.03, 0.004), cloth.darkened(0.3))
		for h: int in 12:
			var x := lerpf(-half + 0.2, half - 0.2, h / 11.0)
			VertexShapes.box(tool, Vector3(x, TOP_M - 0.03, z + 0.05), Vector3(0.012, 0.03, 0.012), HOOK)
		# as emendas entre as peças de pano (uma a cada lanço entre os esteios) e uma faixa mais clara no meio de cada uma
		for p: int in range(1, POSTS - 1):
			var x := lerpf(-half, half, float(p) / (POSTS - 1)) + 0.18
			VertexShapes.box(tool, Vector3(x, (TOP_M + BOTTOM_M) * 0.5, z + 0.046), Vector3(0.015, (TOP_M - BOTTOM_M) * 0.5 - 0.06,
					0.003), cloth.darkened(0.35))
		for p: int in POSTS - 1:
			var x := lerpf(-half, half, (p + 0.5) / (POSTS - 1))
			VertexShapes.box(tool, Vector3(x, (TOP_M + BOTTOM_M) * 0.5, z + 0.045), Vector3(0.09, (TOP_M - BOTTOM_M) * 0.5 - 0.1,
					0.002), cloth.lightened(0.12))
	tool.generate_normals()
	return tool.commit()
