class_name MilestoneView
extends Node3D
## Fase 237: o marco de légua. Nas estradas de terra das ilhas com relevo, numa célula a cada STONE_EVERY pelo desenho da grade
## (`posmod(7x + 13y, STONE_EVERY)` = 0: numa estrada reta, um marco a cada STONE_EVERY células), só no meio de um trecho reto de
## RUN_CELLS células para cada lado (a estrada comprida), sem casa a até `SignpostView.TOWN_CELLS` células (fora das vilas) e fora
## das células dos postes de fio (Fase 120): o marco de pedra de topo redondo na beira da estrada, do lado em que a célula vizinha
## está livre, com a face virada para a estrada (`stones`), o painel rebaixado com os riscos da inscrição (sem texto) e o pé
## esverdeado de musgo, cada um com uma pontinha de inclinação pelo hash (`stone_mesh`). Um MultiMesh; nada no save; refeito
## quando as estradas mudam, na obra, na demolição e ao trocar de mundo.

const STONE_EVERY := 23
const RUN_CELLS := 2
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
## Quanto o marco sai do meio da célula para a beira e quanto ele se inclina no máximo.
const OFFSET_M := 0.82
const LEAN_RAD := 0.09
## O marco: a meia largura (o raio do topo), a altura do ombro, a meia grossura e o quanto fica enterrado.
const HALF_W := 0.2
const SHOULDER_M := 0.5
const HALF_T := 0.09
const SUNK_M := 0.08
const ARCH_STEPS := 6
const STONE := Color(0.74, 0.72, 0.66)
const PANEL := Color(0.62, 0.6, 0.55)
const CARVE := Color(0.32, 0.31, 0.29)
const MOSS := Color(0.4, 0.46, 0.3)

var _simulation: Simulation
var _stones := MultiMeshInstance3D.new()
## Os lugares dos marcos (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.95
	_stones.name = "Milestones"
	_stones.multimesh = MultiMesh.new()
	_stones.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_stones.multimesh.mesh = stone_mesh()
	_stones.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_stones.material_override = material
	add_child(_stones)
	EventBus.roads_changed.connect(_mark)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func stone_count() -> int:
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
		places.append_array(stones(world, _simulation.data, island_id))
	_stones.multimesh.instance_count = places.size()
	for i: int in places.size():
		_stones.multimesh.set_instance_transform(i, places[i])


## Os marcos da ilha: o pé no chão, o +z (a face) virado para a estrada. Vazio na ilha plana.
static func stones(world: WorldState, data: GameData, island_id: int) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var grid := world.island(island_id)
	if grid == null or grid.flat:
		return result
	var houses: Array[Vector2i] = []
	var houses_ready := false
	for cell: Vector2i in grid.road_cells():
		if posmod(7 * cell.x + 13 * cell.y, STONE_EVERY) != 0 or grid.is_paved(cell):
			continue
		if posmod(cell.x + 3 * cell.y, PowerLineView.POLE_EVERY) == PowerLineView.POLE_REST:
			continue
		var axis := _straight_axis(grid, cell)
		if axis == Vector2i.ZERO:
			continue
		if not houses_ready:
			houses = SignpostView._house_cells(world, data, island_id)
			houses_ready = true
		if SignpostView._near_town(houses, cell):
			continue
		# a beira de um lado ou do outro pelo hash; vale o primeiro lado com a vizinha livre
		var across := Vector2i(axis.y, axis.x)
		var first := 1 if posmod(cell.x * 5 + cell.y * 11, 2) == 0 else -1
		for flip: int in [first, -first]:
			var side := across * flip
			var beside := cell + side
			if not grid.in_bounds(beside) or not grid.is_land(beside) or grid.has_road(beside) or grid.building_at(beside) != 0:
				continue
			var out := Vector3(side.x, 0.0, side.y)
			var foot := grid.surface_world(cell) + out * OFFSET_M
			foot.y = grid.height_at(foot.x, foot.z)
			# a face para a estrada (o −out), com a inclinação pelo hash em volta do eixo da estrada
			var facing := -out
			var lean := (float(posmod(cell.x * 37 + cell.y * 53, 9)) / 8.0 * 2.0 - 1.0) * LEAN_RAD
			var basis := Basis(Vector3.UP, atan2(facing.x, facing.z)) * Basis(Vector3.RIGHT, lean)
			result.append(Transform3D(basis, foot))
			break
	return result


