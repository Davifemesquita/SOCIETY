class_name CoalHeapView
extends Node3D
## Fase 216: o monte de carvão na usina. Em cada usina a carvão, nas duas células do meio de um lado — o de −X do modelo, depois o
## de +X e por fim o de trás (a frente é a da estrada) —, livres como as das tábuas da Fase 215 (`sites`, pela mesma regra): a
## baia de tábuas encostada na parede, aberta na frente, com o monte de carvão de duas cristas escorrendo para fora dela, umas
## pedras soltas no chão e a pá cravada no monte (`heap_mesh`, no meio das duas células). O recheio e as bombas deixam as células
## limpas (`cells`). Um MultiMesh; nada no save; refeito na obra, na demolição, na estrada, no trilho e ao trocar de mundo.

const POWER_STATION := &"power_station"
## A baia: a meia largura ao longo da parede, o fundo e a altura das paredes de tábua.
const HALF_WIDTH_M := 1.9
const DEPTH_M := 1.7
const BIN_WALL_M := 0.55
## A crista mais alta do monte e a malha do monte (pontos ao longo da parede × para fora).
const PEAK_M := 1.15
const GRID_X := 36
const GRID_Z := 20
const COAL := Color(0.05, 0.05, 0.055)
const COAL_LIGHT := Color(0.15, 0.15, 0.155)
const PLANK := Color(0.36, 0.29, 0.22)
const POST := Color(0.26, 0.21, 0.16)
const IRON := Color(0.3, 0.3, 0.32)
const HANDLE := Color(0.55, 0.42, 0.28)

var _simulation: Simulation
var _heaps := MultiMeshInstance3D.new()
## Os lugares (o meio entre as duas células no chão, o +z para longe da parede) (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.85
	_heaps.name = "CoalHeaps"
	_heaps.multimesh = MultiMesh.new()
	_heaps.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_heaps.multimesh.mesh = heap_mesh()
	_heaps.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_heaps.material_override = material
	add_child(_heaps)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func heap_count() -> int:
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
		var found := sites(world, _simulation.data, island_id)
		for id: int in found:
			var site: Array = found[id]
			var pair: Array[Vector2i] = site[0]
			var side: Vector2i = site[1]
			var x := Vector3(side.y, 0.0, -side.x)
			var z := Vector3(side.x, 0.0, side.y)
			var at := (grid.cell_world(pair[0]) + grid.cell_world(pair[1])) * 0.5
			at.y = minf(BuildingKit.corner_range(grid, Rect2i(pair[0], Vector2i.ONE)).x,
					BuildingKit.corner_range(grid, Rect2i(pair[1], Vector2i.ONE)).x)
			places.append(Transform3D(Basis(x, Vector3.UP, z), at))
	_heaps.multimesh.instance_count = places.size()
	for i: int in places.size():
		_heaps.multimesh.set_instance_transform(i, places[i])


## Os montes da ilha: id da usina → [as duas células, o lado da área para onde elas ficam].
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	var result: Dictionary[int, Array] = {}
	var grid := world.island(island_id)
	if grid == null:
		return result
	var ids: Array[int] = []
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id == island_id and record.def_id == POWER_STATION:
			ids.append(id)
	if ids.is_empty():
		return result
	ids.sort()
	var taken: Dictionary[Vector2i, bool] = {}
	if not grid.flat:
		taken.merge(ForecourtView.cells(world, data, island_id))
		taken.merge(AvenueView.cells(world, island_id))
	# nem nas tábuas de uma serraria encostada
	for cell: Vector2i in PlankStackView.cells(world, data, island_id):
		taken[cell] = true
	for id: int in ids:
		var record := world.buildings[id]
		var area := Footprint.rect(record.origin, data.building(record.def_id).size, record.rotation)
		var model := BuildingView.model_place(grid, record, area)
		var plus_x := Vector2i(roundi(model.basis.x.x), roundi(model.basis.x.z))
		var back := Vector2i(roundi(model.basis.z.x), roundi(model.basis.z.z))
		for side: Vector2i in [-plus_x, plus_x, back]:
			var pair := PlankStackView._pair(area, side)
			if not PlankStackView._free(grid, pair[0], taken) or not PlankStackView._free(grid, pair[1], taken):
				continue
			for cell: Vector2i in pair:
				taken[cell] = true
			result[id] = [pair, side]
			break
	return result


## As células dos montes da ilha (o recheio e as bombas as deixam limpas) → o id da usina.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}
	var found := sites(world, data, island_id)
	for station_id: int in found:
		var site: Array = found[station_id]
		var pair: Array[Vector2i] = site[0]
		for cell: Vector2i in pair:
			result[cell] = station_id
	return result


