class_name PalapaView
extends Node3D
## Fase 204: os guarda-sóis de palha nas praias tropicais. Em volta de cada entreposto e cabana de pesca das ilhas tropicais
## (HOSTS), até PER_HOST células de areia (terra baixa, até SAND_TOP_M, com o mar a até SEA_CELLS células), livres (sem prédio,
## estrada, trilho nem árvore, fora do barco virado e das redes), a mais de near_of e até SPREAD_CELLS além disso, pela ordem
## da distância e afastadas SPACING_CELLS umas das outras (`cells`); em cada uma o guarda-sol de folhas de palmeira num mastro,
## com a franja recortada, e um banco de toras (`palapa_mesh`), girado à toa. O recheio deixa as células limpas. Um MultiMesh;
## nada no save; refeito na obra, na demolição, na estrada, na derrubada de árvores e ao trocar de mundo.

const HOSTS: Array[StringName] = [&"trading_post", &"fishery"]
const PER_HOST := 3
const MIN_CELLS := 3.5
## Em volta do entreposto, além do cais de pedra da Fase 106 (até STONE_QUAY_REACH_M além do prédio, e o cais é só desenho:
## as células debaixo dele parecem areia livre).
const QUAY_CLEAR_CELLS := 8.0
const SPREAD_CELLS := 8.0
const SPACING_CELLS := 3.0
const SEA_CELLS := 2
const SAND_TOP_M := 1.8
const MAX_RELIEF_M := 0.7
## O guarda-sol: o mastro, o raio da palha, a altura da beira e do bico; os gomos e a franja.
const POLE_M := 2.3
const ROOF_R_M := 1.25
const EAVE_M := 1.85
const PEAK_M := 2.6
const GORES := 12
const POLE := Color(0.45, 0.33, 0.21)
const THATCH := Color(0.74, 0.6, 0.34)
const THATCH_DARK := Color(0.58, 0.45, 0.24)
const LOG := Color(0.5, 0.38, 0.25)

var _simulation: Simulation
var _palapas := MultiMeshInstance3D.new()
## Os lugares dos guarda-sóis (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.95
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_palapas.name = "Palapas"
	_palapas.multimesh = MultiMesh.new()
	_palapas.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_palapas.multimesh.mesh = palapa_mesh()
	_palapas.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_palapas.material_override = material
	add_child(_palapas)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.trees_changed.connect(func(_island_id: int, _area: Rect2i) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func palapa_count() -> int:
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
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		for cell: Vector2i in cells(world, _simulation.data, island_id):
			var at := grid.cell_world(cell)
			at.y = TerrainDetail.shown_at(grid, at.x, at.z)
			var turn := float(FireflyView.cell_hash(island_id, cell.x, cell.y, 204) % 628) / 100.0
			places.append(Transform3D(Basis(Vector3.UP, turn), at))
	_palapas.multimesh.instance_count = places.size()
	for i: int in places.size():
		_palapas.multimesh.set_instance_transform(i, places[i])


## As células dos guarda-sóis da ilha. Vazio nas temperadas e na ilha plana.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, bool]:
	var result: Dictionary[Vector2i, bool] = {}
	var grid := world.island(island_id)
	if grid == null or grid.flat or not world.is_tropical(island_id, data):
		return result
	var hosts: Array[int] = []
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id == island_id and record.def_id in HOSTS:
			hosts.append(id)
	if hosts.is_empty():
		return result
	hosts.sort()
	var taken: Dictionary[Vector2i, bool] = {}
	taken.merge(FishNetView.cells(world, data, island_id))
	for cell: Vector2i in BeachBoatView.cells(world, data, island_id):
		taken[cell] = true
	for id: int in hosts:
		var record := world.buildings[id]
		var def := data.building(record.def_id)
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		var middle := Vector2(area.position) + Vector2(area.size) * 0.5
		var near := near_of(record.def_id, area)
		var found: Array[Vector2i] = []
		var ring := area.grow(ceili(near + SPREAD_CELLS))
		for y: int in range(ring.position.y, ring.end.y):
			for x: int in range(ring.position.x, ring.end.x):
				var cell := Vector2i(x, y)
				var apart := (Vector2(cell) + Vector2(0.5, 0.5)).distance_to(middle)
				if apart < near or apart > near + SPREAD_CELLS or taken.has(cell) or result.has(cell):
					continue
				if _sand(grid, cell):
					found.append(cell)
		found.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			var da := (Vector2(a) + Vector2(0.5, 0.5)).distance_squared_to(middle)
			var db := (Vector2(b) + Vector2(0.5, 0.5)).distance_squared_to(middle)
			return da < db or (da == db and (a.y < b.y or (a.y == b.y and a.x < b.x))))
		var picked: Array[Vector2i] = []
		for cell: Vector2i in found:
			if picked.size() >= PER_HOST:
				break
			var close := false
			for other: Vector2i in result:
				if Vector2(other).distance_to(Vector2(cell)) < SPACING_CELLS:
					close = true
					break
			if not close:
				picked.append(cell)
				result[cell] = true
	return result


