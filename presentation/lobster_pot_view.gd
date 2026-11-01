class_name LobsterPotView
extends Node3D
## Fase 222: os covos no cais. Nos lanços do cais de pedra dos entrepostos (Fase 106), fora da frente do entreposto, na ordem dos
## lanços, até PILES_PER_POST pilhas a PILE_GAP_M ou mais umas das outras, POT_IN_M para dentro da beira, ao longo dela (`pots`):
## a pilha de covos de vime em meia-lua (três embaixo e dois em cima), o cabo enrolado e duas boias de cortiça pintadas
## (`pot_mesh`, de poucas faces: a pilha se repete em todo cais). Fica de fora a pilha que cairia a menos de CLEAR_M de um lampião (Fase 146), de uma cisterna (Fase 127), de um
## mastro (Fase 147), do alto de uma escada (Fase 194) ou de um banco (Fase 198), e a que a terra de trás cobriria (o resto fixo
## dos bancos deixava os covos sem lugar: os lanços dele já tinham as outras peças). Um MultiMesh; nada no save; refeito na obra,
## na demolição e ao trocar de mundo.

const PILES_PER_POST := 2
const PILE_GAP_M := 4.0
const POT_IN_M := 1.2
const CLEAR_M := 1.8
const BURIED_M := 0.08
## O covo: o comprimento (ao longo da beira), a largura e a altura da meia-lua.
const POT_L := 0.62
const POT_W := 0.42
const POT_H := 0.32
const ARCH_SEGMENTS := 4
const WICKER := Color(0.58, 0.47, 0.3)
const WICKER_DARK := Color(0.42, 0.33, 0.21)
const ROPE := Color(0.68, 0.6, 0.44)
const BUOY_RED := Color(0.66, 0.18, 0.13)
const CORK := Color(0.82, 0.74, 0.58)

var _simulation: Simulation
var _pots := MultiMeshInstance3D.new()
## Os lugares das pilhas (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.85
	_pots.name = "LobsterPots"
	_pots.multimesh = MultiMesh.new()
	_pots.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_pots.multimesh.mesh = pot_mesh()
	_pots.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_pots.material_override = material
	add_child(_pots)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func pot_count() -> int:
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
		var record := world.building(id)
		if _simulation.def_of(record).is_trading_post:
			places.append_array(pots(_simulation, record))
	_pots.multimesh.instance_count = places.size()
	for i: int in places.size():
		_pots.multimesh.set_instance_transform(i, places[i])


## As pilhas de covos do cais do entreposto: o pé no alto da plataforma, o x ao longo da beira e o −z para o mar.
static func pots(simulation: Simulation, record: BuildingRecord) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var segments := HarborView.stone_quay(simulation, record)
	if segments.is_empty():
		return result
	var others: Array[Vector3] = QuayRailView.lamps(simulation, record)
	for place: Transform3D in HarborView.cistern_places(simulation, record):
		others.append(place.origin)
	others.append_array(QuayMastView.masts(simulation, record))
	for frame: Transform3D in QuayStairsView.flights(simulation, record):
		others.append(frame.origin)
	for bench: Transform3D in QuayBenchView.benches(simulation, record):
		others.append(bench.origin)
	for i: int in segments.size():
		if result.size() >= PILES_PER_POST or QuayRailView._in_front(simulation, record, segments[i]):
			continue
		var segment: Array = segments[i]
		var front: Vector3 = segment[0]
		var outward: Vector3 = segment[1]
		var along := Vector3(-outward.z, 0.0, outward.x)
		var point := front - outward * POT_IN_M
		if simulation.world.surface_height(point.x, point.z) > front.y + BURIED_M:
			continue
		var near := false
		for other: Vector3 in others:
			if Vector2(other.x - point.x, other.z - point.z).length() < CLEAR_M:
				near = true
				break
		for pile: Transform3D in result:
			if pile.origin.distance_to(point) < PILE_GAP_M:
				near = true
		if near:
			continue
		result.append(Transform3D(Basis(along, Vector3.UP, -outward), point))
	return result


