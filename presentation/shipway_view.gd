class_name ShipwayView
extends Node3D
## Fase 115: a carreira do estaleiro. Do lado do mar de cada estaleiro (`HarborView.seaward`) desce até a água uma rampa
## de madeira (`site`): duas vigas-guia, dormentes de través e esteios até o chão onde ela fica no alto. Com uma encomenda
## em andamento, o casco aparece deitado nela, a popa virada para o mar, e cresce com o progresso (`hull_mesh`): a quilha
## nos picadeiros, depois a roda de proa e o cadaste, o cavername da popa para a proa, o costado em fiadas da quilha para
## cima e, por fim, a borda; andaimes e escoras dos lados enquanto a obra anda. Pronto o navio, a encomenda sai e o casco
## some (o navio aparece no porto). O progresso é conferido a cada CHECK_S em STEPS degraus, e só o casco que mudou de
## degrau é refeito. Só lê o estado; nada no save.

const RAMP_WIDTH_M := 6.0
const RAMP_TOP_M := 0.3
const RAMP_BOTTOM_M := -1.8
const RAMP_MIN_M := 26.0
const RAMP_MAX_M := 40.0
## Quanto a rampa passa da primeira água funda.
const RAMP_PAST_WATER_M := 6.0
const WATER_SEARCH_M := 30
const WAY_OFFSET_M := 1.3
const SLEEPER_STEP_M := 1.0
const POST_STEP_M := 2.0
## O casco começa HULL_START_M rampa abaixo, com a quilha KEEL_BLOCK_M acima dela (nos picadeiros).
const HULL_START_M := 2.0
const KEEL_BLOCK_M := 0.7
## O casco em obra é HULL_SCALE do comprimento do navio, com a boca e o pontal pela proporção.
const HULL_SCALE := 0.8
const BEAM_RATIO := 0.27
const DEPTH_RATIO := 0.6
const FRAMES := 14
const STRAKES := 8
const SECTION_SEGMENTS := 12
const LENGTH_SEGMENTS := 24
const STEPS := 40
const CHECK_S := 0.5
## As etapas da obra, em fração do progresso: roda e cadaste, cavername até FRAMES_END, costado de PLANKING_START a
## PLANKING_END, a borda depois disso.
const POSTS_AT := 0.05
const FRAMES_END := 0.5
const PLANKING_START := 0.45
const PLANKING_END := 0.95
const SCAFFOLD_FROM := 0.15
const RAMP_WOOD := Color(0.36, 0.27, 0.19)
const KEEL_WOOD := Color(0.33, 0.24, 0.16)
const FRAME_WOOD := Color(0.66, 0.52, 0.35)
const PLANK_WOOD := Color(0.55, 0.4, 0.26)
const SCAFFOLD_WOOD := Color(0.5, 0.43, 0.33)