## O eixo da estrada reta que passa pela célula (as duas vizinhas de um eixo são estrada, e as do outro não, até RUN_CELLS para
## cada lado), ou zero.
static func _straight_axis(grid: IslandGrid, cell: Vector2i) -> Vector2i:
	for axis: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
		var across := Vector2i(axis.y, axis.x)
		var straight := true
		for k: int in range(-RUN_CELLS, RUN_CELLS + 1):
			var at := cell + axis * k
			if not grid.has_road(at) or grid.is_paved(at) or grid.has_road(at + across) or grid.has_road(at - across):
				straight = false
				break
		if straight:
			return axis
	return Vector2i.ZERO


## O marco com o pé no zero (enterrado SUNK_M) e a face para +z: a laje de topo redondo, o painel rebaixado na face com três
## riscos da inscrição e a faixa de musgo no pé.
static func stone_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# o contorno no plano xy, no sentido anti-horário visto de +z: o lado direito, o arco do topo e o lado esquerdo
	var outline: Array[Vector2] = [Vector2(HALF_W, -SUNK_M)]
	for k: int in ARCH_STEPS + 1:
		var angle := PI * k / ARCH_STEPS
		outline.append(Vector2(cos(angle) * HALF_W, SHOULDER_M + sin(angle) * HALF_W))
	outline.append(Vector2(-HALF_W, -SUNK_M))
	var middle := Vector2(0.0, SHOULDER_M * 0.6)
	for i: int in outline.size():
		var p := outline[i]
		var q := outline[(i + 1) % outline.size()]
		VertexShapes.tri(tool, Vector3(middle.x, middle.y, HALF_T), Vector3(q.x, q.y, HALF_T), Vector3(p.x, p.y, HALF_T), STONE)
		VertexShapes.tri(tool, Vector3(middle.x, middle.y, -HALF_T), Vector3(p.x, p.y, -HALF_T), Vector3(q.x, q.y, -HALF_T),
				STONE)
		VertexShapes.quad(tool, Vector3(p.x, p.y, HALF_T), Vector3(q.x, q.y, HALF_T), Vector3(q.x, q.y, -HALF_T),
				Vector3(p.x, p.y, -HALF_T), STONE)
	# o painel rebaixado e os riscos da inscrição, logo à frente da face
	var face := HALF_T + 0.004
	VertexShapes.quad(tool, Vector3(-HALF_W * 0.7, SHOULDER_M + 0.08, face), Vector3(HALF_W * 0.7, SHOULDER_M + 0.08, face),
			Vector3(HALF_W * 0.7, 0.16, face), Vector3(-HALF_W * 0.7, 0.16, face), PANEL)
	for k: int in 3:
		var y := SHOULDER_M - 0.02 - k * 0.1
		var half := HALF_W * (0.45 if k == 1 else 0.3)
		VertexShapes.box(tool, Vector3(0.0, y, face), Vector3(half, 0.012, 0.004), CARVE)
	# o musgo no pé, nas duas faces
	for z: float in [face, -face]:
		var near := z > 0.0
		var a := Vector3(-HALF_W, 0.0, z)
		var b := Vector3(HALF_W, 0.0, z)
		var c := Vector3(HALF_W, 0.07, z)
		var d := Vector3(-HALF_W, 0.07, z)
		if near:
			VertexShapes.quad(tool, d, c, b, a, MOSS)
		else:
			VertexShapes.quad(tool, c, d, a, b, MOSS)
	tool.generate_normals()
	return tool.commit()
