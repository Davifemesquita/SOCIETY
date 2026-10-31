class_name LumberYardView
extends Node3D
## Fase 148: o terreiro do lenhador. Na célula encostada no meio de um lado de cada lenhador (o de +X da frente, o oposto
## ou o de trás, a primeira de terra, sem prédio, estrada nem trilho e quase plana: `cell_of`), o cavalete de serrar em xis
## com uma tora atravessada, o cepo com o machado cravado, a pilha de lenha rachada e as lascas no chão (`yard_mesh`),
## virados para o lenhador. Se a célula tem mata, a clareira da Fase 140 a corta inteira (`StumpView.cut_cells_of`), sem
## toco. O recheio deixa a célula limpa (`ScatterView.island_context`). Uma malha só para o arquipélago; nada no save;
## refeita na obra, na demolição, na estrada, no trilho e ao trocar de mundo.

const MAX_RELIEF_M := 0.8
const WOOD := Color(0.5, 0.36, 0.22)
const BARK := Color(0.33, 0.25, 0.18)
const CUT := Color(0.78, 0.65, 0.44)
const IRON := Color(0.22, 0.22, 0.23)
const CHIPS := Color(0.72, 0.6, 0.4)

var _simulation: Simulation
var _yards := MeshInstance3D.new()
var _count := 0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	_yards.name = "LumberYards"
	_yards.material_override = material
	add_child(_yards)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func yard_count() -> int:
	return _count


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	_count = 0
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var world := _simulation.world
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		var found := cells(world, _simulation.data, island_id)
		for cell: Vector2i in found:
			var toward: Vector2i = found[cell]
			var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
			var middle := grid.cell_world(cell)
			# o −Z do terreiro virado para o lenhador
			var place := Transform3D(Basis.looking_at(Vector3(toward.x, 0.0, toward.y), Vector3.UP),
					Vector3(middle.x, corners.x, middle.z))
			yard_mesh(tool, place)
			_count += 1
	if _count == 0:
		_yards.mesh = null
		return
	tool.generate_normals()
	_yards.mesh = tool.commit()


## As células dos terreiros da ilha → o lado de quem olha para o lenhador (da célula para ele).
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, Vector2i]:
	var result: Dictionary[Vector2i, Vector2i] = {}
	var grid := world.island(island_id)
	if grid == null:
		return result
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id != island_id or record.def_id != &"lumberjack":
			continue
		var found: Variant = cell_of(world, data, record)
		if found is Array:
			var pair: Array = found
			var cell: Vector2i = pair[0]
			var side: Vector2i = pair[1]
			result[cell] = -side
	return result


## [a célula do terreiro do lenhador, o lado da área para onde ela fica] ou null: encostada no meio do lado de +X da frente,
## do oposto ou do de trás, a primeira de terra, sem prédio, estrada nem trilho e com até MAX_RELIEF_M de desnível (a mata
## pode estar nela: a clareira a corta).
static func cell_of(world: WorldState, data: GameData, record: BuildingRecord) -> Variant:
	var grid := world.island(record.island_id)
	var area := Footprint.rect(record.origin, data.building(record.def_id).size, record.rotation)
	var front := Footprint.front_direction(record.rotation)
	var right := Vector2i(-front.y, front.x)
	for side: Vector2i in [right, -right, -front]:
		var cell := SpoilTipView._beside(area, side)
		if not grid.in_bounds(cell) or not grid.is_land(cell):
			continue
		var index := grid.index(cell)
		if grid.occupancy[index] != 0 or grid.roads[index] != IslandGrid.Road.NONE or grid.rails[index] != 0:
			continue
		if not grid.flat:
			var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
			if corners.y - corners.x > MAX_RELIEF_M:
				continue
		return [cell, side]
	return null


## O terreiro no referencial place (o −Z para o lenhador, o pé no chão): o cavalete em xis com a tora, o cepo com o machado,
## a pilha de lenha rachada e as lascas.
static func yard_mesh(tool: SurfaceTool, place: Transform3D) -> void:
	# cavalete: dois xis de pernas e a tora atravessada neles
	for x: float in [-0.35, 0.35]:
		for lean: float in [-1.0, 1.0]:
			VertexShapes.strut(tool, place * Vector3(x - 0.05, 0.0, -0.25 * lean + 0.2),
					place * Vector3(x + 0.05, 0.85, 0.25 * lean + 0.2), 0.03, 0.03, WOOD)
	VertexShapes.cylinder(tool, place * Vector3(-0.8, 0.72, 0.2), place * Vector3(0.8, 0.72, 0.2), 0.13, BARK, 8)
	VertexShapes.cylinder(tool, place * Vector3(0.8, 0.72, 0.2), place * Vector3(0.81, 0.72, 0.2), 0.12, CUT, 8)
	# cepo e o machado cravado
	var block := place * Vector3(-0.45, 0.0, -0.45)
	VertexShapes.cylinder(tool, block, block + place.basis * Vector3(0.0, 0.5, 0.0), 0.24, BARK, 9)
	VertexShapes.cylinder(tool, block + place.basis * Vector3(0.0, 0.5, 0.0), block + place.basis * Vector3(0.0, 0.51, 0.0),
			0.22, CUT, 9)
	var bite := block + place.basis * Vector3(0.05, 0.53, 0.0)
	VertexShapes.strut(tool, bite, bite + place.basis * Vector3(0.35, 0.45, 0.1), 0.02, 0.02, WOOD)
	VertexShapes.oriented_box(tool, Transform3D(place.basis * Basis(Vector3.BACK, 0.6), bite + place.basis * Vector3(0.0, -0.02, 0.0)),
			Vector3(0.09, 0.05, 0.015), IRON)
	# pilha de lenha rachada, em três fiadas, encostada do lado de lá
	for row: int in 3:
		for k: int in 5 - row:
			var at := Vector3(0.35 + (k - (4 - row) * 0.5) * 0.15, 0.07 + row * 0.13, -0.55)
			VertexShapes.oriented_box(tool, place * Transform3D(Basis(Vector3.BACK, 0.4 * ((k + row) % 2)), at),
					Vector3(0.06, 0.06, 0.28), CUT if (k + row) % 3 == 0 else WOOD)
	# lascas
	for k: int in 6:
		var angle := k * 1.7
		var at := Vector3(-0.45 + cos(angle) * 0.45, 0.01, -0.45 + sin(angle) * 0.4)
		VertexShapes.oriented_box(tool, place * Transform3D(Basis(Vector3.UP, angle), at), Vector3(0.06, 0.01, 0.025), CHIPS)
