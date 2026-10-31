class_name HarborView
extends Node3D
## Porto (Fase 15): o píer vira trapiche de madeira. Um tabuleiro de tábuas sobre estacas cobre a área dele e
## segue como passarela até perto do cais (Harbors.berth_point: onde o navio encosta), com cabeços de
## amarração na ponta. Sem cais (píer sem estrada até um entreposto), a passarela vai para o mar mais perto
## (`seaward`). Tábuas, estacas e cabeços são caixas e cilindros, um MultiMesh por peça, refeitos
## quando prédio, estrada ou mundo muda. Só lê o mundo.
## Parte 2: o entreposto ganha cais de tábuas no lado do mar, com cabeços na beira, carga (barris, caixotes e sacos
## do CargoKit) e dois barcos a remo amarrados; cada píer ganha um barco ao lado da passarela.
## Fase 20: as amarras. Cada barco leva um cabo da proa e outro da popa até o cabeço mais perto do mesmo píer
## ou cais, caindo em curva entre as pontas (`rope_span`); todos os cabos numa malha só, refeita com o resto.
## As tábuas e as estacas levam a madeira gasta do `shaders/plank.gdshader`.
## Fase 21: o cabo dá duas voltas no fuste do cabeço (`hitch`) e sai dele do lado do barco, em vez de nascer
## no meio do ferro.
## Fase 106: o cais de pedra. Ao longo da costa, dos dois lados do entreposto, uma plataforma reta de cantaria no nível
## do cais de tábuas, de QUAY_DEPTH_M para o mar e STONE_QUAY_BACK_M para dentro, em lanços de STONE_QUAY_STEP_M até
## STONE_QUAY_REACH_M de cada lado (parando onde a terra sobe), com o paredão descendo até SEA_WALL_BOTTOM_M, o
## capeamento na beira e um cabeço a cada SEA_WALL_BOLLARD_EVERY lanços (stone_quay). A linha d'água desenhada é curva:
## o cais segue a frente do entreposto, não a escada das células.

## Tábua: largura (ao longo da passarela), fresta, espessura e altura do tabuleiro acima do chão (ou da água).
const BOARD_WIDTH_M := 0.3
const BOARD_GAP_M := 0.04
const BOARD_THICKNESS_M := 0.08
const DECK_LIFT_M := 0.5
## Passarela: largura, folga até o cais (o casco encosta do lado) e comprimento sem cais.
const WALK_WIDTH_M := 3.0
const BERTH_CLEARANCE_M := 4.0
const WALK_MIN_M := 4.0
const WALK_MAX_M := 30.0
const WALK_DEFAULT_M := 12.0
## Estacas: espaço entre elas, grossura e quanto descem abaixo do chão ou da água.
const PILE_STEP_M := 2.0
const PILE_WIDTH_M := 0.22
const PILE_SINK_M := 1.5
## Cabeço de amarração: raio e altura acima do tabuleiro.
const BOLLARD_RADIUS_M := 0.16
const BOLLARD_HEIGHT_M := 0.45
## Cais do entreposto: fundo (para o mar), espaço entre cabeços e a carga (tipo de peça por lugar, da esquerda
## para a direita, no fundo do cais).
const QUAY_DEPTH_M := 3.0
const QUAY_BOLLARD_STEP_M := 3.0
const QUAY_CARGO: Array[int] = [GoodDef.Pile.BARREL, GoodDef.Pile.BARREL, GoodDef.Pile.CRATE, GoodDef.Pile.SACK,
		GoodDef.Pile.SACK, GoodDef.Pile.CRATE, GoodDef.Pile.BARREL]
