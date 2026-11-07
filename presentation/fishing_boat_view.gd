class_name FishingBoatView
extends Node3D
## Fase 107: os barcos de pesca. Cada cabana de pesca tem um barco a vela (o casco a remo da HarborView, com o mastro e
## a vela latina) que, enquanto a cabana produz, faz a volta da pesca: sai do ponto de amarra (`route`, a água funda mais
## perto da cabana, do lado do mar) até o pesqueiro, mar adentro, pesca dando voltas devagar e volta (`pose`). Com a
## cabana parada, fica amarrado. No tempo de jogo (para na pausa), desencontrado pelo id. Só lê o estado; nada no save.

const CYCLE_S := 120.0
## As partes da volta: ida (até OUT_END), pesca (até FISH_END) e volta.
const OUT_END := 0.3
const FISH_END := 0.7
const FISHING_GROUND_M := 45.0
const FISH_CIRCLE_M := 5.0
const HOME_SEARCH_M := 24
const MAST_M := 3.2
const SAIL_COLOR := Color(0.9, 0.86, 0.76)
const BOB_M := 0.08

var _simulation: Simulation
var _boats: Dictionary[int, Node3D] = {}
var _routes: Dictionary[int, Array] = {}
var _time: float = 0.0
var _hull: ArrayMesh
var _rig: ArrayMesh


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var wood := StandardMaterial3D.new()
	wood.albedo_color = HarborView.BOAT_COLOR
	wood.roughness = 0.8
	wood.cull_mode = BaseMaterial3D.CULL_DISABLED
	_hull = HarborView.boat_mesh()
	_hull.surface_set_material(0, wood)
	_rig = rig_mesh()
	EventBus.building_placed.connect(_on_change)
	EventBus.building_removed.connect(_on_change)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func boat_count() -> int:
	return _boats.size()


func boat_of(building_id: int) -> Node3D:
	return _boats.get(building_id)


func _on_change(_building_id: int) -> void:
	rebuild()


func rebuild() -> void:
	for node: Node3D in _boats.values():
		node.queue_free()
	_boats.clear()
	_routes.clear()
	for building_id: int in _simulation.world.building_ids():
		var record := _simulation.world.building(building_id)
		if _simulation.def_of(record).id != &"fishery":
			continue
		var path := route(_simulation, record)
		if path.is_empty():
			continue
		_routes[building_id] = path
		var boat := Node3D.new()
		boat.name = "FishingBoat%d" % building_id
		var hull := MeshInstance3D.new()
		hull.mesh = _hull
		boat.add_child(hull)
		var rig := MeshInstance3D.new()
		rig.mesh = _rig
		rig.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		boat.add_child(rig)
		add_child(boat)
		_boats[building_id] = boat
	_place_all()


## O ponto de amarra (a água funda mais perto da cabana, do lado do mar) e o pesqueiro (mar adentro na mesma direção, até
## onde ainda boia); vazio se não houver água funda por perto.
static func route(simulation: Simulation, record: BuildingRecord) -> Array[Vector3]:
	var world := simulation.world
	var def := simulation.def_of(record)
	var grid := world.island(record.island_id)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var center := grid.rect_world(area)
	var cell_size := simulation.config.cell_size_m
	var out := HarborView.seaward(world, center, area, cell_size, record.rotation)
	var reach := (area.size.x if out.x != 0.0 else area.size.y) * cell_size * 0.5
	var home := Vector3.INF
	for meters: int in HOME_SEARCH_M:
		var spot := center + out * (reach + 2.0 + meters)
		if HarborView.afloat(world, spot):
			home = Vector3(spot.x, 0.0, spot.z)
			break
	if home == Vector3.INF:
		return []
	var far := home
	for meters: int in range(int(FISHING_GROUND_M), 0, -5):
		var spot := home + out * float(meters)
		if HarborView.afloat(world, spot):
			far = Vector3(spot.x, 0.0, spot.z)
			break
	return [home, far]