var _simulation: Simulation
var _material := StandardMaterial3D.new()
var _ramps: Dictionary[int, MeshInstance3D] = {}
var _hulls: Dictionary[int, MeshInstance3D] = {}
var _sites: Dictionary[int, Dictionary] = {}
var _steps: Dictionary[int, int] = {}
var _wait: float = 0.0
var _dirty: bool = false


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	_material.vertex_color_use_as_albedo = true
	_material.vertex_color_is_srgb = true
	_material.roughness = 0.85
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	EventBus.building_placed.connect(func(_building_id: int) -> void: _dirty = true)
	EventBus.building_removed.connect(func(_building_id: int) -> void: _dirty = true)
	EventBus.roads_changed.connect(func(_island_id: int) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func ramp_count() -> int:
	return _ramps.size()


func hull_of(building_id: int) -> MeshInstance3D:
	return _hulls.get(building_id)


func site_of(building_id: int) -> Dictionary:
	return _sites.get(building_id, {})


func _process(delta: float) -> void:
	if _dirty:
		rebuild()
		return
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = CHECK_S
	refresh_hulls()


func rebuild() -> void:
	_dirty = false
	for node: MeshInstance3D in _ramps.values() + _hulls.values():
		remove_child(node)
		node.queue_free()
	_ramps.clear()
	_hulls.clear()
	_sites.clear()
	_steps.clear()
	var world := _simulation.world
	for building_id: int in world.building_ids():
		var record := world.building(building_id)
		if not _simulation.def_of(record).is_shipyard():
			continue
		var plan := site(_simulation, record)
		if plan.is_empty():
			continue
		_sites[building_id] = plan
		var ramp := MeshInstance3D.new()
		ramp.name = "Ramp_%d" % building_id
		ramp.mesh = ramp_mesh(_simulation.world, plan)
		ramp.material_override = _material
		add_child(ramp)
		_ramps[building_id] = ramp
	refresh_hulls()


## Refaz o casco dos estaleiros cujo degrau de progresso mudou (e tira o dos que ficaram sem encomenda).
func refresh_hulls() -> void:
	var orders := _simulation.world.shipyard_state
	for building_id: int in _sites:
		var order := orders.order(building_id)
		var step := -1 if order == null else clampi(floori(order.progress * STEPS), 0, STEPS)
		if _steps.get(building_id, -2) == step:
			continue
		_steps[building_id] = step
		var old: MeshInstance3D = _hulls.get(building_id)
		if old != null:
			remove_child(old)
			old.queue_free()
			_hulls.erase(building_id)
		if step < 0:
			continue
		var ship := _simulation.data.ship(order.def_id)
		var length := (ship.length_m if ship != null else 16.0) * HULL_SCALE
		var hull := MeshInstance3D.new()
		hull.name = "Hull_%d" % building_id
		hull.mesh = hull_mesh(length, float(step) / STEPS)
		hull.material_override = _material
		hull.transform = hull_transform(_sites[building_id], length)
		add_child(hull)
		_hulls[building_id] = hull


## A carreira de um estaleiro: {start, direction, length, top, bottom}, com a boca na beira do lado do mar e a ponta já
## na água funda; vazio se não há mar perto ou se prédio ou estrada estão no caminho.
static func site(simulation: Simulation, record: BuildingRecord) -> Dictionary:
	var world := simulation.world
	var grid := world.island(record.island_id)
	var def := simulation.def_of(record)
	var cell_size := simulation.config.cell_size_m
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var center := grid.rect_world(area)
	var direction := HarborView.seaward(world, center, area, cell_size, record.rotation)
	var reach := (area.size.x if direction.x != 0.0 else area.size.y) * cell_size * 0.5
	var start := center + direction * reach
	var water := -1
	for meters: int in WATER_SEARCH_M + 1:
		if HarborView.afloat(world, start + direction * meters):
			water = meters
			break
	if water < 0:
		return {}
	var length := clampf(water + RAMP_PAST_WATER_M, RAMP_MIN_M, RAMP_MAX_M)
	var across := Vector3(-direction.z, 0.0, direction.x)
	var meters := 0.5
	while meters < length:
		for offset: float in [-RAMP_WIDTH_M * 0.5, 0.0, RAMP_WIDTH_M * 0.5]:
			var cell := grid.world_to_cell(start + direction * meters + across * offset)
			if not grid.in_bounds(cell):
				continue
			var occupant := grid.building_at(cell)
			if (occupant != 0 and occupant != record.id) or grid.has_road(cell):
				return {}
		meters += 1.0
	var top := maxf(world.surface_height(start.x, start.z), 0.0) + RAMP_TOP_M
	return {"start": Vector3(start.x, top, start.z), "direction": direction, "length": length, "top": top,
			"bottom": RAMP_BOTTOM_M}


## O ponto da linha do meio da rampa a meters da boca, na altura dela.
static func ramp_point(plan: Dictionary, meters: float) -> Vector3:
	var start: Vector3 = plan["start"]
	var direction: Vector3 = plan["direction"]
	var length: float = plan["length"]
	var spot := start + direction * meters
	var top: float = plan["top"]
	var bottom: float = plan["bottom"]
	spot.y = lerpf(top, bottom, clampf(meters / length, 0.0, 1.0))
	return spot


## A rampa no mundo: vigas-guia, dormentes e os esteios até o chão (ou o fundo) onde ela fica no alto.
static func ramp_mesh(world: WorldState, plan: Dictionary) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var direction: Vector3 = plan["direction"]
	var length: float = plan["length"]
	var across := Vector3(-direction.z, 0.0, direction.x)
	for side: float in [-1.0, 1.0]:
		var a := ramp_point(plan, 0.0) + across * side * WAY_OFFSET_M
		var b := ramp_point(plan, length) + across * side * WAY_OFFSET_M
		VertexShapes.strut(tool, a, b, 0.18, 0.12, KEEL_WOOD)
	var meters := SLEEPER_STEP_M * 0.5
	while meters < length:
		var middle := ramp_point(plan, meters) + Vector3(0.0, -0.2, 0.0)
		VertexShapes.strut(tool, middle - across * RAMP_WIDTH_M * 0.5, middle + across * RAMP_WIDTH_M * 0.5, 0.12, 0.08,
				RAMP_WOOD)
		meters += SLEEPER_STEP_M
	meters = POST_STEP_M * 0.5
	while meters < length:
		for side: float in [-1.0, 1.0]:
			var top := ramp_point(plan, meters) + across * side * (RAMP_WIDTH_M * 0.5 - 0.25) + Vector3(0.0, -0.28, 0.0)
			var ground := world.surface_height(top.x, top.z) - 0.3
			if top.y - ground > 0.3:
				VertexShapes.strut(tool, Vector3(top.x, ground, top.z), top, 0.1, 0.1, RAMP_WOOD)
		meters += POST_STEP_M
	tool.generate_normals()
	return tool.commit()


## O referencial do casco na rampa: popa (z = 0) virada para o mar, a proa para a terra, a quilha nos picadeiros.
static func hull_transform(plan: Dictionary, length: float) -> Transform3D:
	var bow := ramp_point(plan, HULL_START_M)
	var stern := ramp_point(plan, HULL_START_M + length)
	var z := (bow - stern).normalized()
	var x := Vector3.UP.cross(z).normalized()
	var y := z.cross(x)
	return Transform3D(Basis(x, y, z), stern + y * KEEL_BLOCK_M)


## Meia boca do casco na fração u do comprimento (0 = popa, 1 = proa): a popa larga, o maior na frente do meio e a proa
## fechando em ponta.
static func half_beam(u: float, beam: float) -> float:
	if u < 0.45:
		return beam * 0.5 * (0.72 + 0.28 * sin(PI * 0.5 * u / 0.45))
	return beam * 0.5 * pow(cos(PI * 0.5 * (u - 0.45) / 0.55), 0.7)


## Altura da borda: sobe nas pontas (o tosado).
static func sheer(u: float, depth: float) -> float:
	return depth * (1.0 + 0.12 * pow(2.0 * u - 1.0, 2.0))


## O ponto do costado na fração u do comprimento e no ângulo phi da seção (0 = quilha, ±PI/2 = borda, + a boreste).
static func hull_point(u: float, phi: float, length: float) -> Vector3:
	var beam := length * BEAM_RATIO
	var depth := beam * DEPTH_RATIO
	return Vector3(half_beam(u, beam) * sin(phi), sheer(u, depth) * (1.0 - cos(phi)), u * length)


## O casco em obra no progresso dado (0 a 1), no referencial dele: quilha em y = 0 de z = 0 (popa) a z = length (proa).
static func hull_mesh(length: float, progress: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var beam := length * BEAM_RATIO
	var depth := beam * DEPTH_RATIO
	# a quilha e os picadeiros
	VertexShapes.strut(tool, Vector3(0.0, -0.12, -0.2), Vector3(0.0, -0.12, length + 0.2), 0.14, 0.14, KEEL_WOOD)
	var block := 0.75
	while block < length:
		VertexShapes.box(tool, Vector3(0.0, -0.26 - KEEL_BLOCK_M * 0.5 + 0.01, block),
				Vector3(0.35, KEEL_BLOCK_M * 0.5 - 0.13, 0.25), KEEL_WOOD)
		block += 1.6
	if progress >= POSTS_AT:
		# a roda de proa e o cadaste, levemente inclinados para fora
		VertexShapes.strut(tool, Vector3(0.0, 0.0, length), Vector3(0.0, sheer(1.0, depth) + 0.35, length + 0.55), 0.12,
				0.14, KEEL_WOOD)
		VertexShapes.strut(tool, Vector3(0.0, 0.0, 0.0), Vector3(0.0, sheer(0.0, depth) + 0.25, -0.35), 0.12, 0.14,
				KEEL_WOOD)
		# escoras dos dois lados, do chão (a rampa) ao bojo
		for u: float in [0.25, 0.5, 0.75]:
			for side: float in [-1.0, 1.0]:
				var touch := hull_point(u, side * PI / 3.0, length)
				var foot := Vector3(side * (half_beam(u, beam) + 1.6), -KEEL_BLOCK_M, u * length)
				VertexShapes.strut(tool, foot, touch, 0.07, 0.07, SCAFFOLD_WOOD)
	# o cavername, da popa para a proa
	var frames := ceili(FRAMES * clampf((progress - POSTS_AT) / (FRAMES_END - POSTS_AT), 0.0, 1.0))
	for i: int in frames:
		var u := (i + 0.5) / FRAMES
		for k: int in SECTION_SEGMENTS:
			var a := hull_point(u, -PI * 0.5 + PI * k / SECTION_SEGMENTS, length)
			var b := hull_point(u, -PI * 0.5 + PI * (k + 1) / SECTION_SEGMENTS, length)
			VertexShapes.strut(tool, a, b, 0.07, 0.07, FRAME_WOOD)
	# o costado em fiadas, da quilha para cima; na última etapa, a borda
	var strakes := floori(STRAKES * clampf((progress - PLANKING_START) / (PLANKING_END - PLANKING_START), 0.0, 1.0))
	for j: int in strakes:
		_strake(tool, length, PI * 0.5 * j / STRAKES, PI * 0.5 * (j + 1) / STRAKES)
	if progress >= PLANKING_END:
		for side: float in [-1.0, 1.0]:
			for i: int in LENGTH_SEGMENTS:
				var a := hull_point(float(i) / LENGTH_SEGMENTS, side * PI * 0.5, length) + Vector3(0.0, 0.08, 0.0)
				var b := hull_point(float(i + 1) / LENGTH_SEGMENTS, side * PI * 0.5, length) + Vector3(0.0, 0.08, 0.0)
				VertexShapes.strut(tool, a, b, 0.09, 0.08, KEEL_WOOD)
	# andaime dos dois lados: varas em pé e duas tábuas de passadiço
	if progress >= SCAFFOLD_FROM and progress < 1.0:
		var out := beam * 0.5 + 0.9
		var z := 0.5
		var poles: Array[float] = []
		while z < length:
			poles.append(z)
			z += 3.0
		for side: float in [-1.0, 1.0]:
			for pole: float in poles:
				VertexShapes.strut(tool, Vector3(side * out, -KEEL_BLOCK_M, pole), Vector3(side * out, depth + 1.0, pole),
						0.05, 0.05, SCAFFOLD_WOOD)
			for height: float in [depth * 0.45, depth * 0.95]:
				VertexShapes.strut(tool, Vector3(side * (out - 0.25), height, poles[0]),
						Vector3(side * (out - 0.25), height, poles[-1]), 0.25, 0.03, SCAFFOLD_WOOD)
	tool.generate_normals()
	return tool.commit()


## Uma fiada do costado dos dois lados, entre os ângulos phi0 e phi1 da seção, de ponta a ponta.
static func _strake(tool: SurfaceTool, length: float, phi0: float, phi1: float) -> void:
	for side: float in [-1.0, 1.0]:
		for i: int in LENGTH_SEGMENTS:
			var u0 := float(i) / LENGTH_SEGMENTS
			var u1 := float(i + 1) / LENGTH_SEGMENTS
			var a := hull_point(u0, side * phi0, length)
			var b := hull_point(u1, side * phi0, length)
			var c := hull_point(u1, side * phi1, length)
			var d := hull_point(u0, side * phi1, length)
			# para fora: do eixo do casco para o costado
			var outward := (a + c) * 0.5 - Vector3(0.0, sheer((u0 + u1) * 0.5, length * BEAM_RATIO * DEPTH_RATIO), (a.z + c.z) * 0.5)
			outward.z = 0.0
			if (b - a).cross(c - a).dot(outward) > 0.0:
				VertexShapes.quad(tool, a, d, c, b, PLANK_WOOD)
			else:
				VertexShapes.quad(tool, a, b, c, d, PLANK_WOOD)