## Barco a remo: comprimento, boca, pontal e quanto o casco afunda na água.
const BOAT_LENGTH_M := 4.0
const BOAT_BEAM_M := 1.3
const BOAT_DEPTH_M := 0.5
const BOAT_DRAFT_M := 0.15
const BOAT_COLOR := Color(0.36, 0.25, 0.16)
const BOAT_SEARCH_M := 12
const BOAT_KEEL_CLEARANCE_M := 0.2
const WOOD_COLOR := Color(0.45, 0.33, 0.22)
const IRON_COLOR := Color(0.16, 0.16, 0.17)
## Cabo de amarração: raio, quanto cai no meio (fração do vão), pedaços da curva, vão máximo e a cor do cânhamo.
const ROPE_RADIUS_M := 0.025
const ROPE_SAG := 0.12
const ROPE_SEGMENTS := 12
const ROPE_MAX_M := 10.0
const ROPE_COLOR := Color(0.62, 0.53, 0.38)
## Volta no cabeço (Fase 21): quantas voltas o cabo dá em volta do fuste, de quanto em quanto ele desce a cada
## volta e os pedaços de cada volta. Um segundo cabo no mesmo cabeço dá as voltas dele mais abaixo.
const HITCH_TURNS := 2.0
const HITCH_PITCH_M := 0.05
const HITCH_SEGMENTS := 10
## Fase 106: o cais de pedra.
const STONE_QUAY_REACH_M := 14.0
const STONE_QUAY_STEP_M := 2.0
const STONE_QUAY_BACK_M := 2.5
const STONE_QUAY_BELOW_DECK_M := 0.25
const STONE_QUAY_RISE_M := 0.6
const SEA_WALL_BOTTOM_M := -2.0
const COPING_M := Vector2(0.18, 0.95)
const SEA_WALL_BOLLARD_EVERY := 3
## Fase 127: as cisternas ficam a pelo menos isto além da largura do entreposto, no cais de pedra.
const CISTERN_CLEAR_M := 1.6
const STONE_COLOR := Color(0.78, 0.76, 0.7)

