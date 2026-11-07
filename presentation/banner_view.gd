class_name BannerView
extends Node3D
## Fase 205: os estandartes na fachada. Na prefeitura, no teatro, na universidade, no museu e na escola (SERVICES), um de cada
## lado da porta, na divisa da célula dela, pendurado num braço de ferro que sai da parede abaixo do alto do segundo andar (ou
## do primeiro, no prédio de um andar): o pano comprido de rabo de andorinha na cor do prédio (COLORS), com o galão dourado nas
## beiras e o emblema no meio (`banner_mesh`, `places_of`), balançando no `shaders/banner.gdshader` com o vento. No lugar do
## modelo (`BuildingView.model_place`); um MultiMesh; nada no save; refeito na obra, na demolição e ao trocar de mundo.

const SERVICES: Array[StringName] = [&"town_hall", &"theater", &"university", &"museum", &"school"]
const COLORS: Dictionary[StringName, Color] = {&"town_hall": Color(0.62, 0.1, 0.1), &"theater": Color(0.4, 0.1, 0.42),
		&"university": Color(0.1, 0.22, 0.5), &"museum": Color(0.08, 0.36, 0.22),
		&"school": Color(0.55, 0.32, 0.08)}
## O pano: a largura, o comprimento máximo, quanto o alto fica abaixo do alto do andar e o vão mínimo acima da porta.
const WIDTH_M := 0.62
const LENGTH_M := 2.2
const BELOW_FLOOR_M := 0.35
const DOOR_CLEAR_M := 2.9
const MIN_LENGTH_M := 1.0
## O braço: quanto o pano fica para fora da parede.
const ARM_M := 0.42
const GOLD := Color(0.86, 0.68, 0.24)
const IRON := Color(0.12, 0.12, 0.13)

var _simulation: Simulation
var _banners := MultiMeshInstance3D.new()
## Cada estandarte (o meio do alto do pano, a frente para fora da fachada, o comprimento no y da base) (testes).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/banner.gdshader") as Shader
	_banners.name = "Banners"
	_banners.multimesh = MultiMesh.new()
	_banners.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_banners.multimesh.use_custom_data = true
	_banners.multimesh.mesh = banner_mesh()
	_banners.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_banners.material_override = material
	add_child(_banners)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func banner_count() -> int:
	return places.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	places.clear()
	var colors: Array[Color] = []
	var world := _simulation.world
	for id: int in world.building_ids():
		var record := world.building(id)
		if record.def_id not in SERVICES:
			continue
		for place: Transform3D in places_of(_simulation, record):
			places.append(place)
			colors.append(COLORS[record.def_id])
	var multimesh := _banners.multimesh
	multimesh.instance_count = places.size()
	for i: int in places.size():
		multimesh.set_instance_transform(i, places[i])
		var color := colors[i]
		multimesh.set_instance_custom_data(i, Color(color.r, color.g, color.b, float(i % 7) / 7.0))


## Os estandartes do prédio (no mundo): o meio do alto de cada pano, ARM_M para fora da fachada, nas duas divisas da célula da
## porta, com o y da base esticado para o comprimento que cabe entre o andar e o alto da porta. Vazio sem lugar.
static func places_of(simulation: Simulation, record: BuildingRecord) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var grid := simulation.world.island(record.island_id)
	var spec := BuildingKit.spec_for(simulation, record, grid.cell_size)
	if spec == null:
		return result
	var hall := spec.hall()
	var top := hall.floor_m() * mini(hall.floors(), 2) - BELOW_FLOOR_M
	var length := minf(LENGTH_M, top - DOOR_CLEAR_M)
	if length < MIN_LENGTH_M:
		return result
	var door := spec.hall_offset() + BuildingKit._wall_point(hall, 0, hall.door_index, 0)
	var def := simulation.def_of(record)
	var model := BuildingView.model_place(grid, record, Footprint.rect(record.origin, def.size, record.rotation))
	for side: float in [-1.0, 1.0]:
		var local := Vector3(door.x + side * spec.cell_m * 0.5, top, door.z - ARM_M)
		result.append(model * Transform3D(Basis.from_scale(Vector3(1.0, length / LENGTH_M, 1.0)), local))
	return result


## O estandarte com o meio do alto do pano na origem e o pano descendo em −y até −LENGTH_M, a frente para −z: o braço de ferro
## da parede (+z) até o pano, a vara de través, o pano de rabo de andorinha (COLOR.a = 1: a cor da instância) com o galão
## dourado nas beiras e embaixo e o emblema em losango no meio.
static func banner_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := WIDTH_M * 0.5
	var field := Color(1.0, 1.0, 1.0, 1.0)
	var gold := Color(GOLD.r, GOLD.g, GOLD.b, 0.0)
	var iron := Color(IRON.r, IRON.g, IRON.b, 0.0)
	# o braço: da parede até a vara, com a mão-francesa
	VertexShapes.strut(tool, Vector3(0.0, 0.08, ARM_M), Vector3(0.0, 0.08, 0.0), 0.018, 0.018, iron)
	VertexShapes.strut(tool, Vector3(0.0, -0.25, ARM_M), Vector3(0.0, 0.08, ARM_M * 0.35), 0.012, 0.012, iron)
	VertexShapes.strut(tool, Vector3(-half - 0.06, 0.04, 0.0), Vector3(half + 0.06, 0.04, 0.0), 0.016, 0.016, gold)
	# o pano: o corpo e o rabo de andorinha
	var body := LENGTH_M - 0.35
	var tail := LENGTH_M
	var trim := 0.05
	var inner := half - trim
	_quad(tool, Vector2(-inner, 0.0), Vector2(inner, 0.0), Vector2(inner, -body), Vector2(-inner, -body), field)
	var notch := Vector3(0.0, -body + 0.1, 0.0)
	for side: float in [-1.0, 1.0]:
		var edge := Vector3(side * inner, -body, 0.0)
		var point := Vector3(side * inner, -tail + 0.06, 0.0)
		VertexShapes.tri(tool, edge, notch, point, field)
	# o galão dourado nas beiras e no alto
	for side: float in [-1.0, 1.0]:
		var outer := Vector2(side * half, 0.0)
		var low := minf(outer.x, side * inner)
		var high := maxf(outer.x, side * inner)
		_quad(tool, Vector2(low, 0.0), Vector2(high, 0.0), Vector2(high, -tail), Vector2(low, -tail), gold)
	_quad(tool, Vector2(-half, 0.0), Vector2(half, 0.0), Vector2(half, -0.08), Vector2(-half, -0.08), gold)
	# o emblema em losango, um pouco à frente do pano
	var middle := Vector3(0.0, -body * 0.45, -0.004)
	var r := half * 0.55
	VertexShapes.quad(tool, middle + Vector3(0.0, r * 1.3, 0.0), middle + Vector3(r, 0.0, 0.0),
			middle + Vector3(0.0, -r * 1.3, 0.0), middle + Vector3(-r, 0.0, 0.0), gold)
	tool.generate_normals()
	return tool.commit()


static func _quad(tool: SurfaceTool, a: Vector2, b: Vector2, c: Vector2, d: Vector2, color: Color) -> void:
	VertexShapes.quad(tool, Vector3(a.x, a.y, 0.0), Vector3(b.x, b.y, 0.0), Vector3(c.x, c.y, 0.0), Vector3(d.x, d.y, 0.0), color)
