class_name PastureTroughView
extends Node3D
## Fase 118: o cocho do pasto. Cada pasto ganha um cocho de madeira junto da cerca de trás (`RoadMask.trough_of`, o mesmo
## lugar da mancha de chão gasto da máscara), com a água dentro, sobre dois pés (`trough_mesh`), assentado no relevo. Um
## MultiMesh do arquipélago; nada no save; refeito na obra, na demolição e ao trocar de mundo. Só a ilha com relevo (na
## plana a máscara das estradas não pinta o chão gasto).

const LENGTH_M := 1.7
const WIDTH_M := 0.5
const HEIGHT_M := 0.42
const WALL_M := 0.05
const LEG_M := 0.12
const WOOD := Color(0.42, 0.31, 0.2)
const DARK_WOOD := Color(0.32, 0.23, 0.15)
const WATER := Color(0.28, 0.36, 0.38)

var _simulation: Simulation
var _troughs := MultiMeshInstance3D.new()
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.8
	var mesh := trough_mesh()
	mesh.surface_set_material(0, material)
	_troughs.name = "Troughs"
	_troughs.multimesh = MultiMesh.new()
	_troughs.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_troughs.multimesh.mesh = mesh
	add_child(_troughs)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func trough_count() -> int:
	return _troughs.multimesh.instance_count


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	var places := places_of(_simulation.world, _simulation.data)
	var multimesh := _troughs.multimesh
	multimesh.instance_count = places.size()
	for i: int in places.size():
		multimesh.set_instance_transform(i, places[i])
	multimesh.custom_aabb = WorldBounds.of(_simulation.config)


## O lugar de cada cocho no mundo: no meio dado pela máscara, ao longo da cerca, na altura do chão.
static func places_of(world: WorldState, data: GameData) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.def_id != &"pasture":
			continue
		var grid := world.island(record.island_id)
		if grid == null or grid.flat:
			continue
		var spot := RoadMask.trough_of(record, data.building(record.def_id), grid.cell_size)
		var x := grid.origin_m.x + spot[0].x
		var z := grid.origin_m.y + spot[0].y
		var along := Vector3(spot[1].x, 0.0, spot[1].y)
		var basis := Basis(along, Vector3.UP, along.cross(Vector3.UP))
		result.append(Transform3D(basis, Vector3(x, grid.height_at(x, z), z)))
	return result


## O cocho ao longo de x: fundo, as quatro tábuas dos lados, a água a dois terços e os dois pés de través.
static func trough_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := Vector3(LENGTH_M, HEIGHT_M, WIDTH_M) * 0.5
	var floor_y := LEG_M + WALL_M * 0.5
	VertexShapes.box(tool, Vector3(0.0, floor_y, 0.0), Vector3(half.x, WALL_M * 0.5, half.z), WOOD)
	var wall_y := LEG_M + half.y
	for side: float in [-1.0, 1.0]:
		VertexShapes.box(tool, Vector3(0.0, wall_y, side * (half.z - WALL_M * 0.5)), Vector3(half.x, half.y, WALL_M * 0.5), WOOD)
		VertexShapes.box(tool, Vector3(side * (half.x - WALL_M * 0.5), wall_y, 0.0), Vector3(WALL_M * 0.5, half.y, half.z - WALL_M),
				DARK_WOOD)
		VertexShapes.box(tool, Vector3(side * (half.x - 0.2), LEG_M * 0.5, 0.0), Vector3(0.06, LEG_M * 0.5, half.z + 0.06),
				DARK_WOOD)
	VertexShapes.box(tool, Vector3(0.0, LEG_M + HEIGHT_M * 0.66, 0.0), Vector3(half.x - WALL_M, 0.01, half.z - WALL_M), WATER)
	tool.generate_normals()
	return tool.commit()