var _simulation: Simulation
var _boards := MultiMeshInstance3D.new()
var _piles := MultiMeshInstance3D.new()
var _bollards := MultiMeshInstance3D.new()
var _boats := MultiMeshInstance3D.new()
var _walls := MultiMeshInstance3D.new()
var _coping := MultiMeshInstance3D.new()
var _cisterns := MultiMeshInstance3D.new()
var _cargo: Dictionary[int, MultiMeshInstance3D] = {}
var _ropes := MeshInstance3D.new()
var _rope_spans: Array[PackedVector3Array] = []
var _hitches: Array[PackedVector3Array] = []
var _rope_material := StandardMaterial3D.new()
var _dirty: bool = false


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	# Fase 20: a madeira gasta, com o veio e o tom de cada tábua
	var wood := TraderPostModel.plank_material(WOOD_COLOR, 0.0, false)
	var iron := StandardMaterial3D.new()
	iron.albedo_color = IRON_COLOR
	iron.metallic = 0.6
	iron.roughness = 0.5
	# tábua de 1 m de comprimento (esticada até a largura do tabuleiro), estaca de 1 m de altura (esticada)
	var board := BoxMesh.new()
	board.size = Vector3(1.0, BOARD_THICKNESS_M, BOARD_WIDTH_M)
	board.material = wood
	var pile := BoxMesh.new()
	pile.size = Vector3(PILE_WIDTH_M, 1.0, PILE_WIDTH_M)
	pile.material = wood
	var bollard := CylinderMesh.new()
	bollard.top_radius = BOLLARD_RADIUS_M * 1.3
	bollard.bottom_radius = BOLLARD_RADIUS_M
	bollard.height = BOLLARD_HEIGHT_M
	bollard.radial_segments = 10
	bollard.rings = 1
	bollard.material = iron
	var hull := StandardMaterial3D.new()
	hull.albedo_color = BOAT_COLOR
	hull.roughness = 0.8
	hull.cull_mode = BaseMaterial3D.CULL_DISABLED
	var boat := boat_mesh()
	boat.surface_set_material(0, hull)
	# Fase 106: o lanço do cais e o capeamento, caixas de 1 m esticadas, na pedra das paredes (projetada pelo mundo)
	var wall := BoxMesh.new()
	var coping := BoxMesh.new()
	# Fase 127: a cisterna do cais, de aduelas com a cor no vértice
	var cistern := FarmSiloView.cistern_mesh()
	var painted := StandardMaterial3D.new()
	painted.vertex_color_use_as_albedo = true
	painted.vertex_color_is_srgb = true
	painted.roughness = 0.85
	cistern.surface_set_material(0, painted)
	var parts: Array = [[_boards, "Boards", board], [_piles, "Piles", pile], [_bollards, "Bollards", bollard],
			[_boats, "Boats", boat], [_walls, "SeaWall", wall], [_coping, "Coping", coping],
			[_cisterns, "Cisterns", cistern]]
	for pile_kind: int in [GoodDef.Pile.BARREL, GoodDef.Pile.CRATE, GoodDef.Pile.SACK]:
		var piece := CargoKit.mesh(pile_kind)
		if piece != null:
			_cargo[pile_kind] = MultiMeshInstance3D.new()
			parts.append([_cargo[pile_kind], "Cargo%d" % pile_kind, piece])
	for part: Array in parts:
		var layer: MultiMeshInstance3D = part[0]
		layer.name = part[1]
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.mesh = part[2]
		add_child(layer)
	for layer: MultiMeshInstance3D in [_walls, _coping]:
		layer.material_override = BuildingMaterials.walls()
		BuildingMaterials.dress(layer, BuildingMaterials.Wall.STONE, STONE_COLOR, 0.0)
	for pile_kind: int in _cargo:
		if CargoKit.tinted(pile_kind):
			_cargo[pile_kind].multimesh.use_colors = true
	_rope_material.albedo_color = ROPE_COLOR
	_rope_material.roughness = 0.95
	_rope_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_ropes.name = "Ropes"
	_ropes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ropes)
	EventBus.building_placed.connect(func(_building_id: int) -> void: _dirty = true)
	EventBus.building_removed.connect(func(_building_id: int) -> void: _dirty = true)
	EventBus.roads_changed.connect(func(_island_id: int) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func board_count() -> int:
	return _boards.multimesh.instance_count


func pile_count() -> int:
	return _piles.multimesh.instance_count


func bollard_count() -> int:
	return _bollards.multimesh.instance_count


func cistern_count() -> int:
	return _cisterns.multimesh.instance_count


func wall_count() -> int:
	return _walls.multimesh.instance_count


func boat_count() -> int:
	return _boats.multimesh.instance_count


func rope_count() -> int:
	return _rope_spans.size()


## Voltas de cabo nos cabeços (uma por cabo).
func hitch_count() -> int:
	return _hitches.size()


## Os pontos da volta index, de cima (onde o cabo sai para o barco) para baixo.
func hitch_points(index: int) -> PackedVector3Array:
	return _hitches[index]


## Os pontos do cabo index, da ponta no cabeço à ponta no barco.
func rope_points(index: int) -> PackedVector3Array:
	return _rope_spans[index]


## Peças de carga nos cais, de todos os tipos.
func cargo_count() -> int:
	var total := 0
	for layer: MultiMeshInstance3D in _cargo.values():
		total += layer.multimesh.instance_count
	return total


func _process(_delta: float) -> void:
	if _dirty:
		rebuild()


func rebuild() -> void:
	_dirty = false
	var boards: Array[Transform3D] = []
	var piles: Array[Transform3D] = []
	var bollards: Array[Transform3D] = []
	var boats: Array[Transform3D] = []
	var cargo: Dictionary[int, Array] = {}
	var cisterns: Array[Transform3D] = []
	for pile_kind: int in _cargo:
		cargo[pile_kind] = []
	_rope_spans.clear()
	_hitches.clear()
	var world := _simulation.world
	var harbors: Array[BuildingRecord] = []
	for building_id: int in world.building_ids():
		var record := world.building(building_id)
		var def := _simulation.def_of(record)
		if def.kind == BuildingDef.Kind.PIER or def.is_trading_post:
			harbors.append(record)
		var first_bollard := bollards.size()
		var first_boat := boats.size()
		if def.kind == BuildingDef.Kind.PIER:
			var plan := walkway(_simulation, record)
			_pier(plan, boards, piles, bollards)
			var start: Vector3 = plan["start"]
			var direction: Vector3 = plan["direction"]
			var length: float = plan["length"]
			var across := Vector3(-direction.z, 0.0, direction.x)
			_moor(boats, start + direction * (length - BOAT_LENGTH_M * 0.6)
					+ across * (WALK_WIDTH_M * 0.5 + BOAT_BEAM_M * 0.7), direction, direction)
		elif def.is_trading_post:
			var plan := walkway(_simulation, record)
			_quay(plan, boards, piles, bollards, boats, cargo)
			cisterns.append_array(cistern_places(_simulation, record))
		_moor_lines(bollards.slice(first_bollard), boats.slice(first_boat))
	_fill(_boards, boards)
	_fill(_piles, piles)
	_fill(_boats, boats)
	var walls: Array[Transform3D] = []
	var coping: Array[Transform3D] = []
	for record: BuildingRecord in harbors:
		if not _simulation.def_of(record).is_trading_post:
			continue
		var segments := stone_quay(_simulation, record)
		for i: int in segments.size():
			var segment: Array = segments[i]
			_quay_segment(segment, walls, coping)
			if i % SEA_WALL_BOLLARD_EVERY == 1:
				var front: Vector3 = segment[0]
				var outward: Vector3 = segment[1]
				var spot := front - outward * 0.35
				bollards.append(Transform3D(Basis.IDENTITY, Vector3(spot.x, front.y + COPING_M.x + BOLLARD_HEIGHT_M * 0.5, spot.z)))
	_fill(_bollards, bollards)
	_fill(_walls, walls)
	_fill(_coping, coping)
	_fill(_cisterns, cisterns)
	for pile_kind: int in _cargo:
		var places: Array[Transform3D] = []
		places.assign(cargo[pile_kind])
		_fill(_cargo[pile_kind], places)
		if CargoKit.tinted(pile_kind):
			for i: int in places.size():
				_cargo[pile_kind].multimesh.set_instance_color(i, CargoKit.SACK_COLOR)
	_ropes.mesh = rope_mesh(_rope_spans + _hitches, _rope_material)


## Cabos da proa e da popa de cada barco até o cabeço mais perto (do mesmo píer ou cais), dentro de ROPE_MAX_M.
## O cabo sai da volta que ele dá no fuste (Fase 21), do lado do barco.
func _moor_lines(bollards: Array[Transform3D], boats: Array[Transform3D]) -> void:
	var tied: Dictionary[int, int] = {}
	for boat: Transform3D in boats:
		for end: Vector3 in [Vector3(0.0, BOAT_DEPTH_M * 1.2, -BOAT_LENGTH_M * 0.5 + 0.15),
				Vector3(0.0, BOAT_DEPTH_M, BOAT_LENGTH_M * 0.5 - 0.15)]:
			var on_boat := boat * end
			var best := -1
			var best_m := ROPE_MAX_M
			for i: int in bollards.size():
				var top := bollards[i].origin + Vector3(0.0, BOLLARD_HEIGHT_M * 0.3, 0.0)
				if top.distance_to(on_boat) < best_m:
					best_m = top.distance_to(on_boat)
					best = i
			if best < 0:
				continue
			var below: int = tied[best] if tied.has(best) else 0
			tied[best] = below + 1
			var coil := hitch(bollards[best].origin, on_boat, below)
			_hitches.append(coil)
			_rope_spans.append(rope_span(coil[0], on_boat, ROPE_SAG))


## A volta do cabo no cabeço de centro center: uma hélice de HITCH_TURNS voltas em volta do fuste, começando no
## lado virado para toward (de onde o cabo sai) e descendo; below conta os cabos que já estão no cabeço (cada
## um dá as voltas dele mais abaixo).
static func hitch(center: Vector3, toward: Vector3, below: int = 0) -> PackedVector3Array:
	var points := PackedVector3Array()
	var flat := Vector2(toward.x - center.x, toward.z - center.z)
	var start := flat.angle() if flat.length() > 0.001 else 0.0
	var top := BOLLARD_HEIGHT_M * 0.3 - below * HITCH_PITCH_M * (HITCH_TURNS + 0.5)
	var steps := int(HITCH_TURNS * HITCH_SEGMENTS)
	for i: int in steps + 1:
		var t := float(i) / HITCH_SEGMENTS
		var angle := start + t * TAU
		var height := top - t * HITCH_PITCH_M
		# o fuste afina para baixo (raio de BOLLARD_RADIUS_M no pé a 1,3 × no alto)
		var radius := BOLLARD_RADIUS_M * (1.15 + 0.3 * height / BOLLARD_HEIGHT_M) + ROPE_RADIUS_M
		points.append(center + Vector3(cos(angle) * radius, height, sin(angle) * radius))
	return points


## Os pontos de um cabo de from a to caindo em parábola: no meio, sag × o vão abaixo da reta.
static func rope_span(from: Vector3, to: Vector3, sag: float) -> PackedVector3Array:
	var points := PackedVector3Array()
	var drop := from.distance_to(to) * sag
	for i: int in ROPE_SEGMENTS + 1:
		var t := float(i) / ROPE_SEGMENTS
		points.append(from.lerp(to, t) - Vector3(0.0, drop * 4.0 * t * (1.0 - t), 0.0))
	return points


## Uma malha com todos os cabos: um tubo de quatro faces de ROPE_RADIUS_M ao longo de cada lista de pontos.
## Sem cabo, nenhuma malha.
static func rope_mesh(spans: Array[PackedVector3Array], material: Material, radius: float = ROPE_RADIUS_M) -> ArrayMesh:
	if spans.is_empty():
		return null
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for points: PackedVector3Array in spans:
		var rings: Array[PackedVector3Array] = []
		for i: int in points.size():
			var along := (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]).normalized()
			var side := along.cross(Vector3.UP if absf(along.y) < 0.95 else Vector3.RIGHT).normalized()
			var up := side.cross(along)
			var ring := PackedVector3Array()
			for k: int in 4:
				var angle := k * PI * 0.5
				ring.append(points[i] + (side * cos(angle) + up * sin(angle)) * radius)
			rings.append(ring)
		for i: int in rings.size() - 1:
			for k: int in 4:
				var a := rings[i][k]
				var b := rings[i][(k + 1) % 4]
				var c := rings[i + 1][(k + 1) % 4]
				var d := rings[i + 1][k]
				for vertex: Vector3 in [a, b, c, a, c, d]:
					tool.add_vertex(vertex)
	tool.generate_normals()
	var mesh := tool.commit()
	mesh.surface_set_material(0, material)
	return mesh


