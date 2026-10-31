class_name PowerLineView
extends Node3D
## Fase 120: os postes e os fios. Nas células de estrada até o raio de cada usina (`BuildingDef.power_radius_cells`, a mesma
## folga entre retângulos da eletricidade), uma a cada POLE_EVERY pelo desenho da grade (`posmod(x + 3y, 4) = 2`: nunca a
## célula do poste de gás, que é o resto 0), um poste de madeira na beira do lado da calçada, com a travessa e dois
## isoladores (`poles`, `pole_mesh`). Cada poste se liga a até MAX_LINKS vizinhos mais perto, até LINK_M (`links`), e de
## cada ligação saem dois fios de isolador a isolador, caindo em curva (`HarborView.rope_span`), todos numa malha só. A
## travessa fica de través da direção média das ligações. Só apresentação; nada no save; refeito na obra, na demolição, na
## estrada e ao trocar de mundo.

const POLE_EVERY := 4
const POLE_REST := 2
const POLE_OFFSET_M := 0.85
const POLE_HEIGHT_M := 6.2
const POLE_RADIUS_M := 0.09
const ARM_M := Vector3(1.5, 0.1, 0.1)
const ARM_BELOW_TOP_M := 0.35
const INSULATOR_OUT_M := 0.6
const INSULATOR_M := 0.16
const LINK_M := 9.5
const MAX_LINKS := 2
const SPAN_STEP_M := 0.5
const WIRE_SAG := 0.035
const WIRE_RADIUS_M := 0.014
const WOOD := Color(0.33, 0.25, 0.18)
const ARM_WOOD := Color(0.38, 0.29, 0.2)
const PORCELAIN := Color(0.86, 0.85, 0.8)
const WIRE_COLOR := Color(0.09, 0.09, 0.09)
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var _simulation: Simulation
var _poles := MultiMeshInstance3D.new()
var _wires := MeshInstance3D.new()
var _wire_material := StandardMaterial3D.new()
var _spans: Array[PackedVector3Array] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.85
	var mesh := pole_mesh()
	mesh.surface_set_material(0, material)
	_poles.name = "Poles"
	_poles.multimesh = MultiMesh.new()
	_poles.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_poles.multimesh.mesh = mesh
	add_child(_poles)
	_wire_material.albedo_color = WIRE_COLOR
	_wire_material.roughness = 0.6
	_wire_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_wires.name = "Wires"
	_wires.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_wires)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func pole_count() -> int:
	return _poles.multimesh.instance_count


func wire_count() -> int:
	return _spans.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	var spots := poles(_simulation.world, _simulation.data)
	var pairs := links(spots, _simulation.world)
	var arms: Array[Vector3] = []
	for i: int in spots.size():
		arms.append(arm_direction(spots, pairs, i))
	var multimesh := _poles.multimesh
	multimesh.instance_count = spots.size()
	for i: int in spots.size():
		var across := arms[i]
		var basis := Basis(across, Vector3.UP, across.cross(Vector3.UP))
		multimesh.set_instance_transform(i, Transform3D(basis, spots[i]))
	multimesh.custom_aabb = WorldBounds.of(_simulation.config)
	_spans.clear()
	for pair: Vector2i in pairs:
		var a := pair.x
		var b := pair.y
		var tips_a := insulators(spots[a], arms[a])
		var tips_b := insulators(spots[b], arms[b])
		# o fio da esquerda vai ao isolador mais perto do outro lado (sem cruzar)
		if tips_a[0].distance_to(tips_b[0]) + tips_a[1].distance_to(tips_b[1]) \
				> tips_a[0].distance_to(tips_b[1]) + tips_a[1].distance_to(tips_b[0]):
			tips_b = PackedVector3Array([tips_b[1], tips_b[0]])
		for k: int in 2:
			_spans.append(HarborView.rope_span(tips_a[k], tips_b[k], WIRE_SAG))
	_wires.mesh = HarborView.rope_mesh(_spans, _wire_material, WIRE_RADIUS_M) if not _spans.is_empty() else null


## Os postes (o pé de cada um, no mundo): nas células de estrada até o raio de cada usina, uma a cada POLE_EVERY pelo
## desenho da grade, na beira do lado de fora da rua (célula cercada de rua não leva). Ilha plana também.
static func poles(world: WorldState, data: GameData) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var seen: Dictionary[Vector3i, bool] = {}
	for id: int in world.buildings:
		var record := world.buildings[id]
		var def := data.building(record.def_id)
		if def == null or not def.is_power_plant():
			continue
		var grid := world.island(record.island_id)
		var reach := Footprint.rect(record.origin, def.size, record.rotation).grow(def.power_radius_cells)
		reach = reach.intersection(Rect2i(Vector2i.ZERO, grid.size))
		for y: int in range(reach.position.y, reach.end.y):
			for x: int in range(reach.position.x, reach.end.x):
				var cell := Vector2i(x, y)
				if posmod(x + 3 * y, POLE_EVERY) != POLE_REST or not grid.has_road(cell):
					continue
				var key := Vector3i(record.island_id, x, y)
				if seen.has(key):
					continue
				seen[key] = true
				var side := Vector2i.ZERO
				for step: Vector2i in SIDES:
					var next := cell + step
					if grid.in_bounds(next) and not grid.has_road(next):
						side = step
						break
				if side == Vector2i.ZERO:
					continue
				var center := grid.surface_world(cell) + Vector3(side.x, 0.0, side.y) * POLE_OFFSET_M
				center.y = grid.height_at(center.x, center.z) if not grid.flat else center.y
				result.append(center)
	return result


