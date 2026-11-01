class_name AnchorView
extends Node3D
## Fase 236: a âncora no cais. Em cada cais de pedra dos entrepostos (Fase 106), no último lanço livre (os covos da Fase 222 tomam
## os primeiros), fora da frente do entreposto, no fundo do cais, ANCHOR_IN_M para dentro da beira (as outras peças ficam junto
## dela), ao longo dela (`spot`): a âncora velha de ferro enferrujada deitada como cai no chão — a haste, o cepo de madeira
## atravessado, os dois braços curvos com as patas (um no chão, outro erguido) e a argola — e a amarra de elos enrolada ao lado
## (`anchor_mesh`). Fica de fora o lanço a menos de CLEAR_M de um lampião, cisterna, mastro, alto de escada, banco ou pilha de
## covos, e o que a terra de trás cobriria. Um MultiMesh; nada no save; refeito na obra, na demolição e ao trocar de mundo.

const ANCHOR_IN_M := 3.6
const CLEAR_M := 2.2
const BURIED_M := 0.08
## A âncora: o comprimento da haste, o do cepo (atravessado STOCK_IN_M antes da cabeça, de meia grossura STOCK_HALF_M), o raio
## da curva dos braços e o quanto eles abrem, a argola e o rolo da amarra (o meio em x e z, o raio e os elos).
const SHANK_M := 2.0
const STOCK_M := 1.5
const STOCK_IN_M := 0.16
const STOCK_HALF_M := 0.07
const ARM_M := 0.62
const ARM_RAD := 1.25
const ARM_STEPS := 4
const RING_M := 0.13
const COIL_AT := Vector2(1.0, 1.15)
const COIL_M := 0.3
const COIL_LINKS := 16
const LEAD_LINKS := 6
const IRON := Color(0.24, 0.17, 0.13)
const RUST := Color(0.42, 0.24, 0.13)
const WOOD := Color(0.4, 0.31, 0.22)

var _simulation: Simulation
var _anchors := MultiMeshInstance3D.new()
## Os lugares das âncoras (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.75
	material.metallic = 0.3
	_anchors.name = "Anchors"
	_anchors.multimesh = MultiMesh.new()
	_anchors.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_anchors.multimesh.mesh = anchor_mesh()
	_anchors.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_anchors.material_override = material
	add_child(_anchors)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func anchor_count() -> int:
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
			var found: Variant = spot(_simulation, record)
			if found is Transform3D:
				var place: Transform3D = found
				places.append(place)
	_anchors.multimesh.instance_count = places.size()
	for i: int in places.size():
		_anchors.multimesh.set_instance_transform(i, places[i])


## O lugar da âncora no cais do entreposto (o pé no alto da plataforma, o x ao longo da beira, o −z para o mar), ou null.
static func spot(simulation: Simulation, record: BuildingRecord) -> Variant:
	var segments := HarborView.stone_quay(simulation, record)
	if segments.is_empty():
		return null
	var others: Array[Vector3] = QuayRailView.lamps(simulation, record)
	for place: Transform3D in HarborView.cistern_places(simulation, record):
		others.append(place.origin)
	others.append_array(QuayMastView.masts(simulation, record))
	for frame: Transform3D in QuayStairsView.flights(simulation, record):
		others.append(frame.origin)
	for bench: Transform3D in QuayBenchView.benches(simulation, record):
		others.append(bench.origin)
	for pile: Transform3D in LobsterPotView.pots(simulation, record):
		others.append(pile.origin)
	for i: int in range(segments.size() - 1, -1, -1):
		if QuayRailView._in_front(simulation, record, segments[i]):
			continue
		var segment: Array = segments[i]
		var front: Vector3 = segment[0]
		var outward: Vector3 = segment[1]
		var along := Vector3(-outward.z, 0.0, outward.x)
		var point := front - outward * ANCHOR_IN_M
		if simulation.world.surface_height(point.x, point.z) > front.y + BURIED_M:
			continue
		var near := false
		for other: Vector3 in others:
			if Vector2(other.x - point.x, other.z - point.z).length() < CLEAR_M:
				near = true
				break
		if near:
			continue
		return Transform3D(Basis(along, Vector3.UP, -outward), point)
	return null


