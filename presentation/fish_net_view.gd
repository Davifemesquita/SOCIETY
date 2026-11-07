class_name FishNetView
extends Node3D
## Fase 139: as redes de pesca secando. Ao lado de cada cabana de pesca, na célula livre encostada nela mais perto da
## metade do lado do mar (`sites`: de terra, sem prédio, estrada, trilho nem árvore, fora do largo e da alameda e quase
## plana), dois cavaletes em A com a rede estendida por cima da vara até perto do chão, as boias de cortiça numa beira
## (`rack_mesh`, a rede recortada em losangos no `shaders/fish_net.gdshader`), e num canto as caixas de peixe empilhadas e
## o cesto (`crates_mesh`), de frente para o mar. O recheio deixa a célula limpa (`ScatterView.island_context`). Uma malha
## só para o arquipélago, em duas superfícies (madeira e rede); nada no save; refeito na obra, na demolição, na estrada, no
## trilho, na derrubada de árvores e ao trocar de mundo.

const MAX_RELIEF_M := 0.8
## O cavalete: comprimento da vara, altura, meia abertura das pernas no chão e os dois cavaletes afastados RACK_GAP_M.
const RACK_LENGTH_M := 1.2
const RACK_HEIGHT_M := 1.15
const RACK_SPREAD_M := 0.42
const RACK_GAP_M := 0.75
const RACK_SHIFT_M := 0.25
## A rede desce da vara até NET_BOTTOM_M do chão, em NET_SEGMENTS lanços com a barriga de NET_SAG_M.
const NET_BOTTOM_M := 0.18
const NET_SEGMENTS := 6
const NET_SAG_M := 0.06
const FLOAT_STEP_M := 0.25
const WOOD := Color(0.42, 0.32, 0.21)
const NET := Color(0.27, 0.29, 0.21)
const CORK := Color(0.82, 0.68, 0.45)
const CRATE := Color(0.6, 0.48, 0.32)
const FISH := Color(0.72, 0.76, 0.8)
const BASKET := Color(0.62, 0.5, 0.3)

var _simulation: Simulation
var _racks := MeshInstance3D.new()
var _count := 0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	_racks.name = "FishNets"
	add_child(_racks)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.trees_changed.connect(func(_island_id: int, _area: Rect2i) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func site_count() -> int:
	return _count


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	_count = 0
	var wood := SurfaceTool.new()
	wood.begin(Mesh.PRIMITIVE_TRIANGLES)
	var net := SurfaceTool.new()
	net.begin(Mesh.PRIMITIVE_TRIANGLES)
	var world := _simulation.world
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		var found := sites(world, _simulation.data, island_id)
		for cell: Vector2i in found:
			var site: Array = found[cell]
			var out: Vector3 = site[0]
			var away: float = site[1]
			var middle := grid.cell_world(cell)
			var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
			# as varas correm ao longo da costa (de través do mar); o pé no canto mais baixo da célula
			var place := Transform3D(Basis.looking_at(out, Vector3.UP), Vector3(middle.x, corners.x, middle.z))
			# os cavaletes do lado da cabana e as caixas no lado de longe dela (o x da célula é de través do mar)
			_rack(wood, net, place * Transform3D(Basis.IDENTITY, Vector3(-RACK_SHIFT_M * away, 0.0, -RACK_GAP_M * 0.5 + 0.1)))
			_rack(wood, net, place * Transform3D(Basis.IDENTITY, Vector3(-RACK_SHIFT_M * away, 0.0, RACK_GAP_M * 0.5 + 0.1)))
			_crates(wood, place * Transform3D(Basis.IDENTITY, Vector3(0.72 * away, 0.0, -0.35)))
			_count += 1
	if _count == 0:
		_racks.mesh = null
		return
	var wood_material := StandardMaterial3D.new()
	wood_material.vertex_color_use_as_albedo = true
	wood_material.vertex_color_is_srgb = true
	wood_material.roughness = 0.9
	var net_material := ShaderMaterial.new()
	net_material.shader = load("res://shaders/fish_net.gdshader") as Shader
	wood.generate_normals()
	var mesh := wood.commit()
	mesh.surface_set_material(0, wood_material)
	net.generate_normals()
	net.commit(mesh)
	mesh.surface_set_material(1, net_material)
	_racks.mesh = mesh


## A célula das redes de cada cabana de pesca da ilha → [para onde fica o mar (unitário, no mundo), o lado de través
## do mar (+1 ou −1, no x da célula) longe da cabana]: das livres encostadas
## na cabana (lados e cantos), de terra, sem árvore, fora do largo e da alameda e quase planas, a mais perto do meio da
## metade da cabana do lado do mar, num dos lados dela.
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, Array]:
	var result: Dictionary[Vector2i, Array] = {}
	var grid := world.island(island_id)
	if grid == null:
		return result
	var ids: Array[int] = []
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id == island_id and record.def_id == &"fishery":
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
		var center := grid.rect_world(area)
		var out := HarborView.seaward(world, center, area, grid.cell_size, record.rotation)
		var across := Vector3(-out.z, 0.0, out.x)
		var reach := (area.size.x if out.x != 0.0 else area.size.y) * grid.cell_size * 0.5
		var width := (area.size.y if out.x != 0.0 else area.size.x) * grid.cell_size * 0.5
		var goals: Array[Vector3] = [center + out * reach * 0.5 + across * (width + grid.cell_size * 0.5),
				center + out * reach * 0.5 - across * (width + grid.cell_size * 0.5)]
		var best := Vector2i(-1, -1)
		var best_m := INF
		var ring := area.grow(1)
		for y: int in range(ring.position.y, ring.end.y):
			for x: int in range(ring.position.x, ring.end.x):
				var cell := Vector2i(x, y)
				if area.has_point(cell) or not grid.in_bounds(cell) or taken.has(cell) or result.has(cell):
					continue
				var index := grid.index(cell)
				# a ilha plana (testes, saves antigos) não tem chão nem árvores na grade
				if not grid.is_land(cell) or grid.occupancy[index] != 0 or grid.roads[index] != IslandGrid.Road.NONE \
						or grid.rails[index] != 0 or (not grid.flat and grid.trees[index] > 0):
					continue
				var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
				if corners.y - corners.x > MAX_RELIEF_M:
					continue
				var at := grid.cell_world(cell)
				var meters := minf(at.distance_squared_to(goals[0]), at.distance_squared_to(goals[1]))
				if meters < best_m:
					best_m = meters
					best = cell
		if best_m < INF:
			# para que lado de través do mar (o x da célula) fica o lado longe da cabana
			var away := 1.0 if (grid.cell_world(best) - center).dot(across) >= 0.0 else -1.0
			result[best] = [out, away]
	return result