## Onde o barco está na volta (fase de 0 a 1): a ida suave, a pesca em círculo em volta do pesqueiro e a volta; o barco
## olha para onde anda (a proa do casco é −Z).
static func pose(home: Vector3, far: Vector3, phase: float) -> Transform3D:
	var heading := (far - home).normalized() if far.distance_to(home) > 0.01 else Vector3.FORWARD
	var at: Vector3
	var facing := heading
	if phase < OUT_END:
		at = home.lerp(far, smoothstep(0.0, 1.0, phase / OUT_END))
	elif phase < FISH_END:
		var turn := (phase - OUT_END) / (FISH_END - OUT_END) * TAU
		var side := Vector3(-heading.z, 0.0, heading.x)
		# a volta passa pelo pesqueiro no começo e no fim e começa na direção da ida (sem salto de posição)
		at = far + (heading * sin(turn) + side * (1.0 - cos(turn))) * FISH_CIRCLE_M * 0.5
		facing = (heading * cos(turn) + side * sin(turn)).normalized()
	else:
		at = far.lerp(home, smoothstep(0.0, 1.0, (phase - FISH_END) / (1.0 - FISH_END)))
		facing = -heading
	return Transform3D(Basis.looking_at(facing, Vector3.UP), at)


## A fase da volta do barco da cabana: desencontrada pelo id.
static func phase_of(building_id: int, time_s: float) -> float:
	return fposmod(time_s / CYCLE_S + float(absi(hash(building_id)) % 1000) / 1000.0, 1.0)


## O mastro, a verga e a vela latina (um triângulo dos dois lados), num referencial em que a proa é −Z.
static func rig_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mast_foot := Vector3(0.0, HarborView.BOAT_DEPTH_M * 0.5, -HarborView.BOAT_LENGTH_M * 0.18)
	CropView._part(tool, CropView._box(Vector3(0.07, MAST_M, 0.07)), Transform3D(Basis.IDENTITY,
			mast_foot + Vector3(0.0, MAST_M * 0.5, 0.0)), HarborView.BOAT_COLOR.darkened(0.2))
	var head := mast_foot + Vector3(0.0, MAST_M, 0.0)
	var tack := mast_foot + Vector3(0.0, 0.5, -0.3)
	var clew := mast_foot + Vector3(0.0, 0.55, HarborView.BOAT_LENGTH_M * 0.55)
	var peak := head + Vector3(0.0, 0.3, HarborView.BOAT_LENGTH_M * 0.25)
	for side: float in [-1.0, 1.0]:
		var bulge := Vector3(side * 0.04, 0.0, 0.0)
		for vertex: Vector3 in [tack + bulge, peak + bulge, clew + bulge]:
			tool.set_color(SAIL_COLOR)
			tool.set_normal(Vector3(side, 0.0, 0.0))
			tool.add_vertex(vertex)
	tool.index()
	var mesh := tool.commit()
	var cloth := StandardMaterial3D.new()
	cloth.vertex_color_use_as_albedo = true
	cloth.vertex_color_is_srgb = true
	cloth.roughness = 0.9
	cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, cloth)
	return mesh


func _process(delta: float) -> void:
	if _simulation == null:
		return
	_time += delta * GameClock.clock.speed_multiplier()
	_place_all()


func _place_all() -> void:
	for building_id: int in _boats:
		var record := _simulation.world.building(building_id)
		if record == null:
			continue
		var path: Array = _routes[building_id]
		var home: Vector3 = path[0]
		var far: Vector3 = path[1]
		var working := record.state == BuildingRecord.State.PRODUCING and not record.paused
		var place := pose(home, far, phase_of(building_id, _time)) if working else pose(home, far, 0.0)
		place.origin.y = sin(_time * 1.3 + building_id) * BOB_M
		_boats[building_id].transform = place