## O traçado do trapiche: [começo (meio do lado do prédio virado para o mar, no chão), direção no plano
## (Vector3 unitário), comprimento da passarela, largura e fundo da área do prédio, centro da área].
static func walkway(simulation: Simulation, record: BuildingRecord) -> Dictionary:
	var def := simulation.def_of(record)
	var grid := simulation.world.island(record.island_id)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var center := grid.rect_world(area)
	var berth := simulation.harbors().berth_point(record.id)
	var direction: Vector3
	if not is_nan(berth.x):
		direction = Vector3(berth.x - center.x, 0.0, berth.y - center.z)
	else:
		direction = seaward(simulation.world, center, area, simulation.config.cell_size_m, record.rotation)
	# a passarela sai pelo lado do prédio mais virado para o cais
	if absf(direction.x) >= absf(direction.z):
		direction = Vector3(signf(direction.x), 0.0, 0.0)
	else:
		direction = Vector3(0.0, 0.0, signf(direction.z))
	var cell_size := simulation.config.cell_size_m
	var half := Vector2(area.size.x, area.size.y) * cell_size * 0.5
	var reach := half.x if direction.x != 0.0 else half.y
	var start := center + direction * reach
	var length := WALK_DEFAULT_M
	if not is_nan(berth.x):
		length = Vector2(berth.x - start.x, berth.y - start.z).dot(Vector2(direction.x, direction.z)) - BERTH_CLEARANCE_M
	return {
		"center": center,
		"half": half,
		"start": start,
		"direction": direction,
		"length": clampf(length, WALK_MIN_M, WALK_MAX_M),
		"deck": center.y + DECK_LIFT_M,
	}


