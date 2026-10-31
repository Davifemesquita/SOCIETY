class_name SpoilTipView
extends Node3D
## Fase 136: a vagoneta e o monte de rejeito das minas. Encostado num lado de cada mina (o de +X da frente, o outro ou o
## de trás, o primeiro com duas células livres em linha, de terra, sem árvore e quase planas), um trilho curto sai da
## parede sobre cavaletes de madeira e sobe até a beira de um monte de pedra solta, na cor do rejeito da mina (`sites`,
## `track`, `heap_mesh`). Enquanto a mina produz, a vagoneta sai cheia da boca, vira o rejeito na ponta e volta vazia
## (`cart_pose`, no tempo de jogo: para na pausa); parada, fica na boca. O monte e o trilho são uma malha só para o
## arquipélago; a vagoneta e a carga, dois MultiMesh com a caixa fixa do arquipélago. O recheio deixa as duas células
## limpas (`ScatterView.island_context`). Nada no save; refeito na obra, na demolição, na estrada, no trilho, na derrubada
## de árvores e ao trocar de mundo.

const MAX_RELIEF_M := 1.0
## O monte: raio da base, altura e as faces em volta; o rejeito pela jazida da mina.
const HEAP_RADIUS_M := 1.1
const HEAP_HEIGHT_M := 1.25
const HEAP_SIDES := 14
const SPOIL_COLORS: Dictionary[StringName, Color] = {
	&"coal": Color(0.17, 0.16, 0.16),
	&"iron_ore": Color(0.42, 0.33, 0.27),
	&"gold": Color(0.56, 0.53, 0.48),
}
const SPOIL_COLOR := Color(0.47, 0.45, 0.42)
## O trilho: bitola, a altura da saída sobre o piso da mina, dormentes a cada SLEEPER_STEP_M e cavaletes até o chão.
const GAUGE_M := 0.5
const FLOOR_LIFT_M := 0.25
const SLEEPER_STEP_M := 0.42
## A ponta do trilho fica TIP_BACK_M antes do meio do monte, TIP_BELOW_M abaixo do cume.
const TIP_BACK_M := 0.55
const TIP_BELOW_M := 0.35
## A vagoneta: meio comprimento e a volta (sai, vira, volta e espera), com o giro de virar.
const CART_HALF_M := 0.38
const CYCLE_S := 14.0
const OUT_S := 5.0
const TIP_S := 2.0
const BACK_S := 5.0
const TIP_RAD := 0.85
const WOOD := Color(0.4, 0.3, 0.2)
const IRON := Color(0.22, 0.21, 0.21)
const RAIL := Color(0.3, 0.29, 0.28)