## A âncora deitada como cai no chão, com o pé no zero, a haste ao longo de x e o −z para o mar: montada com a haste reta e os
## braços num plano de pé, ela é tombada em volta de z até o cepo e a pata de baixo tocarem o chão juntos (o outro braço fica
## erguido); a argola deitada além da cabeça e a amarra saindo dela para o lado de terra (por fora do cepo) até o rolo, em elos
## alternados.
static func anchor_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var crown := Vector3(-SHANK_M * 0.5, 0.0, 0.0)
	var head := Vector3(SHANK_M * 0.5, 0.0, 0.0)
	var stock_at := head - Vector3(STOCK_IN_M, 0.0, 0.0)
	var tip := crown + Vector3(ARM_M * (1.0 - cos(ARM_RAD)), -ARM_M * sin(ARM_RAD) - 0.03, 0.0)
	var rest := stock_at - Vector3(0.0, STOCK_HALF_M, 0.0)
	var tilt := atan2(rest.y - tip.y, rest.x - tip.x)
	var turn := Basis(Vector3.BACK, -tilt)
	var frame := Transform3D(turn, Vector3(0.0, -(turn * tip).y, 0.0))
	VertexShapes.strut(tool, frame * crown, frame * head, 0.055, 0.055, IRON)
	# o cepo de madeira atravessado, com as duas cintas de ferro
	VertexShapes.oriented_box(tool, frame * Transform3D(Basis.IDENTITY, stock_at), Vector3(STOCK_HALF_M, STOCK_HALF_M,
			STOCK_M * 0.5), WOOD)
	for t: float in [-0.28, 0.28]:
		VertexShapes.oriented_box(tool, frame * Transform3D(Basis.IDENTITY, stock_at + Vector3(0.0, 0.0, t * STOCK_M)),
				Vector3(STOCK_HALF_M + 0.008, STOCK_HALF_M + 0.008, 0.025), IRON)
	# os dois braços curvos saindo da cruz para a cabeça, com as patas
	for side: float in [-1.0, 1.0]:
		var last := crown
		for s: int in range(1, ARM_STEPS + 1):
			var angle := ARM_RAD * s / ARM_STEPS
			var point := crown + Vector3(ARM_M * (1.0 - cos(angle)), side * ARM_M * sin(angle), 0.0)
			VertexShapes.strut(tool, frame * last, frame * point, 0.045, 0.045, RUST if s == ARM_STEPS else IRON)
			last = point
		var fluke := Basis(Vector3.BACK, side * (ARM_RAD - PI * 0.5))
		VertexShapes.oriented_box(tool, frame * Transform3D(fluke, last), Vector3(0.14, 0.02, 0.12), RUST)
	# a argola deitada além da cabeça
	var ring := frame * head + Vector3(RING_M, 0.0, 0.0)
	ring.y = 0.025
	for k: int in 8:
		var a0 := TAU * k / 8.0
		var a1 := TAU * (k + 1) / 8.0
		VertexShapes.strut(tool, ring + Vector3(cos(a0), 0.0, sin(a0)) * RING_M, ring + Vector3(cos(a1), 0.0, sin(a1)) * RING_M,
				0.02, 0.02, IRON)
	# a amarra: da argola até o rolo, e o rolo em duas voltas
	var coil := Vector3(COIL_AT.x, 0.0, COIL_AT.y)
	var lead_from := ring + Vector3(0.0, 0.0, RING_M)
	var lead_to := coil - Vector3(0.0, 0.0, COIL_M)
	for k: int in LEAD_LINKS:
		var at := lead_from.lerp(lead_to, (k + 0.5) / LEAD_LINKS)
		_link(tool, Vector3(at.x, 0.03, at.z), atan2(lead_to.z - lead_from.z, lead_to.x - lead_from.x), k % 2 == 0)
	for loop: int in 2:
		var radius := COIL_M - loop * 0.09
		for s: int in COIL_LINKS:
			var angle := TAU * s / COIL_LINKS
			var at := coil + Vector3(cos(angle) * radius, 0.03 + loop * 0.05, sin(angle) * radius)
			_link(tool, at, angle + PI * 0.5, s % 2 == 0)
	tool.generate_normals()
	return tool.commit()


## Um elo da amarra no ponto at, ao longo do ângulo heading (de +x para +z), deitado ou de pé.
static func _link(tool: SurfaceTool, at: Vector3, heading: float, flat: bool) -> void:
	var basis := Basis(Vector3.UP, -heading)
	var half := Vector3(0.06, 0.016, 0.03) if flat else Vector3(0.06, 0.03, 0.016)
	VertexShapes.oriented_box(tool, Transform3D(basis, at), half, IRON)