## Cais do entreposto: tábuas de QUAY_DEPTH_M no lado do mar, na largura do prédio, cabeços na beira, a carga
## no fundo e dois barcos amarrados de comprido na frente.
func _quay(plan: Dictionary, boards: Array[Transform3D], piles: Array[Transform3D], bollards: Array[Transform3D],
		boats: Array[Transform3D], cargo: Dictionary[int, Array]) -> void:
	var half: Vector2 = plan["half"]
	var start: Vector3 = plan["start"]
	var direction: Vector3 = plan["direction"]
	var deck: float = plan["deck"]
	var across := Vector3(-direction.z, 0.0, direction.x)
	var width := (half.y if direction.x != 0.0 else half.x) * 2.0
	_planks(start, direction, across, QUAY_DEPTH_M, width, deck, boards, piles)
	var edge := start + direction * (QUAY_DEPTH_M - 0.3)
	var count := maxi(int(width / QUAY_BOLLARD_STEP_M), 1)
	for i: int in count:
		var spot := edge + across * ((i + 0.5) * width / count - width * 0.5)
		bollards.append(Transform3D(Basis.IDENTITY, Vector3(spot.x, deck + BOLLARD_HEIGHT_M * 0.5, spot.z)))
	var facing := Basis.looking_at(-direction, Vector3.UP)
	for i: int in QUAY_CARGO.size():
		var pile_kind: int = QUAY_CARGO[i]
		if not cargo.has(pile_kind):
			continue
		var spot := start + direction * (CargoKit.ITEM_M * 0.7) + across * ((i - QUAY_CARGO.size() * 0.5 + 0.5) * CargoKit.ITEM_M * 1.1)
		var list: Array = cargo[pile_kind]
		list.append(Transform3D(facing.rotated(Vector3.UP, i * 0.4), Vector3(spot.x, deck, spot.z)))
	for side: float in [-1.0, 1.0]:
		_moor(boats, start + direction * (QUAY_DEPTH_M + BOAT_BEAM_M * 0.8) + across * side * width * 0.25, across,
				direction)