## A pilha com o pé no zero, o x ao longo da beira e o −z para o mar: três covos embaixo, dois em cima nos vãos, o cabo enrolado
## em +x e as duas boias em −x.
static func pot_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k: int in 3:
		_pot(tool, Vector3((k - 1) * (POT_L + 0.04), 0.0, 0.0), 0.95 + 0.05 * k)
	for k: int in 2:
		_pot(tool, Vector3((k - 0.5) * (POT_L + 0.04), POT_H - 0.02, 0.03), 1.0 - 0.06 * k)
	# o cabo enrolado no chão, em três voltas
	var coil := Vector3(1.15, 0.0, 0.05)
	for turn: int in 3:
		var radius := 0.2 - turn * 0.035
		var y := 0.03 + turn * 0.04
		for s: int in 9:
			var a0 := TAU * s / 9.0
			var a1 := TAU * (s + 1) / 9.0
			VertexShapes.strut(tool, coil + Vector3(cos(a0) * radius, y, sin(a0) * radius),
					coil + Vector3(cos(a1) * radius, y, sin(a1) * radius), 0.022, 0.022, ROPE)
	# as duas boias de cortiça, uma de pé e uma deitada, com a faixa pintada
	var stand := Vector3(-1.12, 0.0, 0.08)
	VertexShapes.cylinder(tool, stand, stand + Vector3(0.0, 0.26, 0.0), 0.11, CORK, 8)
	VertexShapes.cylinder(tool, stand + Vector3(0.0, 0.26, 0.0), stand + Vector3(0.0, 0.36, 0.0), 0.11, BUOY_RED, 8)
	VertexShapes.cylinder(tool, stand + Vector3(0.0, 0.36, 0.0), stand + Vector3(0.0, 0.62, 0.0), 0.015, WICKER_DARK, 4)
	var lying := Vector3(-1.05, 0.1, -0.3)
	VertexShapes.cylinder(tool, lying, lying + Vector3(0.24, 0.0, 0.1), 0.1, CORK, 8)
	VertexShapes.cylinder(tool, lying + Vector3(0.24, 0.0, 0.1), lying + Vector3(0.33, 0.0, 0.14), 0.1, BUOY_RED, 8)
	tool.generate_normals()
	return tool.commit()


## Um covo com o meio do pé em at: a base de tábuas, os arcos de vime em meia-lua ao longo de x, as varas de cima de ponta a
## ponta e as duas cabeceiras tramadas; tone muda o tom do vime.
static func _pot(tool: SurfaceTool, at: Vector3, tone: float) -> void:
	VertexShapes.box(tool, at + Vector3(0.0, 0.015, 0.0), Vector3(POT_L * 0.5, 0.015, POT_W * 0.5), WICKER_DARK * tone)
	var arches: Array[float] = [-POT_L * 0.46, -POT_L * 0.15, POT_L * 0.15, POT_L * 0.46]
	for x: float in arches:
		var last := at + Vector3(x, 0.03, -POT_W * 0.5)
		for s: int in range(1, ARCH_SEGMENTS + 1):
			var angle := PI * s / ARCH_SEGMENTS
			var point := at + Vector3(x, 0.03 + sin(angle) * (POT_H - 0.03), -cos(angle) * POT_W * 0.5)
			VertexShapes.strut(tool, last, point, 0.012, 0.012, WICKER * tone)
			last = point
	# as varas de ponta a ponta sobre os arcos
	for s: int in range(1, ARCH_SEGMENTS):
		var angle := PI * s / ARCH_SEGMENTS
		var y := 0.03 + sin(angle) * (POT_H - 0.03)
		var z := -cos(angle) * POT_W * 0.5
		VertexShapes.strut(tool, at + Vector3(-POT_L * 0.5, y, z), at + Vector3(POT_L * 0.5, y, z), 0.009, 0.009,
				WICKER * tone * 0.9)
	# as cabeceiras: a meia-lua tramada, num leque de triângulos
	for x: float in [-POT_L * 0.47, POT_L * 0.47]:
		var center := at + Vector3(x, 0.03, 0.0)
		for s: int in ARCH_SEGMENTS:
			var a0 := PI * s / ARCH_SEGMENTS
			var a1 := PI * (s + 1) / ARCH_SEGMENTS
			var p := at + Vector3(x, 0.03 + sin(a0) * (POT_H - 0.03), -cos(a0) * POT_W * 0.5)
			var q := at + Vector3(x, 0.03 + sin(a1) * (POT_H - 0.03), -cos(a1) * POT_W * 0.5)
			VertexShapes.tri(tool, center, p, q, WICKER_DARK * tone)
			VertexShapes.tri(tool, center, q, p, WICKER_DARK * tone)
