class_name RowboatView
extends Node3D
## Fase 142: os botes a remo do porto. Diante de cada entreposto, BOATS_PER_POST botes dão voltas devagar numa roda de
## água funda do lado do mar (`loop`: o meio e o raio, achados pelo `HarborView.seaward` e pelo `afloat`), um em cada
## sentido; cada um com o remador sentado de costas para a proa, que se inclina a cada remada, e os dois remos que varrem
## e mergulham (`pose`, `oar_pose`, `rower_pose`; o bote dá um arranco a cada remada). O casco é o bote do cais
## (`HarborView.boat_mesh`); o remador e o remo são gerados aqui (`rower_mesh`, `oar_mesh`). No tempo de jogo (para na
## pausa); à noite os botes voltam ao cais (somem). Só apresentação; nada no save; refeito na obra, na demolição e ao
## trocar de mundo.

const BOATS_PER_POST := 2
## A roda: a distância da beira do entreposto até o meio dela e o raio (tenta mais longe e menor até boiar a roda toda).
const LOOP_OUT_M: Array[float] = [20.0, 26.0, 32.0, 40.0]
const LOOP_RADIUS_M: Array[float] = [8.0, 6.0, 4.5]
const LOOP_SAMPLES := 12
const SPEED_M_S := 1.1
## A remada: o tempo de uma, o arranco do bote, a varredura e o mergulho do remo e a inclinação do remador.
const STROKE_S := 2.4
const SURGE := 0.22
const OAR_LENGTH_M := 2.4
const OAR_SWEEP := 0.5
const OAR_TILT := 0.24
const OAR_DIP := 0.12
const ROWER_LEAN := 0.32
const BOB_M := 0.06
const NIGHT_HIDE := 0.5
## O assento do remador e o tolete, um pouco para a popa dele (no referencial do bote, proa em −Z).
const SEAT := Vector3(0.0, 0.22, 0.25)
const OARLOCK_Z := 0.6
const SHIRTS: Array[Color] = [Color(0.62, 0.5, 0.36), Color(0.42, 0.5, 0.62), Color(0.7, 0.68, 0.62)]
const SKIN := Color(0.84, 0.66, 0.52)
const TROUSERS := Color(0.28, 0.26, 0.24)
const CAP := Color(0.2, 0.2, 0.22)
const OAR_WOOD := Color(0.6, 0.47, 0.3)

var _simulation: Simulation
var _boats := MultiMeshInstance3D.new()
var _rowers := MultiMeshInstance3D.new()
var _oars := MultiMeshInstance3D.new()
## Por bote: [meio da roda, raio, índice no entreposto].
var _loops: Array[Array] = []
var _time: float = 0.0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var wood := StandardMaterial3D.new()
	wood.albedo_color = HarborView.BOAT_COLOR
	wood.roughness = 0.8
	wood.cull_mode = BaseMaterial3D.CULL_DISABLED
	var painted := StandardMaterial3D.new()
	painted.vertex_color_use_as_albedo = true
	painted.vertex_color_is_srgb = true
	painted.roughness = 0.85
	painted.cull_mode = BaseMaterial3D.CULL_DISABLED
	for part: Array in [[_boats, "Rowboats", HarborView.boat_mesh(), wood], [_rowers, "Rowers", rower_mesh(), painted],
			[_oars, "Oars", oar_mesh(), painted]]:
		var layer: MultiMeshInstance3D = part[0]
		layer.name = part[1]
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.mesh = part[2]
		var material: Material = part[3]
		layer.material_override = material
		add_child(layer)
	_rowers.multimesh.use_colors = true
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func boat_count() -> int:
	return _loops.size()


## Anda o relógio dos botes à mão (testes e capturas com o jogo pausado).
func advance(seconds: float) -> void:
	_time += seconds
	_row()


func _mark(_id: int) -> void:
	_dirty = true