## Fase 127: as cisternas do entreposto — uma de cada lado, no primeiro lanço do cais de pedra que passa CISTERN_CLEAR_M
## da largura do prédio (o cais de tábuas e a carga ficam livres), no meio da plataforma, assentada no alto dela. Sem cais
## de pedra daquele lado (a ilha plana, a terra subindo), sem cisterna.
static func cistern_places(simulation: Simulation, record: BuildingRecord) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var segments := stone_quay(simulation, record)
	if segments.is_empty():
		return result
	var plan := walkway(simulation, record)
	var half: Vector2 = plan["half"]
	var start: Vector3 = plan["start"]
	var direction: Vector3 = plan["direction"]
	var across := Vector3(-direction.z, 0.0, direction.x)
	var width := (half.y if direction.x != 0.0 else half.x) * 2.0
	for side: float in [-1.0, 1.0]:
		for segment: Array in segments:
			var front: Vector3 = segment[0]
			var t := (front - start).dot(across)
			if t * side < width * 0.5 + CISTERN_CLEAR_M:
				continue
			var outward: Vector3 = segment[1]
			var spot := front - outward * ((QUAY_DEPTH_M + STONE_QUAY_BACK_M) * 0.5)
			result.append(Transform3D(Basis(Vector3.UP, side * 0.7), Vector3(spot.x, front.y, spot.z)))
			break
	return result


## Barco a remo de comprido em along, boiando com a quilha BOAT_DRAFT_M abaixo da água. Se ali ainda é praia
## (o cais acaba antes do mar, ou a célula é de mar mas a areia sobe acima da água), anda para o mar (outward) de metro em metro até as duas pontas boiarem; sem mar
## em BOAT_SEARCH_M, fica sem barco.
func _moor(boats: Array[Transform3D], spot: Vector3, along: Vector3, outward: Vector3) -> void:
	var world := _simulation.world
	for meters: int in BOAT_SEARCH_M + 1:
		var place := spot + outward * meters
		var bow := place + along * BOAT_LENGTH_M * 0.5
		var stern := place - along * BOAT_LENGTH_M * 0.5
		if afloat(world, place) and afloat(world, bow) and afloat(world, stern):
			boats.append(Transform3D(Basis.looking_at(along, Vector3.UP), Vector3(place.x, -BOAT_DRAFT_M, place.z)))
			return


## Casco aberto de barco a remo, de frente para −Z: seções de través (proa em ponta, popa estreita), costados e
## fundo ligando uma à outra, dois bancos. A quilha fica em y = 0.
static func boat_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# [z, meia boca em cima, meia boca no fundo, altura da borda]
	var sections: Array = [
		[-BOAT_LENGTH_M * 0.5, 0.0, 0.0, BOAT_DEPTH_M * 1.25],
		[-BOAT_LENGTH_M * 0.25, BOAT_BEAM_M * 0.42, BOAT_BEAM_M * 0.2, BOAT_DEPTH_M * 1.05],
		[0.0, BOAT_BEAM_M * 0.5, BOAT_BEAM_M * 0.28, BOAT_DEPTH_M],
		[BOAT_LENGTH_M * 0.3, BOAT_BEAM_M * 0.45, BOAT_BEAM_M * 0.24, BOAT_DEPTH_M],
		[BOAT_LENGTH_M * 0.5, BOAT_BEAM_M * 0.32, BOAT_BEAM_M * 0.18, BOAT_DEPTH_M * 1.05],
	]
	var rings: Array[PackedVector3Array] = []
	for section: Array in sections:
		var z: float = section[0]
		var top: float = section[1]
		var bottom: float = section[2]
		var rim: float = section[3]
		rings.append(PackedVector3Array([Vector3(-top, rim, z), Vector3(-bottom, 0.0, z), Vector3(bottom, 0.0, z),
				Vector3(top, rim, z)]))
	for i: int in rings.size() - 1:
		for k: int in 3:
			var a := rings[i][k]
			var b := rings[i][k + 1]
			var c := rings[i + 1][k + 1]
			var d := rings[i + 1][k]
			for vertex: Vector3 in [a, b, c, a, c, d]:
				tool.add_vertex(vertex)
	# espelho de popa
	var stern := rings[rings.size() - 1]
	for vertex: Vector3 in [stern[0], stern[1], stern[2], stern[0], stern[2], stern[3]]:
		tool.add_vertex(vertex)
	# bancos: tábuas de través
	for z: float in [-BOAT_LENGTH_M * 0.12, BOAT_LENGTH_M * 0.25]:
		var half := BOAT_BEAM_M * 0.44
		var y := BOAT_DEPTH_M * 0.7
		for vertex: Vector3 in [Vector3(-half, y, z - 0.12), Vector3(half, y, z - 0.12), Vector3(half, y, z + 0.12),
				Vector3(-half, y, z - 0.12), Vector3(half, y, z + 0.12), Vector3(-half, y, z + 0.12)]:
			tool.add_vertex(vertex)
	tool.generate_normals()
	return tool.commit()


