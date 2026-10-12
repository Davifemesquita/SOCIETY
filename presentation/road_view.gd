class_name RoadView
extends MultiMeshInstance3D
## Estradas de terra como ladrilhos num MultiMesh, refeito quando a rede muda.

const DIRT_COLOR := Color(0.55, 0.45, 0.33)
const THICKNESS_M := 0.08

var _simulation: Simulation
var _cell_size: float


func setup(simulation: Simulation, cell_size: float) -> void:
	_simulation = simulation
	_cell_size = cell_size
	var tile := BoxMesh.new()
	tile.size = Vector3(cell_size, THICKNESS_M, cell_size)
	var material := StandardMaterial3D.new()
	material.albedo_color = DIRT_COLOR
	material.roughness = 1.0
	tile.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = tile
	EventBus.roads_changed.connect(func(_island_id: int) -> void: rebuild())
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func rebuild() -> void:
	var cells := _simulation.world.island(Simulation.MAIN_ISLAND).road_cells()
	multimesh.instance_count = cells.size()
	for i: int in cells.size():
		var position := GridSpace.cell_center(cells[i], _cell_size) + Vector3(0.0, THICKNESS_M * 0.5, 0.0)
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, position))


func tile_count() -> int:
	return multimesh.instance_count
