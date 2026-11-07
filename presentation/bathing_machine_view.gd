class_name BathingMachineView
extends Node3D
## Fase 233: as cabines de banho. Nas ilhas temperadas, perto de cada entreposto (além do cais de pedra, como os guarda-sóis da
## Fase 204: `PalapaView.near_of`), até PER_POST células de areia livre junto do mar (`PalapaView._sand`), afastadas umas das
## outras (`cells`): a cabine de banho de época sobre quatro rodas de raios, as paredes de lona listrada de vermelho e branco, o
## teto de tábuas em arco, a porta com a capota de lona virada para o mar e a escadinha (`machine_mesh`, de frente para a água
## mais perto). O recheio deixa as células limpas. Um MultiMesh; nada no save; refeito na obra, na demolição, na estrada, no
## trilho, na derrubada de árvores e ao trocar de mundo.

const PER_POST := 3
const SPREAD_CELLS := 8.0
const SPACING_CELLS := 2.5
const SEA_LOOK_CELLS := 4
## A cabine: as meias medidas do corpo e a altura do piso sobre o chão.
const BODY_HALF := Vector3(0.75, 0.95, 1.0)
const FLOOR_M := 0.55
const WHEEL_R := 0.45
const RED := Color(0.66, 0.16, 0.13)
const WHITE := Color(0.9, 0.88, 0.82)
const WOOD := Color(0.45, 0.34, 0.23)
const ROOF := Color(0.3, 0.26, 0.22)

var _simulation: Simulation
var _machines := MultiMeshInstance3D.new()
## Os lugares (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.85
	_machines.name = "BathingMachines"
	_machines.multimesh = MultiMesh.new()
	_machines.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_machines.multimesh.mesh = machine_mesh()
	_machines.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_machines.material_override = material
	add_child(_machines)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.trees_changed.connect(_mark_trees)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func machine_count() -> int:
	return places.size()


func _mark(_id: int) -> void:
	_dirty = true


func _mark_trees(_island_id: int, _area: Rect2i) -> void:
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
			places.append(place_of(grid, cell))
	_machines.multimesh.instance_count = places.size()
	for i: int in places.size():
		_machines.multimesh.set_instance_transform(i, places[i])


## As células das cabines da ilha. Vazio nas tropicais (lá ficam os guarda-sóis de palha) e na ilha plana.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, bool]:
	var result: Dictionary[Vector2i, bool] = {}
	var grid := world.island(island_id)
	if grid == null or grid.flat or world.is_tropical(island_id, data):
		return result
	var posts: Array[int] = []
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id == island_id and data.building(record.def_id).is_trading_post:
			posts.append(id)
	if posts.is_empty():
		return result
	posts.sort()
	var taken: Dictionary[Vector2i, bool] = {}
	taken.merge(FishNetView.cells(world, data, island_id))
	for cell: Vector2i in BeachBoatView.cells(world, data, island_id):
		taken[cell] = true
	for id: int in posts:
		var record := world.buildings[id]
		var def := data.building(record.def_id)
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		var middle := Vector2(area.position) + Vector2(area.size) * 0.5
		var near := PalapaView.near_of(record.def_id, area)
		var found: Array[Vector2i] = []
		var ring := area.grow(ceili(near + SPREAD_CELLS))
		for y: int in range(ring.position.y, ring.end.y):
			for x: int in range(ring.position.x, ring.end.x):
				var cell := Vector2i(x, y)
				var apart := (Vector2(cell) + Vector2(0.5, 0.5)).distance_to(middle)
				if apart < near or apart > near + SPREAD_CELLS or taken.has(cell) or result.has(cell):
					continue
				if PalapaView._sand(grid, cell):
					found.append(cell)
		found.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			var da := (Vector2(a) + Vector2(0.5, 0.5)).distance_squared_to(middle)
			var db := (Vector2(b) + Vector2(0.5, 0.5)).distance_squared_to(middle)
			return da < db or (da == db and (a.y < b.y or (a.y == b.y and a.x < b.x))))
		var picked := 0
		for cell: Vector2i in found:
			if picked >= PER_POST:
				break
			var close := false
			for other: Vector2i in result:
				if Vector2(other).distance_to(Vector2(cell)) < SPACING_CELLS:
					close = true
					break
			if not close:
				picked += 1
				result[cell] = true
	return result


## O lugar da cabine: o meio da célula no chão (o mais baixo dos cantos), a porta (−z) virada para a célula de mar mais perto.
static func place_of(grid: IslandGrid, cell: Vector2i) -> Transform3D:
	var at := grid.cell_world(cell)
	at.y = BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE)).x
	# Fase 329: na rampa da praia o chão desenhado fica abaixo da simulação
	var half := grid.cell_size * 0.5
	for corner: Vector2 in [Vector2(-half, -half), Vector2(half, -half), Vector2(-half, half), Vector2(half, half)]:
		at.y = minf(at.y, TerrainDetail.shown_at(grid, at.x + corner.x, at.z + corner.y))
	var best := Vector2.ZERO
	var best_distance := INF
	for dy: int in range(-SEA_LOOK_CELLS, SEA_LOOK_CELLS + 1):
		for dx: int in range(-SEA_LOOK_CELLS, SEA_LOOK_CELLS + 1):
			var next := cell + Vector2i(dx, dy)
			if not grid.in_bounds(next) or grid.ground[grid.index(next)] != IslandGrid.Ground.SEA:
				continue
			var distance := Vector2(dx, dy).length()
			if distance < best_distance:
				best_distance = distance
				best = Vector2(dx, dy)
	var facing := Vector3(best.x, 0.0, best.y).normalized() if best_distance < INF else Vector3.FORWARD
	# a porta em −z olha para o mar: z = −facing; base de mão direita
	var z := -facing
	var x := Vector3.UP.cross(z).normalized()
	return Transform3D(Basis(x, Vector3.UP, z), at)