## A altura do monte no ponto (x ao longo da parede, z para fora; a parede em z = −1): duas cristas encostadas na parede que
## descem para fora, com o carvão em pedras (ruído sem sorteio).
static func height_at(x: float, z: float) -> float:
	var back := z + 1.0
	var a := PEAK_M * exp(-(pow(x + 0.75, 2.0) / 0.9 + pow(back - 0.35, 2.0) / 0.7))
	var b := PEAK_M * 0.8 * exp(-(pow(x - 0.85, 2.0) / 0.75 + pow(back - 0.4, 2.0) / 0.6))
	var lumps := 0.05 * sin(x * 13.0 + z * 5.0) * sin(z * 11.0 - x * 3.0) \
			+ 0.03 * sin(x * 29.0 - z * 17.0) * sin(z * 23.0 + x * 7.0)
	return maxf(maxf(a, b) + lumps * minf(maxf(a, b) * 3.0, 1.0), 0.0)


## A baia e o monte com o meio entre as duas células na origem (o pé no chão), a parede da usina em −z (a uma meia célula).
static func heap_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wall_z := -1.0
	# as paredes da baia: os dois lados de tábuas, com os esteios
	for side: float in [-1.0, 1.0]:
		var x := side * HALF_WIDTH_M
		VertexShapes.box(tool, Vector3(x, BIN_WALL_M * 0.5, wall_z + DEPTH_M * 0.5), Vector3(0.03, BIN_WALL_M * 0.5,
				DEPTH_M * 0.5), PLANK)
		for z: float in [wall_z + 0.08, wall_z + DEPTH_M - 0.05]:
			VertexShapes.box(tool, Vector3(x, (BIN_WALL_M + 0.12) * 0.5, z), Vector3(0.05, (BIN_WALL_M + 0.12) * 0.5, 0.05),
					POST)
	# o monte: a malha da altura, com a cor de cada canto entre o preto e o cinza do carvão
	# as faces chapadas: o carvão em pedras, não um pano liso
	tool.set_smooth_group(-1)
	var x0 := -HALF_WIDTH_M + 0.05
	var x1 := HALF_WIDTH_M - 0.05
	var z0 := wall_z + 0.02
	var z1 := wall_z + DEPTH_M + 0.2
	for i: int in GRID_X:
		for j: int in GRID_Z:
			var p: Array[Vector3] = []
			var c: Array[Color] = []
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var x := lerpf(x0, x1, float(i + corner.x) / GRID_X)
				var z := lerpf(z0, z1, float(j + corner.y) / GRID_Z)
				p.append(Vector3(x, height_at(x, z), z))
				var shine := fposmod(sin(x * 37.0 + z * 91.0) * 43758.5453, 1.0)
				c.append(COAL.lerp(COAL_LIGHT, shine * 0.6))
			# a face para cima no sentido horário visto de cima (x à direita, z para baixo): (0, 0) → (1, 0) → (1, 1)
			_tri(tool, p[0], p[1], p[2], c[0], c[1], c[2])
			_tri(tool, p[0], p[2], p[3], c[0], c[2], c[3])
	tool.set_smooth_group(0)
	# pedras soltas no chão diante do monte e no pé dele, espalhadas pelo hash do número
	for k: int in 12:
		var x := -1.6 + 3.2 * fposmod(k * 0.618034, 1.0)
		var z := z1 - 0.05 - 0.45 * fposmod(k * 0.381966 + 0.13, 1.0)
		var size := 0.05 + 0.03 * fposmod(k * 0.7548, 1.0)
		var at := Vector3(x, height_at(x, z) + size * 0.6, z)
		PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(size * 1.2, size, size)), at), COAL_LIGHT)
	# a pá cravada no monte da direita, o cabo para fora e para cima
	var blade := Vector3(0.85, height_at(0.85, -0.2) - 0.05, -0.2)
	var tip := blade + Vector3(0.15, 0.95, 0.75)
	VertexShapes.strut(tool, blade, tip, 0.03, 0.03, HANDLE)
	VertexShapes.strut(tool, tip - Vector3(0.08, 0.0, 0.0), tip + Vector3(0.08, 0.0, 0.0), 0.025, 0.025, HANDLE)
	var dir := (tip - blade).normalized()
	var across := dir.cross(Vector3.UP).normalized()
	VertexShapes.quad(tool, blade - across * 0.13 - dir * 0.3, blade + across * 0.13 - dir * 0.3, blade + across * 0.13,
			blade - across * 0.13, IRON)
	VertexShapes.quad(tool, blade - across * 0.13, blade + across * 0.13, blade + across * 0.13 - dir * 0.3,
			blade - across * 0.13 - dir * 0.3, IRON)
	tool.generate_normals()
	return tool.commit()


static func _tri(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	tool.set_color(ca)
	tool.add_vertex(a)
	tool.set_color(cb)
	tool.add_vertex(b)
	tool.set_color(cc)
	tool.add_vertex(c)