## Se a célula é areia livre: terra baixa e quase plana, sem prédio, estrada, trilho nem árvore, com o mar a até SEA_CELLS.
static func _sand(grid: IslandGrid, cell: Vector2i) -> bool:
	if not grid.in_bounds(cell):
		return false
	var index := grid.index(cell)
	if grid.ground[index] != IslandGrid.Ground.LAND or grid.occupancy[index] != 0 \
			or grid.roads[index] != IslandGrid.Road.NONE or grid.rails[index] != 0 or grid.trees[index] > 0:
		return false
	var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
	if corners.y > SAND_TOP_M or corners.y - corners.x > MAX_RELIEF_M:
		return false
	for dy: int in range(-SEA_CELLS, SEA_CELLS + 1):
		for dx: int in range(-SEA_CELLS, SEA_CELLS + 1):
			var next := cell + Vector2i(dx, dy)
			if grid.in_bounds(next) and grid.ground[grid.index(next)] == IslandGrid.Ground.SEA:
				return true
	return false


## O guarda-sol com o pé no zero: o mastro, o cone de palha dos gomos alternando o tom, a franja de pontas recortadas caindo da
## beira, o bico amarrado e o banco de duas toras deitadas ao lado.
static func palapa_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.cylinder(tool, Vector3.ZERO, Vector3(0.0, POLE_M + 0.15, 0.0), 0.07, POLE, 8)
	var peak := Vector3(0.0, PEAK_M, 0.0)
	for g: int in GORES:
		var a0 := TAU * g / GORES
		var a1 := TAU * (g + 1) / GORES
		var p0 := Vector3(cos(a0) * ROOF_R_M, EAVE_M, sin(a0) * ROOF_R_M)
		var p1 := Vector3(cos(a1) * ROOF_R_M, EAVE_M, sin(a1) * ROOF_R_M)
		var tone := THATCH if g % 2 == 0 else THATCH_DARK
		VertexShapes.tri(tool, peak, p0, p1, tone)
		# a franja: duas pontas por gomo caindo da beira
		for half: int in 2:
			var b0 := p0.lerp(p1, half * 0.5)
			var b1 := p0.lerp(p1, half * 0.5 + 0.5)
			var tip := (b0 + b1) * 0.5 * 1.04 + Vector3(0.0, -0.22 - 0.06 * ((g + half) % 3), 0.0)
			VertexShapes.tri(tool, b0, tip, b1, THATCH_DARK)
	# o bico amarrado em cima
	VertexShapes.cylinder(tool, peak - Vector3(0.0, 0.08, 0.0), peak + Vector3(0.0, 0.12, 0.0), 0.08, THATCH_DARK, 8)
	# o banco: duas toras deitadas lado a lado
	for side: float in [-0.12, 0.12]:
		VertexShapes.cylinder(tool, Vector3(-0.7, 0.14, 0.65 + side), Vector3(0.7, 0.14, 0.65 + side), 0.12, LOG, 8)
	tool.generate_normals()
	return tool.commit()


## A distância mínima (em células, do meio do prédio) dos guarda-sóis em volta do anfitrião: a metade dele mais MIN_CELLS, ou
## mais QUAY_CLEAR_CELLS no entreposto (o cais de pedra).
static func near_of(def_id: StringName, area: Rect2i) -> float:
	return maxf(area.size.x, area.size.y) * 0.5 + (QUAY_CLEAR_CELLS if def_id == &"trading_post" else MIN_CELLS)