## Para onde fica o mar mais perto da área: o lado (dos quatro) em que a água aparece primeiro, andando
## de metro em metro a partir da borda até WALK_MAX_M. Sem água à vista, o lado oposto à entrada.
static func seaward(world: WorldState, center: Vector3, area: Rect2i, cell_size: float, rotation: int) -> Vector3:
	var best := Vector3.ZERO
	var best_m := INF
	for side: Vector3 in [Vector3(1.0, 0.0, 0.0), Vector3(-1.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0), Vector3(0.0, 0.0, -1.0)]:
		var reach := (area.size.x if side.x != 0.0 else area.size.y) * cell_size * 0.5
		for meters: int in int(WALK_MAX_M):
			var spot := center + side * (reach + meters)
			if is_sea(world, spot):
				if meters < best_m:
					best_m = meters
					best = side
				break
	if best_m < INF:
		return best
	var back := -Footprint.front_direction(rotation)
	return Vector3(back.x, 0.0, back.y)


## O ponto é mar: fora de toda ilha, ou numa célula de mar dela (a altura não serve: a ilha plana fica no zero).
static func is_sea(world: WorldState, spot: Vector3) -> bool:
	for grid: IslandGrid in world.islands:
		if grid.world_rect().has_point(Vector2(spot.x, spot.z)):
			return grid.ground_at(grid.world_to_cell(spot)) == IslandGrid.Ground.SEA
	return true


## O ponto é mar com fundo abaixo da quilha do barco (a praia é célula de mar e fica acima da água).
static func afloat(world: WorldState, spot: Vector3) -> bool:
	if not is_sea(world, spot):
		return false
	for grid: IslandGrid in world.islands:
		if grid.world_rect().has_point(Vector2(spot.x, spot.z)) and not grid.corner_heights.is_empty():
			return grid.height_at(spot.x, spot.z) < -BOAT_DRAFT_M - BOAT_KEEL_CLEARANCE_M
	return true


## Tabuleiro sobre a área, passarela, estacas nas bordas e dois cabeços na ponta.
func _pier(plan: Dictionary, boards: Array[Transform3D], piles: Array[Transform3D], bollards: Array[Transform3D]) -> void:
	var center: Vector3 = plan["center"]
	var half: Vector2 = plan["half"]
	var start: Vector3 = plan["start"]
	var direction: Vector3 = plan["direction"]
	var length: float = plan["length"]
	var deck: float = plan["deck"]
	var across := Vector3(-direction.z, 0.0, direction.x)
	# a área: da parte de trás (oposta ao mar) até o começo da passarela
	var depth := (half.x if direction.x != 0.0 else half.y) * 2.0
	var area_width := (half.y if direction.x != 0.0 else half.x) * 2.0
	var back := center - direction * depth * 0.5
	_planks(back, direction, across, depth, area_width, deck, boards, piles)
	_planks(start, direction, across, length, WALK_WIDTH_M, deck, boards, piles)
	var tip := start + direction * (length - 0.5)
	for side: float in [-1.0, 1.0]:
		var spot := tip + across * side * (WALK_WIDTH_M * 0.5 - 0.3)
		bollards.append(Transform3D(Basis.IDENTITY, Vector3(spot.x, deck + BOLLARD_HEIGHT_M * 0.5, spot.z)))


