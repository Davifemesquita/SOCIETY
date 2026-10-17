class_name HarborView
extends Node3D
## Porto (Fase 15): o píer vira trapiche de madeira. Um tabuleiro de tábuas sobre estacas cobre a área dele e
## segue como passarela até perto do cais (Harbors.berth_point: onde o navio encosta), com cabeços de
## amarração na ponta. Sem cais (píer sem estrada até um entreposto), a passarela vai para o mar mais perto
## (`seaward`). Tábuas, estacas e cabeços são caixas e cilindros, um MultiMesh por peça, refeitos
## quando prédio, estrada ou mundo muda. Só lê o mundo.

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
const WOOD_COLOR := Color(0.45, 0.33, 0.22)
const IRON_COLOR := Color(0.16, 0.16, 0.17)

var _simulation: Simulation
var _boards := MultiMeshInstance3D.new()
var _piles := MultiMeshInstance3D.new()
var _bollards := MultiMeshInstance3D.new()
var _dirty: bool = false


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var wood := StandardMaterial3D.new()
	wood.albedo_color = WOOD_COLOR
	wood.roughness = 0.85
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
	for part: Array in [[_boards, "Boards", board], [_piles, "Piles", pile], [_bollards, "Bollards", bollard]]:
		var layer: MultiMeshInstance3D = part[0]
		layer.name = part[1]
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.mesh = part[2]
		add_child(layer)
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


func _process(_delta: float) -> void:
	if _dirty:
		rebuild()


func rebuild() -> void:
	_dirty = false
	var boards: Array[Transform3D] = []
	var piles: Array[Transform3D] = []
	var bollards: Array[Transform3D] = []
	var world := _simulation.world
	for building_id: int in world.building_ids():
		var record := world.building(building_id)
		var def := _simulation.def_of(record)
		if def.kind != BuildingDef.Kind.PIER:
			continue
		var plan := walkway(_simulation, record)
		_pier(plan, boards, piles, bollards)
	_fill(_boards, boards)
	_fill(_piles, piles)
	_fill(_bollards, bollards)


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


static func _fill(layer: MultiMeshInstance3D, items: Array[Transform3D]) -> void:
	layer.multimesh.instance_count = items.size()
	for i: int in items.size():
		layer.multimesh.set_instance_transform(i, items[i])