var _simulation: Simulation
var _tips := MeshInstance3D.new()
var _carts := MultiMeshInstance3D.new()
var _loads := MultiMeshInstance3D.new()
## Por mina: [id, começo do trilho, ponta do trilho] (mundo).
var _tracks: Array[Array] = []
var _time: float = 0.0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	_tips.name = "Tips"
	_tips.material_override = material
	add_child(_tips)
	for part: Array in [[_carts, "Carts", cart_mesh(), false], [_loads, "Loads", load_mesh(), true]]:
		var layer: MultiMeshInstance3D = part[0]
		layer.name = part[1]
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.use_colors = part[3]
		layer.multimesh.mesh = part[2]
		layer.material_override = material
		add_child(layer)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.trees_changed.connect(func(_island_id: int, _area: Rect2i) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func tip_count() -> int:
	return _tracks.size()


func cart_transform(index: int) -> Transform3D:
	return _carts.multimesh.get_instance_transform(index)


## Anda o relógio das vagonetas à mão (testes e capturas com o jogo pausado).
func advance(seconds: float) -> void:
	_time += seconds
	_roll()


func _mark(_id: int) -> void:
	_dirty = true


func _process(delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()
	var step := delta * GameClock.clock.speed_multiplier()
	if step > 0.0:
		advance(step)


func rebuild() -> void:
	_dirty = false
	_tracks.clear()
	var world := _simulation.world
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var colors: Array[Color] = []
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		var found := sites(world, _simulation.data, island_id)
		for mine_id: int in found:
			var record := world.building(mine_id)
			var site: Array = found[mine_id]
			var ends := track(grid, _simulation.def_of(record), record, site)
			var color: Color = SPOIL_COLORS.get(_simulation.def_of(record).deposit, SPOIL_COLOR)
			var heap_at: Vector3 = ends[2]
			_heap(tool, heap_at, color, mine_id)
			_rails(tool, grid, ends[0], ends[1])
			_tracks.append([mine_id, ends[0], ends[1]])
			colors.append(color)
	if _tracks.is_empty():
		_tips.mesh = null
	else:
		tool.generate_normals()
		_tips.mesh = tool.commit()
	for layer: MultiMeshInstance3D in [_carts, _loads]:
		layer.multimesh.instance_count = _tracks.size()
		layer.multimesh.custom_aabb = WorldBounds.of(_simulation.config)
	for i: int in colors.size():
		_loads.multimesh.set_instance_color(i, colors[i])
	_roll()


func _roll() -> void:
	var world := _simulation.world
	for i: int in _tracks.size():
		var entry: Array = _tracks[i]
		var mine_id: int = entry[0]
		var record := world.building(mine_id)
		var working := record != null and record.state == BuildingRecord.State.PRODUCING and not record.paused
		var start: Vector3 = entry[1]
		var tip: Vector3 = entry[2]
		var pose := cart_pose(start, tip, _time + phase_of(mine_id), working)
		_carts.multimesh.set_instance_transform(i, pose)
		# a carga vai cheia na ida e some depois de virar
		var full := loaded(_time + phase_of(mine_id), working)
		_loads.multimesh.set_instance_transform(i, pose if full else Transform3D(Basis.from_scale(Vector3.ZERO), pose.origin))


## O lugar do monte de cada mina da ilha → [a célula encostada na mina, o lado (para fora)]. O lado é o de +X da frente,
## o oposto ou o de trás, o primeiro com as duas células em linha livres (sem prédio, estrada, trilho nem árvore, fora do
## largo e da alameda), de terra e quase planas.
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	var result: Dictionary[int, Array] = {}
	var grid := world.island(island_id)
	if grid == null:
		return result
	var ids: Array[int] = []
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id == island_id and data.building(record.def_id).silhouette == BuildingDef.Silhouette.HEADFRAME:
			ids.append(id)
	if ids.is_empty():
		return result
	ids.sort()
	var taken: Dictionary[Vector2i, bool] = {}
	if not grid.flat:
		taken.merge(ForecourtView.cells(world, data, island_id))
		taken.merge(AvenueView.cells(world, island_id))
	for id: int in ids:
		var record := world.buildings[id]
		var def := data.building(record.def_id)
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		var front := Footprint.front_direction(record.rotation)
		var right := Vector2i(-front.y, front.x)
		for side: Vector2i in [right, -right, -front]:
			var first := _beside(area, side)
			var cells: Array[Vector2i] = [first, first + side]
			var free := true
			for cell: Vector2i in cells:
				if not grid.in_bounds(cell) or taken.has(cell):
					free = false
					break
				var index := grid.index(cell)
				# a ilha plana (testes, saves antigos) não tem chão nem árvores na grade
				if not grid.is_land(cell) or grid.occupancy[index] != 0 or grid.roads[index] != IslandGrid.Road.NONE \
						or grid.rails[index] != 0 or (not grid.flat and grid.trees[index] > 0):
					free = false
					break
			if not free:
				continue
			var corners := BuildingKit.corner_range(grid, Rect2i(first.min(first + side), Vector2i.ONE + side.abs()))
			if corners.y - corners.x > MAX_RELIEF_M:
				continue
			for cell: Vector2i in cells:
				taken[cell] = true
			result[id] = [first, side]
			break
	return result


## As duas células de cada monte da ilha (o recheio as deixa limpas) → o id da mina.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}
	var found := sites(world, data, island_id)
	for mine_id: int in found:
		var site: Array = found[mine_id]
		var first: Vector2i = site[0]
		var side: Vector2i = site[1]
		result[first] = mine_id
		result[first + side] = mine_id
	return result


## A célula de fora encostada no meio do lado side da área.
static func _beside(area: Rect2i, side: Vector2i) -> Vector2i:
	var middle := area.position + area.size / 2
	if side.x > 0:
		return Vector2i(area.end.x, middle.y)
	if side.x < 0:
		return Vector2i(area.position.x - 1, middle.y)
	if side.y > 0:
		return Vector2i(middle.x, area.end.y)
	return Vector2i(middle.x, area.position.y - 1)


## [começo do trilho na parede da mina, ponta do trilho sobre o monte, pé do meio do monte] no mundo.
static func track(grid: IslandGrid, def: BuildingDef, record: BuildingRecord, site: Array) -> Array[Vector3]:
	var first: Vector2i = site[0]
	var side: Vector2i = site[1]
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var out := Vector3(side.x, 0.0, side.y)
	var floor_y := BuildingKit.seat(grid, area).y + FLOOR_LIFT_M
	var near := grid.cell_world(first) - out * (grid.cell_size * 0.5 + 0.15)
	var far := grid.cell_world(first + side) + out * 0.15
	var heap := Vector3(far.x, grid.height_at(far.x, far.z), far.z)
	var tip := heap - out * TIP_BACK_M
	tip.y = maxf(floor_y, heap.y + HEAP_HEIGHT_M - TIP_BELOW_M)
	return [Vector3(near.x, floor_y, near.z), tip, heap]


## A vagoneta no instante time: sai da boca até a ponta (OUT_S), vira o rejeito (TIP_S, a frente baixando em volta do eixo
## da frente), volta (BACK_S) e espera na boca o resto da volta; parada (sem produzir), fica na boca.
static func cart_pose(start: Vector3, tip: Vector3, time: float, working: bool) -> Transform3D:
	var along := tip - start
	var length := along.length()
	var flat := Vector3(along.x, 0.0, along.z).normalized()
	var basis := Basis.looking_at(along.normalized(), Vector3.UP)
	var first := minf(CART_HALF_M + 0.1, length * 0.5) / length
	var last := maxf(first, 1.0 - CART_HALF_M / length)
	var s := first
	var tilt := 0.0
	if working:
		var t := fposmod(time, CYCLE_S)
		if t < OUT_S:
			s = lerpf(first, last, smoothstep(0.0, 1.0, t / OUT_S))
		elif t < OUT_S + TIP_S:
			s = last
			tilt = sin(PI * (t - OUT_S) / TIP_S) * TIP_RAD
		elif t < OUT_S + TIP_S + BACK_S:
			s = lerpf(last, first, smoothstep(0.0, 1.0, (t - OUT_S - TIP_S) / BACK_S))
	var origin := start.lerp(tip, s)
	if tilt == 0.0:
		return Transform3D(basis, origin)
	# vira em volta do eixo das rodas da frente: a frente (−Z) desce
	var pivot := Vector3(0.0, 0.0, -CART_HALF_M)
	var turn := Transform3D(Basis.IDENTITY, pivot) * Transform3D(Basis(Vector3.RIGHT, -tilt), Vector3.ZERO) \
			* Transform3D(Basis.IDENTITY, -pivot)
	return Transform3D(basis, origin) * turn if flat != Vector3.ZERO else Transform3D(basis, origin)


## O adianto da volta da vagoneta de cada mina (s): as minas não andam juntas.
static func phase_of(mine_id: int) -> float:
	return float(posmod(mine_id * 7, 13))


## Se a vagoneta vai cheia no instante time: da boca até o meio da virada.
static func loaded(time: float, working: bool) -> bool:
	if not working:
		return true
	var t := fposmod(time, CYCLE_S)
	return t < OUT_S + TIP_S * 0.5 or t >= OUT_S + TIP_S + BACK_S


## O monte de pedra solta: um cone de HEAP_SIDES faces com o raio e a altura irregulares e o tom de cada face (pelo hash
## da mina) e pedras soltas em volta do pé.
static func _heap(tool: SurfaceTool, center: Vector3, color: Color, seed_value: int) -> void:
	var rings: Array[PackedVector3Array] = []
	var heights: Array[float] = [0.0, 0.45, 0.8]
	var widths: Array[float] = [1.0, 0.72, 0.38]
	for ring: int in heights.size():
		var points := PackedVector3Array()
		for k: int in HEAP_SIDES:
			var noise := float(absi(hash([seed_value, ring, k])) % 1000) / 1000.0
			var angle := TAU * k / HEAP_SIDES
			var radius := HEAP_RADIUS_M * widths[ring] * (0.85 + 0.3 * noise)
			var lift := HEAP_HEIGHT_M * heights[ring] + (0.0 if ring == 0 else (noise - 0.5) * 0.12)
			points.append(center + Vector3(cos(angle) * radius, lift - (0.1 if ring == 0 else 0.0), sin(angle) * radius))
		rings.append(points)
	var top := center + Vector3(0.0, HEAP_HEIGHT_M, 0.0)
	for ring: int in rings.size():
		for k: int in HEAP_SIDES:
			var j := (k + 1) % HEAP_SIDES
			# tom de cada face pelo hash (alternado, parecia um guarda-chuva)
			var tone := float(absi(hash([seed_value, ring, k, &"face"])) % 1000) / 1000.0
			var shade := color.darkened(0.2 * tone) if tone < 0.6 else color.lightened(0.15 * (tone - 0.6))
			if ring + 1 < rings.size():
				VertexShapes.quad(tool, rings[ring][k], rings[ring][j], rings[ring + 1][j], rings[ring + 1][k], shade)
			else:
				VertexShapes.tri(tool, rings[ring][k], rings[ring][j], top, shade)
	for k: int in 7:
		var noise := absi(hash([seed_value, &"stone", k]))
		var angle := TAU * float(noise % 360) / 360.0
		var radius := HEAP_RADIUS_M * (1.0 + float(noise / 360 % 40) / 100.0)
		var size := 0.05 + float(noise / 14400 % 10) / 160.0
		var at := center + Vector3(cos(angle) * radius, size * 0.5 - 0.05, sin(angle) * radius)
		VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.UP, angle), at), Vector3(size, size * 0.7, size * 1.2),
				color.darkened(0.2))