## A cabine com o pé no chão, a porta em −z: as quatro rodas de raios, o chassi, o corpo de lona listrada sobre o piso, o teto
## de tábuas em arco, a porta escura com a capota de lona e a escadinha até a areia.
static func machine_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var hub := Vector3(sx * (BODY_HALF.x + 0.06), WHEEL_R, sz * (BODY_HALF.z - 0.3))
			_wheel(tool, hub, sx)
	VertexShapes.box(tool, Vector3(0.0, FLOOR_M - 0.04, 0.0), Vector3(BODY_HALF.x, 0.05, BODY_HALF.z + 0.05), WOOD)
	# as paredes de lona em listras verticais, em volta do corpo
	var base := FLOOR_M
	var top := FLOOR_M + BODY_HALF.y * 2.0
	var stripes := 8
	for face: int in 4:
		var along_x := face % 2 == 0
		var half_len := BODY_HALF.x if along_x else BODY_HALF.z
		var depth := BODY_HALF.z if along_x else BODY_HALF.x
		var sign_out := -1.0 if face < 2 else 1.0
		for k: int in stripes:
			var u0 := -half_len + k * half_len * 2.0 / stripes
			var u1 := u0 + half_len * 2.0 / stripes
			var color := RED if k % 2 == 0 else WHITE
			var a: Vector3
			var b: Vector3
			if along_x:
				a = Vector3(u0, 0.0, sign_out * depth)
				b = Vector3(u1, 0.0, sign_out * depth)
			else:
				a = Vector3(sign_out * depth, 0.0, u0)
				b = Vector3(sign_out * depth, 0.0, u1)
			var p: Array[Vector3] = [a + Vector3(0.0, base, 0.0), b + Vector3(0.0, base, 0.0), b + Vector3(0.0, top, 0.0),
					a + Vector3(0.0, top, 0.0)]
			VertexShapes.quad(tool, p[0], p[1], p[2], p[3], color)
			VertexShapes.quad(tool, p[0], p[3], p[2], p[1], color)
	# o teto em arco, de tábuas, ao longo de z
	var arch := 8
	for k: int in arch:
		var a0 := PI * k / arch
		var a1 := PI * (k + 1) / arch
		var p0 := Vector3(-cos(a0) * (BODY_HALF.x + 0.08), top + sin(a0) * 0.3, 0.0)
		var p1 := Vector3(-cos(a1) * (BODY_HALF.x + 0.08), top + sin(a1) * 0.3, 0.0)
		var front := Vector3(0.0, 0.0, -BODY_HALF.z - 0.12)
		var back := Vector3(0.0, 0.0, BODY_HALF.z + 0.12)
		VertexShapes.quad(tool, p0 + front, p0 + back, p1 + back, p1 + front, ROOF)
		VertexShapes.quad(tool, p0 + front, p1 + front, p1 + back, p0 + back, ROOF)
		VertexShapes.tri(tool, Vector3(0.0, top, -BODY_HALF.z - 0.01), p0 + Vector3(0.0, 0.0, -BODY_HALF.z - 0.01),
				p1 + Vector3(0.0, 0.0, -BODY_HALF.z - 0.01), WHITE)
		VertexShapes.tri(tool, Vector3(0.0, top, BODY_HALF.z + 0.01), p1 + Vector3(0.0, 0.0, BODY_HALF.z + 0.01),
				p0 + Vector3(0.0, 0.0, BODY_HALF.z + 0.01), WHITE)
	# a porta, a capota de lona sobre ela e a escadinha
	VertexShapes.box(tool, Vector3(0.0, base + 0.8, -BODY_HALF.z - 0.01), Vector3(0.32, 0.75, 0.01), WOOD.darkened(0.3))
	VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.RIGHT, 0.5), Vector3(0.0, top - 0.15, -BODY_HALF.z - 0.3)),
			Vector3(0.5, 0.02, 0.32), RED)
	for k: int in 3:
		var y := FLOOR_M * (k + 0.5) / 3.0
		VertexShapes.box(tool, Vector3(0.0, y, -BODY_HALF.z - 0.15 - (2 - k) * 0.18), Vector3(0.3, 0.025, 0.1), WOOD)
	tool.generate_normals()
	return tool.commit()


static func _wheel(tool: SurfaceTool, hub: Vector3, side: float) -> void:
	var rim := 12
	for k: int in rim:
		var a0 := TAU * k / rim
		var a1 := TAU * (k + 1) / rim
		VertexShapes.strut(tool, hub + Vector3(0.0, sin(a0), cos(a0)) * WHEEL_R, hub + Vector3(0.0, sin(a1), cos(a1)) * WHEEL_R,
				0.025, 0.02, WOOD.darkened(0.2))
	for k: int in 6:
		var angle := TAU * k / 6.0 + 0.3
		VertexShapes.strut(tool, hub, hub + Vector3(0.0, sin(angle), cos(angle)) * WHEEL_R, 0.012, 0.012, WOOD)
	VertexShapes.cylinder(tool, hub - Vector3(0.05 * side, 0.0, 0.0), hub + Vector3(0.07 * side, 0.0, 0.0), 0.06, WOOD.darkened(0.4),
			8)
