class_name BollardView
extends Node3D
## Fase 152: as balizas com corrente na beira do largo. Em cada lado de uma célula do largo calçado (Fase 109) que dá para
## uma estrada, BOLLARD_IN_M para dentro da célula, uma baliza de ferro em cada ponta e a corrente caindo em curva entre
## elas (`edges`, `bollard_mesh`, `_chain`); um lado em OPEN_EVERY fica aberto (é por onde se entra no largo), e o lado do
## poste de gás da rua também. As balizas
## das pontas que se encontram são uma só. Uma malha só para o arquipélago; nada no save; refeita na obra, na demolição, na
## estrada, na derrubada de árvores e ao trocar de mundo.

const BOLLARD_IN_M := 0.18
const BOLLARD_M := 0.62
const OPEN_EVERY := 3
## A corrente: presa CHAIN_BELOW_M abaixo do alto da baliza, caindo CHAIN_SAG_M no meio, em elos de LINK_M.
const CHAIN_BELOW_M := 0.1
const CHAIN_SAG_M := 0.16
const LINK_M := 0.07
const IRON := Color(0.13, 0.14, 0.15)
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var _simulation: Simulation
var _mesh := MeshInstance3D.new()
var _bollards := 0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.5
	material.metallic = 0.5
	_mesh.name = "Bollards"
	_mesh.material_override = material
	add_child(_mesh)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.trees_changed.connect(func(_island_id: int, _area: Rect2i) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func bollard_count() -> int:
	return _bollards


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	_bollards = 0
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var world := _simulation.world
	for island_id: int in world.islands.size():
		var feet: Dictionary[Vector2i, Vector3] = {}
		for edge: Array in edges(world, _simulation.data, island_id):
			var a: Vector3 = edge[0]
			var b: Vector3 = edge[1]
			for foot: Vector3 in [a, b]:
				feet[Vector2i(roundi(foot.x * 20.0), roundi(foot.z * 20.0))] = foot
			_chain(tool, a + Vector3.UP * (BOLLARD_M - CHAIN_BELOW_M), b + Vector3.UP * (BOLLARD_M - CHAIN_BELOW_M))
		for foot: Vector3 in feet.values():
			bollard_mesh(tool, foot)
			_bollards += 1
	if _bollards == 0:
		_mesh.mesh = null
		return
	tool.generate_normals()
	_mesh.mesh = tool.commit()


## Os lados do largo que dão para a estrada na ilha: [baliza de uma ponta, baliza da outra] no chão (mundo), BOLLARD_IN_M
## para dentro da célula do largo; um lado em OPEN_EVERY fica aberto, pelo desenho da grade.
static func edges(world: WorldState, data: GameData, island_id: int) -> Array[Array]:
	var result: Array[Array] = []
	var grid := world.island(island_id)
	if grid == null:
		return result
	for cell: Vector2i in ForecourtView.cells(world, data, island_id):
		for side: Vector2i in SIDES:
			var next := cell + side
			if not grid.in_bounds(next) or not grid.has_road(next):
				continue
			if posmod(cell.x * 3 + cell.y * 5 + side.x + side.y * 2, OPEN_EVERY) == 0:
				continue
			# o poste de gás da rua (Fase 13) fica na beira dela do lado da calçada: ali a corrente passaria por ele
			if grid.is_paved(next) and posmod(next.x + next.y * 3, LampView.LAMP_EVERY) == 0 \
					and LampView._sidewalk_side(grid, next) == -side:
				continue
			var middle := grid.cell_world(cell)
			var out := Vector3(side.x, 0.0, side.y)
			var along := Vector3(-side.y, 0.0, side.x)
			var line := middle + out * (grid.cell_size * 0.5 - BOLLARD_IN_M)
			var a := line + along * grid.cell_size * 0.5
			var b := line - along * grid.cell_size * 0.5
			a.y = grid.height_at(a.x, a.z) + ForecourtView.SLAB_LIFT_M
			b.y = grid.height_at(b.x, b.z) + ForecourtView.SLAB_LIFT_M
			result.append([a, b])
	return result


## A baliza com o pé em foot: o fuste de ferro afinando, o anel e a cabeça em bola.
static func bollard_mesh(tool: SurfaceTool, foot: Vector3) -> void:
	VertexShapes.cylinder(tool, foot + Vector3.DOWN * 0.05, foot + Vector3.UP * 0.12, 0.085, IRON, 8)
	VertexShapes.cylinder(tool, foot + Vector3.UP * 0.12, foot + Vector3.UP * (BOLLARD_M - 0.12), 0.06, IRON, 8)
	VertexShapes.cylinder(tool, foot + Vector3.UP * (BOLLARD_M - 0.16), foot + Vector3.UP * (BOLLARD_M - 0.12), 0.075, IRON, 8)
	VertexShapes.box(tool, foot + Vector3.UP * (BOLLARD_M - 0.06), Vector3(0.065, 0.065, 0.065), IRON)


## A corrente de a até b caindo em parábola, em elos alternados (deitado e em pé).
static func _chain(tool: SurfaceTool, a: Vector3, b: Vector3) -> void:
	var count := maxi(2, ceili(a.distance_to(b) / LINK_M))
	for k: int in count:
		var t0 := float(k) / count
		var t1 := float(k + 1) / count
		var p0 := a.lerp(b, t0) + Vector3.DOWN * CHAIN_SAG_M * 4.0 * t0 * (1.0 - t0)
		var p1 := a.lerp(b, t1) + Vector3.DOWN * CHAIN_SAG_M * 4.0 * t1 * (1.0 - t1)
		if k % 2 == 0:
			VertexShapes.strut(tool, p0, p1, 0.018, 0.006, IRON)
		else:
			VertexShapes.strut(tool, p0, p1, 0.006, 0.018, IRON)
