class_name VelocipedeView
extends Node3D
## Fase 154: o velocípede encostado. Numa casa dos artesãos (`TierDef.HouseTrim.FLOWER_BOXES`: a fachada da frente sem
## gradil, sebe nem alpendre) a cada BIKE_EVERY pelo id, um velocípede de roda grande encostado na parede da frente, na
## célula ao lado da porta (`spot`), deitado LEAN_RAD para a parede: a roda grande com os raios, a rodinha de trás, o quadro
## curvo de ferro, o guidão e o selim (`bike_mesh`). Um MultiMesh do arquipélago, no lugar do modelo da casa (com o desvio
## da variação, `BuildingView.model_place`); nada no save; refeito na obra, na demolição, na subida de classe e ao trocar de
## mundo.

const BIKE_EVERY := 4
const BIKE_REST := 1
const LEAN_RAD := 0.2
## O pé das rodas fica tanto à frente da parede.
const OUT_M := 0.32
const BIG_WHEEL_M := 0.62
const SMALL_WHEEL_M := 0.2
const WHEELBASE_M := 0.95
const SPOKES := 8
const IRON := Color(0.1, 0.1, 0.11)
const TYRE := Color(0.06, 0.06, 0.06)
const SADDLE := Color(0.32, 0.2, 0.12)
const HUB := Color(0.62, 0.6, 0.55)

var _simulation: Simulation
var _bikes := MultiMeshInstance3D.new()
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.6
	material.metallic = 0.3
	var mesh := bike_mesh()
	mesh.surface_set_material(0, material)
	_bikes.name = "Velocipedes"
	_bikes.multimesh = MultiMesh.new()
	_bikes.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_bikes.multimesh.mesh = mesh
	add_child(_bikes)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.house_upgraded.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func bike_count() -> int:
	return _bikes.multimesh.instance_count


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	var places: Array[Transform3D] = []
	var world := _simulation.world
	for id: int in world.building_ids():
		var place: Variant = spot(_simulation, world.building(id))
		if place is Transform3D:
			places.append(place)
	var multimesh := _bikes.multimesh
	multimesh.instance_count = places.size()
	for i: int in places.size():
		multimesh.set_instance_transform(i, places[i])
	multimesh.custom_aabb = WorldBounds.of(_simulation.config)


## Onde fica o velocípede da casa (mundo: o +X ao longo da parede, o +Z para dentro dela, deitado para ela), ou null: só
## nas casas dos artesãos sem pátio na frente, uma a cada BIKE_EVERY pelo id, na célula ao lado da porta.
static func spot(simulation: Simulation, record: BuildingRecord) -> Variant:
	if record == null or not record.is_house() or posmod(record.id, BIKE_EVERY) != BIKE_REST:
		return null
	var tier := simulation.data.tier(record.tier)
	if tier == null or tier.house_trim != TierDef.HouseTrim.FLOWER_BOXES:
		return null
	var grid := simulation.world.island(record.island_id)
	var spec := BuildingKit.spec_for(simulation, record, grid.cell_size)
	if spec == null or spec.court_rows > 0:
		return null
	var hall := spec.hall()
	var index := hall.door_index + 1 if hall.door_index + 1 < hall.cells.x else hall.door_index - 1
	var wall := BuildingKit._wall_point(hall, 0, index, 0)
	# a face da frente tem a normal −Z: o pé das rodas fica OUT_M para fora, e a bicicleta deita para +Z (a parede)
	var local := Transform3D(Basis(Vector3.RIGHT, LEAN_RAD), wall + Vector3(0.0, 0.0, -OUT_M))
	var def := simulation.def_of(record)
	var model := BuildingView.model_place(grid, record, Footprint.rect(record.origin, def.size, record.rotation))
	return model * local


## O velocípede com as rodas no chão (y = 0), o quadro ao longo de x (a roda grande em +x), centrado de ponta a ponta no zero: as duas rodas com o aro, o pneu,
## os raios e o cubo, o garfo e o guidão, o quadro curvo do alto da roda grande até a rodinha e o selim.
static func bike_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# centrada no zero de ponta a ponta (a roda grande passava da quina da casa)
	var shift := ((WHEELBASE_M * 0.5 + BIG_WHEEL_M) - (WHEELBASE_M * 0.5 + SMALL_WHEEL_M)) * 0.5
	var big := Vector3(WHEELBASE_M * 0.5 - shift, BIG_WHEEL_M, 0.0)
	var small := Vector3(-WHEELBASE_M * 0.5 - shift, SMALL_WHEEL_M, 0.0)
	_wheel(tool, big, BIG_WHEEL_M)
	_wheel(tool, small, SMALL_WHEEL_M)
	# o garfo da roda grande e o guidão de través
	var head := big + Vector3(-0.04, BIG_WHEEL_M + 0.12, 0.0)
	VertexShapes.strut(tool, big, head, 0.018, 0.018, IRON)
	VertexShapes.strut(tool, head + Vector3(0.05, 0.08, -0.26), head + Vector3(0.05, 0.08, 0.26), 0.012, 0.012, IRON)
	# o quadro curvo: do alto do garfo descendo em arco até o cubo da rodinha
	var previous := head
	for k: int in range(1, 6):
		var t := float(k) / 5.0
		var point := head.lerp(small, t) + Vector3(0.0, sin(t * PI) * 0.12, 0.0)
		VertexShapes.strut(tool, previous, point, 0.018, 0.018, IRON)
		previous = point
	VertexShapes.box(tool, head + Vector3(-0.17, 0.03, 0.0), Vector3(0.1, 0.03, 0.06), SADDLE)
	tool.generate_normals()
	return tool.commit()


## Uma roda no plano xy: o pneu em SPOKES * 2 lanços, os raios e o cubo.
static func _wheel(tool: SurfaceTool, hub: Vector3, radius: float) -> void:
	var segments := SPOKES * 2
	for k: int in segments:
		var a0 := TAU * k / segments
		var a1 := TAU * (k + 1) / segments
		VertexShapes.strut(tool, hub + Vector3(cos(a0), sin(a0), 0.0) * radius, hub + Vector3(cos(a1), sin(a1), 0.0) * radius,
				0.02, 0.02, TYRE)
	for k: int in SPOKES:
		var angle := TAU * k / SPOKES
		VertexShapes.strut(tool, hub, hub + Vector3(cos(angle), sin(angle), 0.0) * radius * 0.96, 0.004, 0.004, IRON)
	VertexShapes.cylinder(tool, hub + Vector3(0.0, 0.0, -0.05), hub + Vector3(0.0, 0.0, 0.05), 0.04, HUB, 8)
