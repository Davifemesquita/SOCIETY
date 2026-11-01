class_name SundialView
extends Node3D
## Fase 224: o relógio de sol no largo. Em cada serviço com largo calçado (`ForecourtView.PLAZA_SERVICES`, Fase 109), numa das
## células de canto do anel do largo — a mais para a frente que esteja no largo (`cells`) —, a
## coluna de pedra torneada com o mostrador de bronze esverdeado em cima, as marcas das horas e o gnomon apontado para o norte
## (−z do mundo) (`dial_mesh`). Só na ilha com relevo (a ilha plana não tem largo); um MultiMesh; nada no save; refeito na obra,
## na demolição, na estrada, no trilho, na derrubada de árvores e ao trocar de mundo.

## O perfil torneado da coluna: [raio, altura] de baixo para cima (plinto, toro, fuste afinando, capitel).
const COLUMN_PROFILE: Array[Vector2] = [Vector2(0.3, 0.0), Vector2(0.3, 0.12), Vector2(0.24, 0.16), Vector2(0.26, 0.22),
		Vector2(0.15, 0.28), Vector2(0.12, 0.85), Vector2(0.16, 0.92), Vector2(0.28, 1.0), Vector2(0.28, 1.06),
		Vector2(0.0, 1.06)]
const SIDES := 12
const DIAL_R := 0.25
const DIAL_Y := 1.07
const STONE := Color(0.7, 0.68, 0.63)
const BRONZE := Color(0.36, 0.5, 0.42)
const BRONZE_DARK := Color(0.22, 0.3, 0.25)

var _simulation: Simulation
var _dials := MultiMeshInstance3D.new()
## Os lugares (o pé da coluna no chão) (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.8
	_dials.name = "Sundials"
	_dials.multimesh = MultiMesh.new()
	_dials.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_dials.multimesh.mesh = dial_mesh()
	_dials.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_dials.material_override = material
	add_child(_dials)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.trees_changed.connect(_mark_trees)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func dial_count() -> int:
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
			var at := grid.cell_world(cell)
			at.y = BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE)).y + ForecourtView.SLAB_LIFT_M
			places.append(Transform3D(Basis.IDENTITY, at))
	_dials.multimesh.instance_count = places.size()
	for i: int in places.size():
		_dials.multimesh.set_instance_transform(i, places[i])


## As células dos relógios da ilha → o id do serviço: para cada serviço do largo, o canto do anel em volta dele mais para a
## frente (e, no empate, o primeiro da lista) que esteja no largo.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}
	var grid := world.island(island_id)
	if grid == null or grid.flat:
		return result
	var forecourt := ForecourtView.cells(world, data, island_id)
	if forecourt.is_empty():
		return result
	var ids: Array[int] = []
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id == island_id and record.def_id in ForecourtView.PLAZA_SERVICES:
			ids.append(id)
	ids.sort()
	for id: int in ids:
		var record := world.buildings[id]
		var area := Footprint.rect(record.origin, data.building(record.def_id).size, record.rotation)
		var front := Vector2(Footprint.front_direction(record.rotation))
		var middle := Vector2(area.position) + Vector2(area.size) * 0.5
		var corners: Array[Vector2i] = [area.position - Vector2i.ONE, Vector2i(area.end.x, area.position.y - 1),
				Vector2i(area.position.x - 1, area.end.y), area.end]
		var best := Vector2i(-1, -1)
		var best_score := -INF
		for corner: Vector2i in corners:
			if not forecourt.has(corner) or result.has(corner):
				continue
			var score := (Vector2(corner) + Vector2(0.5, 0.5) - middle).dot(front)
			if score > best_score + 1e-4:
				best_score = score
				best = corner
		if best.x >= 0:
			result[best] = id
	return result


## A coluna com o pé no zero: o perfil torneado de pedra, o mostrador de bronze em cima com as doze marcas das horas e o
## gnomon em triângulo, o lado reto para o norte (−z).
static func dial_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k: int in COLUMN_PROFILE.size() - 1:
		var low: Vector2 = COLUMN_PROFILE[k]
		var high: Vector2 = COLUMN_PROFILE[k + 1]
		for s: int in SIDES:
			var a0 := TAU * s / SIDES
			var a1 := TAU * (s + 1) / SIDES
			# o ângulo anda de +x para −z (o sentido do VertexShapes.cylinder): a face para fora
			var p := Vector3(cos(a0), 0.0, -sin(a0))
			var q := Vector3(cos(a1), 0.0, -sin(a1))
			VertexShapes.quad(tool, p * low.x + Vector3(0.0, low.y, 0.0), p * high.x + Vector3(0.0, high.y, 0.0),
					q * high.x + Vector3(0.0, high.y, 0.0), q * low.x + Vector3(0.0, low.y, 0.0), STONE)
	# o mostrador: o disco de bronze, as marcas e o gnomon
	VertexShapes.cylinder(tool, Vector3(0.0, DIAL_Y - 0.02, 0.0), Vector3(0.0, DIAL_Y + 0.01, 0.0), DIAL_R, BRONZE, 16)
	for hour: int in 12:
		var angle := PI * float(hour) / 11.0
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		VertexShapes.strut(tool, Vector3(0.0, DIAL_Y + 0.012, 0.0) + dir * (DIAL_R - 0.07), Vector3(0.0, DIAL_Y + 0.012, 0.0)
				+ dir * (DIAL_R - 0.02), 0.006, 0.003, BRONZE_DARK)
	var foot := Vector3(0.0, DIAL_Y + 0.01, 0.0)
	for side: float in [-1.0, 1.0]:
		var dx := Vector3(side * 0.006, 0.0, 0.0)
		VertexShapes.tri(tool, foot + dx + Vector3(0.0, 0.0, 0.06), foot + dx + Vector3(0.0, 0.0, -DIAL_R + 0.02),
				foot + dx + Vector3(0.0, 0.17, 0.06), BRONZE_DARK)
		VertexShapes.tri(tool, foot + dx + Vector3(0.0, 0.0, 0.06), foot + dx + Vector3(0.0, 0.17, 0.06),
				foot + dx + Vector3(0.0, 0.0, -DIAL_R + 0.02), BRONZE_DARK)
	tool.generate_normals()
	return tool.commit()