## Tábuas de través de from até from + direction × length, na largura width, e as estacas nas duas bordas.
func _planks(from: Vector3, direction: Vector3, across: Vector3, length: float, width: float, deck: float,
		boards: Array[Transform3D], piles: Array[Transform3D]) -> void:
	var basis := Basis(across, Vector3.UP, -direction)
	var board := basis * Basis.from_scale(Vector3(width, 1.0, 1.0))
	var step := BOARD_WIDTH_M + BOARD_GAP_M
	var count := maxi(int(length / step), 1)
	for i: int in count:
		var spot := from + direction * ((i + 0.5) * step)
		boards.append(Transform3D(board, Vector3(spot.x, deck - BOARD_THICKNESS_M * 0.5, spot.z)))
	var world := _simulation.world
	var pile_count := maxi(int(length / PILE_STEP_M), 1)
	for i: int in pile_count + 1:
		for side: float in [-1.0, 1.0]:
			var spot := from + direction * minf(i * PILE_STEP_M, length) + across * side * (width * 0.5 - PILE_WIDTH_M)
			var bottom := world.surface_height(spot.x, spot.z) - PILE_SINK_M
			var top := deck - BOARD_THICKNESS_M
			if top <= bottom:
				continue
			piles.append(Transform3D(Basis.from_scale(Vector3(1.0, top - bottom, 1.0)),
					Vector3(spot.x, (top + bottom) * 0.5, spot.z)))


## Fase 106: os lanços do cais de pedra de um entreposto — cada um [meio da beira (no alto do cais), para o mar, largura].
## Saem do meio da frente para os dois lados, ao longo da costa, até STONE_QUAY_REACH_M além do prédio; param do lado em
## que a terra na beira sobe mais que STONE_QUAY_RISE_M acima do cais (a falésia ou o morro: o cais sumiria nele).
static func stone_quay(simulation: Simulation, record: BuildingRecord) -> Array[Array]:
	var segments: Array[Array] = []
	var grid := simulation.world.island(record.island_id)
	if grid == null or grid.flat:
		return segments
	var plan := walkway(simulation, record)
	var half: Vector2 = plan["half"]
	var start: Vector3 = plan["start"]
	var direction: Vector3 = plan["direction"]
	var top: float = plan["deck"] - STONE_QUAY_BELOW_DECK_M
	var across := Vector3(-direction.z, 0.0, direction.x)
	var width := (half.y if direction.x != 0.0 else half.x) * 2.0
	var front := start + direction * QUAY_DEPTH_M
	var reach := width * 0.5 + STONE_QUAY_REACH_M
	var count := ceili(reach / STONE_QUAY_STEP_M)
	for side: float in [-1.0, 1.0]:
		for k: int in count:
			var t := side * (k + 0.5) * STONE_QUAY_STEP_M
			var edge := front + across * t
			var inland := edge - direction * (QUAY_DEPTH_M + STONE_QUAY_BACK_M)
			if simulation.world.surface_height(inland.x, inland.z) > top + STONE_QUAY_RISE_M:
				break
			segments.append([Vector3(edge.x, top, edge.z), direction, STONE_QUAY_STEP_M])
	return segments


## O lanço: a plataforma de pedra da beira para dentro, do fundo até o alto (a parte enterrada some no chão), e o
## capeamento na beira, um pouco mais largo e saindo para o mar.
func _quay_segment(segment: Array, walls: Array[Transform3D], coping: Array[Transform3D]) -> void:
	var front: Vector3 = segment[0]
	var outward: Vector3 = segment[1]
	var length: float = segment[2]
	var along := Vector3(-outward.z, 0.0, outward.x)
	# base de mão direita (com +outward no z ela fica espelhada e as faces se invertem)
	var basis := Basis(along, Vector3.UP, -outward)
	var depth := QUAY_DEPTH_M + STONE_QUAY_BACK_M
	var middle := front - outward * depth * 0.5
	var height := front.y - SEA_WALL_BOTTOM_M
	walls.append(Transform3D(basis * Basis.from_scale(Vector3(length + 0.01, height, depth)),
			Vector3(middle.x, (front.y + SEA_WALL_BOTTOM_M) * 0.5, middle.z)))
	var cap := front - outward * (COPING_M.y * 0.5 - 0.12)
	coping.append(Transform3D(basis * Basis.from_scale(Vector3(length + 0.02, COPING_M.x, COPING_M.y)),
			Vector3(cap.x, front.y + COPING_M.x * 0.5, cap.z)))

static func _fill(layer: MultiMeshInstance3D, items: Array[Transform3D]) -> void:
	layer.multimesh.instance_count = items.size()
	for i: int in items.size():
		layer.multimesh.set_instance_transform(i, items[i])