## As ligações [i, j] (i < j): cada poste com até MAX_LINKS vizinhos mais perto, até LINK_M; com o mundo, só as de vão
## livre (`clear_span`: o fio passando por cima de um prédio entrava na parede).
static func links(spots: Array[Vector3], world: WorldState = null) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var seen: Dictionary[Vector2i, bool] = {}
	for i: int in spots.size():
		var near: Array = []
		for j: int in spots.size():
			if j == i:
				continue
			var meters := Vector2(spots[i].x - spots[j].x, spots[i].z - spots[j].z).length()
			if meters <= LINK_M and (world == null or clear_span(world, spots[i], spots[j])):
				near.append([meters, j])
		near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0] if a[0] != b[0] else a[1] < b[1])
		for k: int in mini(near.size(), MAX_LINKS):
			var j: int = near[k][1]
			var pair := Vector2i(mini(i, j), maxi(i, j))
			if not seen.has(pair):
				seen[pair] = true
				result.append(pair)
	return result


## O vão entre dois postes não passa por nenhuma célula de prédio (conferido a cada SPAN_STEP_M).
static func clear_span(world: WorldState, a: Vector3, b: Vector3) -> bool:
	var length := Vector2(b.x - a.x, b.z - a.z).length()
	var steps := maxi(ceili(length / SPAN_STEP_M), 1)
	for k: int in range(1, steps):
		var at := a.lerp(b, float(k) / steps)
		for grid: IslandGrid in world.islands:
			if grid.world_rect().has_point(Vector2(at.x, at.z)):
				if grid.building_at(grid.world_to_cell(at)) != 0:
					return false
				break
	return true


## A direção da travessa do poste i (no chão, de través da direção média das ligações dele); x sem ligação.
static func arm_direction(spots: Array[Vector3], pairs: Array[Vector2i], i: int) -> Vector3:
	var along := Vector3.ZERO
	for pair: Vector2i in pairs:
		if pair.x != i and pair.y != i:
			continue
		var other := pair.y if pair.x == i else pair.x
		var step := spots[other] - spots[i]
		step.y = 0.0
		if step.length_squared() < 1e-6:
			continue
		step = step.normalized()
		# a direção sem sentido: soma virando para o mesmo lado
		if along.dot(step) < 0.0:
			step = -step
		along += step
	if along.length_squared() < 1e-6:
		return Vector3.RIGHT
	along = along.normalized()
	return Vector3(-along.z, 0.0, along.x)


## As pontas dos dois isoladores do poste no pé spot, com a travessa em across.
static func insulators(spot: Vector3, across: Vector3) -> PackedVector3Array:
	var top := spot + Vector3(0.0, POLE_HEIGHT_M - ARM_BELOW_TOP_M + ARM_M.y * 0.5 + INSULATOR_M, 0.0)
	return PackedVector3Array([top - across * INSULATOR_OUT_M, top + across * INSULATOR_OUT_M])


## O poste: o fuste de madeira afinando, a travessa em x, as duas escoras e os dois isoladores de porcelana.
static func pole_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.cylinder(tool, Vector3(0.0, -0.3, 0.0), Vector3(0.0, POLE_HEIGHT_M, 0.0), POLE_RADIUS_M, WOOD, 8)
	var arm_y := POLE_HEIGHT_M - ARM_BELOW_TOP_M
	VertexShapes.box(tool, Vector3(0.0, arm_y, 0.0), ARM_M * 0.5, ARM_WOOD)
	for side: float in [-1.0, 1.0]:
		VertexShapes.strut(tool, Vector3(0.0, arm_y - 0.55, 0.0), Vector3(side * 0.5, arm_y - 0.05, 0.0), 0.025, 0.025,
				ARM_WOOD)
		var foot := Vector3(side * INSULATOR_OUT_M, arm_y + ARM_M.y * 0.5, 0.0)
		VertexShapes.cylinder(tool, foot, foot + Vector3(0.0, INSULATOR_M, 0.0), 0.035, PORCELAIN, 6)
	tool.generate_normals()
	return tool.commit()