func _process(delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()
	var clock := GameClock.clock
	var showing := DayClock.night_factor(_simulation.config, clock.hour()) < NIGHT_HIDE
	for layer: MultiMeshInstance3D in [_boats, _rowers, _oars]:
		layer.visible = showing
	var step := delta * clock.speed_multiplier()
	if showing and step > 0.0:
		advance(step)


func rebuild() -> void:
	_dirty = false
	_loops.clear()
	var world := _simulation.world
	for id: int in world.building_ids():
		var record := world.building(id)
		var def := _simulation.def_of(record)
		if not def.is_trading_post:
			continue
		var found := loop(world, record, def, _simulation.config.cell_size_m)
		if found.is_empty():
			continue
		for k: int in BOATS_PER_POST:
			_loops.append([found[0], found[1], k + id * BOATS_PER_POST])
	_boats.multimesh.instance_count = _loops.size()
	_rowers.multimesh.instance_count = _loops.size()
	_oars.multimesh.instance_count = _loops.size() * 2
	for layer: MultiMeshInstance3D in [_boats, _rowers, _oars]:
		layer.multimesh.custom_aabb = WorldBounds.of(_simulation.config)
	for i: int in _loops.size():
		var k: int = _loops[i][2]
		_rowers.multimesh.set_instance_color(i, SHIRTS[posmod(k, SHIRTS.size())])
	_row()


func _row() -> void:
	for i: int in _loops.size():
		var entry: Array = _loops[i]
		var center: Vector3 = entry[0]
		var radius: float = entry[1]
		var k: int = entry[2]
		var boat := pose(center, radius, k, _time)
		_boats.multimesh.set_instance_transform(i, boat)
		_rowers.multimesh.set_instance_transform(i, boat * rower_pose(k, _time))
		for side: int in 2:
			_oars.multimesh.set_instance_transform(i * 2 + side, boat * oar_pose(1.0 if side == 0 else -1.0, k, _time))


## A roda dos botes do entreposto: [meio (no mar, na altura zero), raio], ou vazio sem água funda para uma roda inteira.
static func loop(world: WorldState, record: BuildingRecord, def: BuildingDef, cell_size: float) -> Array:
	var grid := world.island(record.island_id)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var center := grid.rect_world(area)
	var out := HarborView.seaward(world, center, area, cell_size, record.rotation)
	var reach := (area.size.x if out.x != 0.0 else area.size.y) * cell_size * 0.5
	for out_m: float in LOOP_OUT_M:
		var middle := center + out * (reach + out_m)
		middle.y = 0.0
		for radius: float in LOOP_RADIUS_M:
			var clear := HarborView.afloat(world, middle)
			for n: int in LOOP_SAMPLES:
				if not clear:
					break
				var angle := TAU * n / LOOP_SAMPLES
				clear = HarborView.afloat(world, middle + Vector3(cos(angle), 0.0, sin(angle)) * radius)
			if clear:
				return [middle, radius]
	return []


## A fase da remada do bote k no instante time (rad).
static func stroke(k: int, time: float) -> float:
	return time / STROKE_S * TAU + float(k) * 1.7


## O bote k na roda no instante time: um sentido para os pares e outro para os ímpares, com o arranco a cada remada, a
## proa (−Z do casco) para onde ele anda, subindo e descendo nas ondas.
static func pose(center: Vector3, radius: float, k: int, time: float) -> Transform3D:
	var turn := 1.0 if k % 2 == 0 else -1.0
	var speed := SPEED_M_S / radius
	var travel := time + SURGE * STROKE_S / TAU * sin(stroke(k, time))
	var angle := float(k) * 2.3 + turn * speed * travel
	var at := center + Vector3(cos(angle), 0.0, sin(angle)) * radius
	at.y = sin(time * 1.3 + float(k)) * BOB_M
	var forward := Vector3(-sin(angle), 0.0, cos(angle)) * turn
	var roll := Basis(Vector3.FORWARD, sin(time * 0.9 + float(k) * 0.7) * 0.04)
	return Transform3D(Basis.looking_at(forward, Vector3.UP) * roll, at)


## O remador no referencial do bote: sentado, de costas para a proa, inclinando para trás na remada.
static func rower_pose(k: int, time: float) -> Transform3D:
	var lean := sin(stroke(k, time)) * ROWER_LEAN
	return Transform3D(Basis(Vector3.RIGHT, lean), SEAT)


## O remo do lado side (+1 boreste, −1 bombordo) no referencial do bote: preso no tolete, varre da proa para a popa com a pá
## n'água e volta erguido.
static func oar_pose(side: float, k: int, time: float) -> Transform3D:
	var phase := stroke(k, time)
	var sweep := cos(phase) * OAR_SWEEP
	var tilt := OAR_TILT + sin(phase) * OAR_DIP
	var yaw := sweep if side > 0.0 else PI - sweep
	var oarlock := Vector3(side * HarborView.BOAT_BEAM_M * 0.5, HarborView.BOAT_DEPTH_M, OARLOCK_Z)
	return Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, -tilt), oarlock)


## O remador de frente para +Z (a popa), com o pé no zero do assento: calça, tronco na cor da instância (branco no
## vértice), braços para a frente segurando os remos, a cabeça e o boné.
static func rower_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.box(tool, Vector3(0.0, 0.08, 0.18), Vector3(0.16, 0.08, 0.22), TROUSERS)
	VertexShapes.box(tool, Vector3(0.0, 0.42, 0.0), Vector3(0.17, 0.26, 0.11), Color.WHITE)
	for side: float in [-1.0, 1.0]:
		VertexShapes.strut(tool, Vector3(side * 0.18, 0.58, 0.02), Vector3(side * 0.22, 0.34, 0.36), 0.04, 0.04, Color.WHITE)
	VertexShapes.box(tool, Vector3(0.0, 0.8, 0.0), Vector3(0.09, 0.1, 0.09), SKIN)
	VertexShapes.box(tool, Vector3(0.0, 0.92, 0.02), Vector3(0.1, 0.035, 0.12), CAP)
	tool.generate_normals()
	return tool.commit()


## O remo ao longo de +X a partir do tolete: o cabo para dentro, a haste e a pá na ponta, rente à água.
static func oar_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.strut(tool, Vector3(-0.45, 0.0, 0.0), Vector3(OAR_LENGTH_M - 0.5, 0.0, 0.0), 0.025, 0.025, OAR_WOOD)
	VertexShapes.box(tool, Vector3(OAR_LENGTH_M - 0.28, 0.0, 0.0), Vector3(0.24, 0.012, 0.07), OAR_WOOD.darkened(0.1))
	tool.generate_normals()
	return tool.commit()