## As células das redes da ilha (o recheio as deixa limpas).
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, bool]:
	var result: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in sites(world, data, island_id):
		result[cell] = true
	return result


## Um cavalete no referencial place (a vara ao longo de x, no alto; as pernas abertas em z): as duas pernas em A de cada
## ponta, a vara, a rede caindo dos dois lados com a barriga e as boias de cortiça na beira de baixo de um lado.
static func _rack(wood: SurfaceTool, net: SurfaceTool, place: Transform3D) -> void:
	var half := RACK_LENGTH_M * 0.5
	for end: float in [-half, half]:
		for side: float in [-1.0, 1.0]:
			VertexShapes.strut(wood, place * Vector3(end, -0.05, side * RACK_SPREAD_M),
					place * Vector3(end, RACK_HEIGHT_M + 0.06, side * 0.03), 0.03, 0.03, WOOD)
	VertexShapes.strut(wood, place * Vector3(-half - 0.08, RACK_HEIGHT_M, 0.0), place * Vector3(half + 0.08, RACK_HEIGHT_M, 0.0),
			0.025, 0.025, WOOD)
	for side: float in [-1.0, 1.0]:
		var top: Array[Vector3] = []
		var bottom: Array[Vector3] = []
		for k: int in NET_SEGMENTS + 1:
			var x := -half + RACK_LENGTH_M * k / NET_SEGMENTS
			var sag := sin(PI * k / NET_SEGMENTS) * NET_SAG_M
			top.append(place * Vector3(x, RACK_HEIGHT_M + 0.03, 0.0))
			bottom.append(place * Vector3(x, NET_BOTTOM_M + sag + 0.04 * sin(k * 2.1 + side), side * (RACK_SPREAD_M - 0.08)))
		var slope := top[0].distance_to(bottom[0])
		for k: int in NET_SEGMENTS:
			var u0 := RACK_LENGTH_M * k / NET_SEGMENTS
			var u1 := RACK_LENGTH_M * (k + 1) / NET_SEGMENTS
			var corners: Array = [[top[k], Vector2(u0, 0.0)], [top[k + 1], Vector2(u1, 0.0)],
					[bottom[k + 1], Vector2(u1, slope)], [bottom[k], Vector2(u0, slope)]]
			for index: int in [0, 1, 2, 0, 2, 3]:
				var corner: Array = corners[index]
				var point: Vector3 = corner[0]
				var uv: Vector2 = corner[1]
				net.set_color(NET)
				net.set_uv(uv)
				net.add_vertex(point)
		if side > 0.0:
			var floats := floori(RACK_LENGTH_M / FLOAT_STEP_M)
			for k: int in floats + 1:
				var t := float(k) / floats
				var at: Vector3 = bottom[0].lerp(bottom[NET_SEGMENTS], t)
				VertexShapes.box(wood, at + Vector3(0.0, sin(PI * t) * NET_SAG_M, 0.0), Vector3(0.05, 0.025, 0.035), CORK)


## As caixas de peixe no referencial place (o pé no zero): duas no chão e uma em cima, de ripas, com os peixes à mostra
## na de cima, e um cesto ao lado.
static func _crates(wood: SurfaceTool, place: Transform3D) -> void:
	var half := Vector3(0.26, 0.11, 0.18)
	for at: Vector3 in [Vector3(0.0, half.y, 0.0), Vector3(0.0, half.y, 0.4), Vector3(0.02, half.y * 3.0 + 0.01, 0.2)]:
		VertexShapes.oriented_box(wood, place * Transform3D(Basis.IDENTITY, at), half, CRATE)
		for x: float in [-half.x, half.x]:
			VertexShapes.oriented_box(wood, place * Transform3D(Basis.IDENTITY, at + Vector3(x, 0.0, 0.0)),
					Vector3(0.015, half.y + 0.01, half.z + 0.01), CRATE.darkened(0.25))
	for k: int in 4:
		var fish := Vector3(-0.15 + k * 0.1, half.y * 4.0 + 0.03, 0.2 + (0.05 if k % 2 == 0 else -0.05))
		VertexShapes.oriented_box(wood, place * Transform3D(Basis(Vector3.UP, 0.2 * k), fish), Vector3(0.035, 0.02, 0.12),
				FISH)
	VertexShapes.cylinder(wood, place * Vector3(0.0, 0.0, -0.45), place * Vector3(0.0, 0.3, -0.45), 0.17, BASKET, 10)
