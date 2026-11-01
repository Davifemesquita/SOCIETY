class_name SignpostView
extends Node3D
## Fase 187: a placa na encruzilhada. Em cada célula de estrada de terra com três ou quatro estradas em volta pelos lados (a
## encruzilhada), sem casa a até TOWN_CELLS células (fora das vilas), o poste de madeira (`post_mesh`) num canto da célula —
## do lado sem estrada, ou no canto entre duas delas — e uma tábua apontando cada estrada, cada uma numa altura, com a ponta em
## seta (`arm_mesh`, `junctions`). Dois MultiMesh; nada no save; refeito quando as estradas mudam, na obra, na demolição e ao
## trocar de mundo.

const TOWN_CELLS := 6
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
## Quanto o poste sai do meio da célula, a altura dele e a das tábuas (uma por estrada, de cima para baixo).
const POST_OFFSET_M := 0.75
const POST_M := 2.3
const ARM_HEIGHTS_M: Array[float] = [2.0, 1.78, 1.56, 1.34]
const ARM_M := 0.75
const WOOD := Color(0.42, 0.32, 0.22)
const BOARD := Color(0.62, 0.52, 0.38)

var _simulation: Simulation
var _posts := MultiMeshInstance3D.new()
var _arms := MultiMeshInstance3D.new()
## Os pés dos postes e o lugar de cada tábua (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var arm_places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	for pair: Array in [[_posts, "SignPosts", post_mesh()], [_arms, "SignArms", arm_mesh()]]:
		var layer: MultiMeshInstance3D = pair[0]
		var label: String = pair[1]
		var mesh: ArrayMesh = pair[2]
		layer.name = label
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.mesh = mesh
		layer.multimesh.custom_aabb = WorldBounds.of(simulation.config)
		layer.material_override = material
		add_child(layer)
	EventBus.roads_changed.connect(_mark)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func post_count() -> int:
	return places.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	places.clear()
	arm_places.clear()
	var world := _simulation.world
	for island_id: int in world.islands.size():
		for entry: Array in junctions(world, _simulation.data, island_id):
			var post: Transform3D = entry[0]
			var arms: Array[Transform3D] = entry[1]
			places.append(post)
			arm_places.append_array(arms)
	for pair: Array in [[_posts, places], [_arms, arm_places]]:
		var layer: MultiMeshInstance3D = pair[0]
		var list: Array[Transform3D] = pair[1]
		layer.multimesh.instance_count = list.size()
		for i: int in list.size():
			layer.multimesh.set_instance_transform(i, list[i])


## As placas da ilha: [pé do poste (mundo), [lugar de cada tábua, o +x apontando a estrada]]. Vazio na ilha plana.
static func junctions(world: WorldState, data: GameData, island_id: int) -> Array[Array]:
	var result: Array[Array] = []
	var grid := world.island(island_id)
	if grid == null or grid.flat:
		return result
	var houses := _house_cells(world, data, island_id)
	for cell: Vector2i in grid.road_cells():
		if grid.is_paved(cell):
			continue
		var ways: Array[Vector2i] = []
		for side: Vector2i in SIDES:
			if grid.has_road(cell + side):
				ways.append(side)
		if ways.size() < 3 or _near_town(houses, cell):
			continue
		# o poste do lado sem estrada (no T) ou no canto entre a primeira estrada e a seguinte (no cruzamento)
		var corner := Vector2.ZERO
		for side: Vector2i in SIDES:
			if side not in ways:
				corner = Vector2(side)
		if corner == Vector2.ZERO:
			corner = Vector2(ways[0] + ways[1]).normalized()
		var middle := grid.surface_world(cell)
		var foot := middle + Vector3(corner.x, 0.0, corner.y) * POST_OFFSET_M
		foot.y = grid.height_at(foot.x, foot.z)
		var arms: Array[Transform3D] = []
		for k: int in ways.size():
			var way := Vector3(ways[k].x, 0.0, ways[k].y)
			# a tábua aponta para fora da encruzilhada pela estrada (o +x dela), com uma pontinha de torto
			var yaw := atan2(-way.z, way.x) + (0.04 if k % 2 == 0 else -0.05)
			arms.append(Transform3D(Basis(Vector3.UP, yaw), foot + Vector3(0.0, ARM_HEIGHTS_M[k], 0.0)))
		result.append([Transform3D(Basis(Vector3.UP, float(posmod(cell.x * 31 + cell.y * 17, 90)) * PI / 180.0), foot),
				arms])
	return result


## As células ocupadas por casas na ilha.
static func _house_cells(world: WorldState, data: GameData, island_id: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for id: int in world.buildings:
		var record := world.building(id)
		if record.island_id != island_id or not record.is_house():
			continue
		var def := data.building(record.def_id)
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		cells.append(area.position + area.size / 2)
	return cells


static func _near_town(houses: Array[Vector2i], cell: Vector2i) -> bool:
	for house: Vector2i in houses:
		if absi(house.x - cell.x) <= TOWN_CELLS and absi(house.y - cell.y) <= TOWN_CELLS:
			return true
	return false


## O poste com o pé no zero: o fuste quadrado de madeira e o chapéu em pirâmide baixa.
static func post_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.box(tool, Vector3(0.0, POST_M * 0.5 - 0.15, 0.0), Vector3(0.06, POST_M * 0.5 + 0.15, 0.06), WOOD)
	var top := Vector3(0.0, POST_M, 0.0)
	var corners: Array[Vector3] = [Vector3(-0.09, 0.0, -0.09), Vector3(0.09, 0.0, -0.09), Vector3(0.09, 0.0, 0.09),
			Vector3(-0.09, 0.0, 0.09)]
	for k: int in 4:
		VertexShapes.tri(tool, top + corners[k], top + corners[(k + 1) % 4], top + Vector3(0.0, 0.12, 0.0), WOOD)
	tool.generate_normals()
	return tool.commit()


## A tábua com o pé no poste e a ponta em seta para +x, a borda escura em volta do painel claro.
static func arm_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.box(tool, Vector3(ARM_M * 0.5, 0.0, 0.0), Vector3(ARM_M * 0.5, 0.075, 0.02), BOARD)
	# a ponta em seta
	var tip := Vector3(ARM_M + 0.14, 0.0, 0.0)
	for z: float in [-0.02, 0.02]:
		VertexShapes.tri(tool, Vector3(ARM_M, 0.075, z), Vector3(ARM_M, -0.075, z), tip + Vector3(0.0, 0.0, z), BOARD)
		VertexShapes.tri(tool, Vector3(ARM_M, -0.075, z), Vector3(ARM_M, 0.075, z), tip + Vector3(0.0, 0.0, z), BOARD)
	# os riscos escuros das letras (sem texto: só a ideia de uma inscrição)
	for x: float in [0.22, 0.4, 0.58]:
		VertexShapes.box(tool, Vector3(x, 0.0, 0.0), Vector3(0.06, 0.012, 0.024), WOOD)
	tool.generate_normals()
	return tool.commit()
