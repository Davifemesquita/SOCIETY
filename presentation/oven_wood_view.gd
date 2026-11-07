class_name OvenWoodView
extends Node3D
## Fase 213: a lenha da padaria. Em cada padaria, ao lado da boca do forno da Fase 137 (`FurnaceGlowView.mouth`), ALONG_M ao longo
## da parede para o lado de +x da boca, encostada nela, se a célula do lado está livre (com um vizinho encostado, entraria na
## parede dele): a pilha de achas de lenha miúda, em fiadas, e a pá de forno de cabo comprido de pé, encostada na parede ao lado
## (`wood_mesh`). No referencial da boca (o +z para fora da parede); um MultiMesh; nada no save; refeito na obra, na demolição e
## ao trocar de mundo.

const BAKERY := &"bakery"
## Do meio da boca até o meio da pilha, ao longo da parede.
const ALONG_M := 1.25
const LENGTH_M := 0.9
const COURSES := 5
const LOG_M := 0.32
const LOG_R_M := 0.045
const BARK := Color(0.38, 0.27, 0.18)
const SPLIT := Color(0.72, 0.58, 0.4)
const PEEL_WOOD := Color(0.55, 0.42, 0.28)

var _simulation: Simulation
var _piles := MultiMeshInstance3D.new()
## Os lugares (no referencial da boca: o pé na parede, o +z para fora) (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	_piles.name = "OvenWood"
	_piles.multimesh = MultiMesh.new()
	_piles.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_piles.multimesh.mesh = wood_mesh()
	_piles.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_piles.material_override = material
	add_child(_piles)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
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
	for id: int in world.building_ids():
		var found: Variant = spot(_simulation, world.building(id))
		if found is Transform3D:
			var place: Transform3D = found
			places.append(place)
	_piles.multimesh.instance_count = places.size()
	for i: int in places.size():
		_piles.multimesh.set_instance_transform(i, places[i])


## O lugar da lenha da padaria (o referencial da boca do forno), ou null.
static func spot(simulation: Simulation, record: BuildingRecord) -> Variant:
	if record == null or record.def_id != BAKERY:
		return null
	var found: Variant = FurnaceGlowView.mouth(simulation, record)
	if not found is Transform3D:
		return null
	var mouth: Transform3D = found
	var grid := simulation.world.island(record.island_id)
	var point := mouth * Vector3(ALONG_M, 0.0, 0.0)
	# a célula do lado tem de estar livre: com o vizinho encostado, a lenha entraria na parede dele
	var outside := grid.world_to_cell(mouth * Vector3(ALONG_M, 0.0, grid.cell_size * 0.5))
	if not grid.in_bounds(outside) or grid.building_at(outside) != 0:
		return null
	var place := Transform3D(mouth.basis, Vector3(point.x, maxf(grid.height_at(point.x, point.z), mouth.origin.y - 0.6), point.z))
	return place


## A lenha com o meio da pilha na parede (z = 0) e o pé no chão: COURSES fiadas de achas de LOG_M, de ponta para fora, alternando a
## casca e o miolo, sob uma tábua; e a pá de forno de pé na ponta da pilha, encostada na parede.
static func wood_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := LENGTH_M * 0.5
	var per_course := int(LENGTH_M / (LOG_R_M * 2.1))
	for c: int in COURSES:
		var y := LOG_R_M + c * LOG_R_M * 1.8
		for k: int in per_course:
			var x := -half + LOG_R_M + k * (LENGTH_M - LOG_R_M * 2.0) / maxf(per_course - 1, 1)
			var z0 := 0.04
			var color := BARK if (k + c) % 3 != 0 else SPLIT
			VertexShapes.cylinder(tool, Vector3(x, y, z0), Vector3(x, y, z0 + LOG_M), LOG_R_M, color, 5)
			# a ponta cortada à mostra, mais clara
			VertexShapes.cylinder(tool, Vector3(x, y, z0 + LOG_M), Vector3(x, y, z0 + LOG_M + 0.004), LOG_R_M * 0.8, SPLIT, 5)
	var top := LOG_R_M + COURSES * LOG_R_M * 1.8
	VertexShapes.box(tool, Vector3(0.0, top + 0.01, LOG_M * 0.5 + 0.04), Vector3(half + 0.05, 0.015, LOG_M * 0.5 + 0.04), PEEL_WOOD)
	# a pá: o cabo comprido de pé, inclinado contra a parede, e a pá chata e larga no pé
	var foot := Vector3(half + 0.22, 0.02, 0.32)
	var head := Vector3(half + 0.22, 1.85, 0.04)
	VertexShapes.strut(tool, foot + Vector3(0.0, 0.32, -0.02), head, 0.016, 0.016, PEEL_WOOD)
	VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.RIGHT, -0.16), foot + Vector3(0.0, 0.16, -0.02)),
			Vector3(0.15, 0.17, 0.008), PEEL_WOOD.lightened(0.1))
	tool.generate_normals()
	return tool.commit()
