class_name MudWallowView
extends Node3D
## Fase 227: o lamaçal do chiqueiro. Em cada pasto de uma fazenda de porcos (o dono pelo `DerivedState.module_owner`, como os
## bichos da Fase 13), uma poça de lama do lado oposto ao cocho da Fase 118 e para a frente (`spot`): a lama escura e lisa,
## molhada (pouca aspereza), de borda recortada, com a orla de terra pisada mais clara em volta e uns torrões (`mud_mesh`),
## assentada no chão. Um MultiMesh; nada no save; refeito na obra, na demolição e ao trocar de mundo.

const PIG_FARM := &"pig_farm"
## A poça: os raios da elipse, a orla, quanto a borda recorta e a altura sobre o chão.
const RADIUS_M := Vector2(1.05, 0.75)
const RIM_M := 0.28
const RAGGED := 0.18
const SIDES := 18
const LIFT_M := 0.03
## Do meio do pasto: para o lado oposto ao do cocho e para a frente.
const ASIDE_M := 1.2
const AHEAD_M := 0.7
const MUD := Color(0.2, 0.14, 0.09)
const RIM := Color(0.38, 0.29, 0.2)

var _simulation: Simulation
var _mud := MultiMeshInstance3D.new()
## Os lugares (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.3
	material.metallic_specular = 0.6
	_mud.name = "MudWallows"
	_mud.multimesh = MultiMesh.new()
	_mud.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_mud.multimesh.mesh = mud_mesh()
	_mud.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_mud.material_override = material
	_mud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mud)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func wallow_count() -> int:
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
	var derived := _simulation.derived_state()
	var ids := world.building_ids()
	ids.sort()
	for id: int in ids:
		var record := world.building(id)
		if record.def_id != &"pasture":
			continue
		var owner_id: int = derived.module_owner.get(id, 0)
		var farm := world.building(owner_id)
		if farm == null or farm.def_id != PIG_FARM:
			continue
		places.append(spot(world, _simulation.data, record))
	_mud.multimesh.instance_count = places.size()
	for i: int in places.size():
		_mud.multimesh.set_instance_transform(i, places[i])


## O lugar da poça no pasto: do meio, ASIDE_M para o lado oposto ao do cocho e AHEAD_M para a frente, girada pelo id, na altura
## do chão.
static func spot(world: WorldState, data: GameData, record: BuildingRecord) -> Transform3D:
	var grid := world.island(record.island_id)
	var def := data.building(record.def_id)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var trough := RoadMask.trough_of(record, def, grid.cell_size)
	var middle := (Vector2(area.position) + Vector2(area.size) * 0.5) * grid.cell_size
	var along := trough[1]
	var front := Vector2(Footprint.front_direction(record.rotation))
	var side := signf((trough[0] - middle).dot(along))
	if side == 0.0:
		side = 1.0
	var at := middle - along * side * ASIDE_M + front * AHEAD_M
	var x := grid.origin_m.x + at.x
	var z := grid.origin_m.y + at.y
	var turn := float(posmod(record.id * 37, 360)) * PI / 180.0
	return Transform3D(Basis(Vector3.UP, turn), Vector3(x, grid.height_at(x, z) + LIFT_M, z))


## A poça com o meio na origem: a lama numa elipse de borda recortada (sem sorteio, pelo ângulo), a orla de terra pisada em
## volta, um pouco mais baixa nas pontas de fora, e quatro torrões na beira.
static func mud_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var inner: Array[Vector3] = []
	var outer: Array[Vector3] = []
	for s: int in SIDES:
		var angle := TAU * s / SIDES
		var wobble := 1.0 + RAGGED * sin(angle * 3.0 + 0.7) * cos(angle * 2.0 - 0.4)
		var dir := Vector3(cos(angle) * RADIUS_M.x, 0.0, sin(angle) * RADIUS_M.y) * wobble
		inner.append(dir)
		outer.append(dir + dir.normalized() * RIM_M + Vector3(0.0, -0.02, 0.0))
	for s: int in SIDES:
		var n := (s + 1) % SIDES
		# o ângulo anda de +x para +z: visto de cima é horário, a face para cima
		VertexShapes.tri(tool, Vector3(0.0, -0.005, 0.0), inner[s], inner[n], MUD)
		VertexShapes.quad(tool, inner[s], outer[s], outer[n], inner[n], RIM)
	for k: int in 4:
		var angle := TAU * k / 4.0 + 0.5
		var at := Vector3(cos(angle) * RADIUS_M.x, 0.0, sin(angle) * RADIUS_M.y) * 1.05
		PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.12, 0.06, 0.1)), at), RIM.darkened(0.2))
	tool.generate_normals()
	return tool.commit()