## O trilho do começo à ponta: os dois trilhos de ferro, os dormentes, os cavaletes (dois esteios e a travessa) onde o
## trilho passa acima do chão e o batente na ponta.
static func _rails(tool: SurfaceTool, grid: IslandGrid, start: Vector3, tip: Vector3) -> void:
	var along := tip - start
	var flat := Vector3(along.x, 0.0, along.z).normalized()
	var across := Vector3(-flat.z, 0.0, flat.x)
	for side: float in [-1.0, 1.0]:
		var offset := across * GAUGE_M * 0.5 * side + Vector3(0.0, -0.02, 0.0)
		VertexShapes.strut(tool, start + offset, tip + offset, 0.025, 0.02, RAIL)
	var steps := maxi(2, ceili(along.length() / SLEEPER_STEP_M))
	for k: int in steps + 1:
		var at := start.lerp(tip, float(k) / steps) + Vector3(0.0, -0.065, 0.0)
		VertexShapes.oriented_box(tool, Transform3D(Basis.looking_at(across, Vector3.UP), at),
				Vector3(0.06, 0.03, GAUGE_M * 0.5 + 0.18), WOOD)
		var ground := grid.height_at(at.x, at.z)
		if at.y - ground > 0.15 and k % 2 == 0:
			for side: float in [-1.0, 1.0]:
				var foot := at + across * (GAUGE_M * 0.5 + 0.1) * side
				VertexShapes.strut(tool, Vector3(foot.x, ground - 0.1, foot.z), foot, 0.045, 0.045, WOOD)
			VertexShapes.strut(tool, at - across * (GAUGE_M * 0.5 + 0.1) + Vector3(0.0, -(at.y - ground) * 0.5, 0.0),
					at + across * (GAUGE_M * 0.5 + 0.1) + Vector3(0.0, -(at.y - ground) * 0.5, 0.0), 0.03, 0.03, WOOD)
	VertexShapes.oriented_box(tool, Transform3D(Basis.looking_at(across, Vector3.UP), tip + flat * 0.08 + Vector3(0.0, 0.06, 0.0)),
			Vector3(0.08, 0.08, GAUGE_M * 0.5 + 0.12), WOOD)


