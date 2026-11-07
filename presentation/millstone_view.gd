class_name MillstoneView
extends Node3D
## Fase 211: as mós no moinho. Em cada moinho, na célula livre encostada no meio do lado de −X ou de +X (o de −X primeiro; as pás
## ficam na frente), de terra, sem prédio, estrada, trilho nem árvore, fora do largo e da alameda, e quase plana (`sites`): duas
## mós de pedra velhas, de pé encostadas na parede, uma na frente da outra, com o furo do eixo e os sulcos da face, e ao lado a
## pilha de sacos de farinha brancos (`millstone_mesh`). O recheio e as bombas deixam a célula limpa (`cells`). Um MultiMesh;
## nada no save; refeito na obra, na demolição, na estrada, no trilho e ao trocar de mundo.

const MILL := &"mill"
const MAX_RELIEF_M := 0.8
## A mó: o raio, a espessura e o furo do eixo.
const STONE_R_M := 0.62
const STONE_THICK_M := 0.24
const EYE_R_M := 0.12
const SIDES := 14
const STONE := Color(0.6, 0.57, 0.52)
const STONE_DARK := Color(0.42, 0.4, 0.37)
const SACK := Color(0.9, 0.88, 0.82)
const SACK_TIE := Color(0.62, 0.52, 0.36)

var _simulation: Simulation
var _stones := MultiMeshInstance3D.new()
## Os lugares (o meio da célula no chão, o +z para longe da parede) (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	_stones.name = "Millstones"
	_stones.multimesh = MultiMesh.new()
	_stones.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_stones.multimesh.mesh = millstone_mesh()
	_stones.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_stones.material_override = material
	add_child(_stones)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func millstone_count() -> int:
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
			var cell: Vector2i = site[0]
			var side: Vector2i = site[1]
			var at := grid.cell_world(cell)
			at.y = BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE)).x
			# o x ao longo da parede, o +z para fora dela (base de mão direita: x = cima × fora)
			var x := Vector3(side.y, 0.0, -side.x)
			var z := Vector3(side.x, 0.0, side.y)
			places.append(Transform3D(Basis(x, Vector3.UP, z), at))
	_stones.multimesh.instance_count = places.size()
	for i: int in places.size():
		_stones.multimesh.set_instance_transform(i, places[i])


## As mós da ilha: id do moinho → [a célula, o lado da área para onde ela fica].
static func sites(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Array]:
	var result: Dictionary[int, Array] = {}
	var grid := world.island(island_id)
	if grid == null:
		return result
	var ids: Array[int] = []
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id == island_id and record.def_id == MILL:
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
		var area := Footprint.rect(record.origin, data.building(record.def_id).size, record.rotation)
		var front := Footprint.front_direction(record.rotation)
		var right := Vector2i(-front.y, front.x)
		for side: Vector2i in [-right, right]:
			var cell := SpoilTipView._beside(area, side)
			if not grid.in_bounds(cell) or taken.has(cell):
				continue
			var index := grid.index(cell)
			# a ilha plana (testes, saves antigos) não tem chão nem árvores na grade
			if not grid.is_land(cell) or grid.occupancy[index] != 0 or grid.roads[index] != IslandGrid.Road.NONE \
					or grid.rails[index] != 0 or (not grid.flat and grid.trees[index] > 0):
				continue
			var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
			if corners.y - corners.x > MAX_RELIEF_M:
				continue
			taken[cell] = true
			result[id] = [cell, side]
			break
	return result


## As células das mós da ilha (o recheio e as bombas as deixam limpas) → o id do moinho.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}
	var found := sites(world, data, island_id)
	for mill_id: int in found:
		var site: Array = found[mill_id]
		var cell: Vector2i = site[0]
		result[cell] = mill_id
	return result


## As mós e os sacos com o meio da célula na origem (o pé no chão), a parede do moinho em −z (a uma meia célula): as duas mós de
## pé, de face para fora, encostadas na parede e uma um pouco à frente e de lado, com o furo do eixo e os sulcos; a pilha de
## sacos em +x.
static func millstone_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wall_z := -1.0 + 0.04
	for k: int in 2:
		var center := Vector3(-0.32 + k * 0.22, STONE_R_M, wall_z + STONE_THICK_M * (0.5 + k * 1.25))
		# inclinada para trás, encostada (na parede a de trás, na de trás a da frente)
		var lean := Basis(Vector3.RIGHT, -0.12)
		_millstone(tool, Transform3D(lean, center))
	# a pilha de sacos: três embaixo e dois em cima
	for k: int in 5:
		var row := 0 if k < 3 else 1
		var x := 0.32 + (k % 3) * 0.27 if row == 0 else 0.45 + (k - 3) * 0.27
		var at := Vector3(x, 0.17 + row * 0.27, wall_z + 0.3)
		PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.16, 0.15, 0.24)), at), SACK)
		PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.05, 0.04, 0.05)), at + Vector3(0.0, 0.14, 0.12)),
				SACK_TIE)
	tool.generate_normals()
	return tool.commit()


## Uma mó de pé no lugar place (o eixo dela em z): o anel de pedra com as duas faces, a borda e o furo, e os sulcos escuros
## em raio na face de fora.
static func _millstone(tool: SurfaceTool, place: Transform3D) -> void:
	var half := STONE_THICK_M * 0.5
	for i: int in SIDES:
		var a0 := TAU * i / SIDES
		var a1 := TAU * (i + 1) / SIDES
		var p := Vector3(cos(a0), sin(a0), 0.0)
		var q := Vector3(cos(a1), sin(a1), 0.0)
		var out_f := Vector3(0.0, 0.0, half)
		var back := Vector3(0.0, 0.0, -half)
		# a borda
		VertexShapes.quad(tool, place * (p * STONE_R_M + back), place * (p * STONE_R_M + out_f),
				place * (q * STONE_R_M + out_f), place * (q * STONE_R_M + back), STONE_DARK)
		# a face de fora e a de dentro, do furo até a borda
		VertexShapes.quad(tool, place * (p * EYE_R_M + out_f), place * (q * EYE_R_M + out_f), place * (q * STONE_R_M + out_f),
				place * (p * STONE_R_M + out_f), STONE)
		VertexShapes.quad(tool, place * (p * EYE_R_M + back), place * (p * STONE_R_M + back), place * (q * STONE_R_M + back),
				place * (q * EYE_R_M + back), STONE)
		# o furo do eixo
		VertexShapes.quad(tool, place * (p * EYE_R_M + out_f), place * (p * EYE_R_M + back), place * (q * EYE_R_M + back),
				place * (q * EYE_R_M + out_f), STONE_DARK.darkened(0.4))
	# os sulcos em raio na face de fora
	for k: int in 8:
		var angle := TAU * k / 8.0 + 0.2
		var dir := Vector3(cos(angle), sin(angle), 0.0)
		var normal := Vector3(-dir.y, dir.x, 0.0)
		var from := dir * (EYE_R_M + 0.05)
		var to := dir * (STONE_R_M - 0.06)
		var z := Vector3(0.0, 0.0, half + 0.004)
		VertexShapes.quad(tool, place * (from - normal * 0.012 + z), place * (from + normal * 0.012 + z),
				place * (to + normal * 0.012 + z), place * (to - normal * 0.012 + z), STONE_DARK)