## A vagoneta de frente para −Z, com as rodas sobre o zero: quatro rodas de ferro, o chassi e a caçamba de chapa com os
## reforços.
static func cart_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x: float in [-GAUGE_M * 0.5, GAUGE_M * 0.5]:
		for z: float in [-CART_HALF_M * 0.62, CART_HALF_M * 0.62]:
			VertexShapes.cylinder(tool, Vector3(x - 0.025, 0.11, z), Vector3(x + 0.025, 0.11, z), 0.11, IRON, 10)
	VertexShapes.box(tool, Vector3(0.0, 0.25, 0.0), Vector3(0.27, 0.035, CART_HALF_M), WOOD)
	VertexShapes.box(tool, Vector3(0.0, 0.46, 0.0), Vector3(0.31, 0.18, CART_HALF_M - 0.02), Color(0.32, 0.27, 0.23))
	for z: float in [-CART_HALF_M + 0.06, 0.0, CART_HALF_M - 0.06]:
		VertexShapes.box(tool, Vector3(0.0, 0.46, z), Vector3(0.325, 0.19, 0.025), IRON)
	tool.generate_normals()
	return tool.commit()


## A carga da vagoneta: o monte de pedra que passa da borda da caçamba (tingido pela instância).
static func load_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var low := 0.6
	var corners: Array[Vector3] = [Vector3(-0.29, low, -0.34), Vector3(0.29, low, -0.34), Vector3(0.29, low, 0.34),
			Vector3(-0.29, low, 0.34)]
	var top := Vector3(0.0, low + 0.2, 0.02)
	var ridge := [Vector3(-0.12, low + 0.16, -0.18), Vector3(0.14, low + 0.17, 0.16)]
	for k: int in 4:
		var a: Vector3 = corners[k]
		var b: Vector3 = corners[(k + 1) % 4]
		VertexShapes.tri(tool, a, top, b, Color.WHITE)
	for point: Vector3 in ridge:
		VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.UP, point.x * 5.0), point), Vector3(0.09, 0.05, 0.08),
				Color(0.85, 0.85, 0.85))
	tool.generate_normals()
	return tool.commit()
