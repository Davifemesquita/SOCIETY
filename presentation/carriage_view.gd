class_name CarriageView
extends Node3D
## Fase 252: a carruagem à porta do teatro. Em cada teatro, na célula de estrada logo à frente da fachada de entrada mais perto do
## meio dela (`spot`, pelas `Footprint.front_cells`), a carruagem fechada de quatro rodas parada sem os cavalos, ao longo da rua: a
## caixa laqueada com as janelas e a porta, o teto com a borda, as rodas de trás maiores, a boleia na frente com o banco do
## cocheiro, as duas lanternas e os varais pousados no chão (`carriage_mesh`). Um MultiMesh; nada no save; refeito na obra, na
## demolição, na estrada e ao trocar de mundo.

const BUILDINGS: Array[StringName] = [&"theater"]
## A caixa: as meias medidas e a altura do fundo; as rodas: o raio das de trás e das da frente e a meia bitola.
const BODY_HALF := Vector3(0.75, 0.48, 0.55)
const BODY_FLOOR_M := 0.55
const REAR_WHEEL_M := 0.5
const FRONT_WHEEL_M := 0.36
const TRACK_M := 0.68
const LACQUER := Color(0.24, 0.08, 0.1)
const TRIM := Color(0.72, 0.58, 0.26)
const GLASS := Color(0.12, 0.14, 0.16)
const WHEEL := Color(0.3, 0.2, 0.12)
const IRON := Color(0.16, 0.16, 0.17)
const LEATHER := Color(0.16, 0.12, 0.1)
const WOOD := Color(0.42, 0.3, 0.2)

var _simulation: Simulation
var _carriages := MultiMeshInstance3D.new()
## Os lugares das carruagens (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.5
	_carriages.name = "Carriages"
	_carriages.multimesh = MultiMesh.new()
	_carriages.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_carriages.multimesh.mesh = carriage_mesh()
	_carriages.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_carriages.material_override = material
	add_child(_carriages)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func carriage_count() -> int:
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
	for id: int in world.building_ids():
		var found: Variant = spot(_simulation, world.building(id))
		if found is Transform3D:
			var place: Transform3D = found
			places.append(place)
	_carriages.multimesh.instance_count = places.size()
	for i: int in places.size():
		_carriages.multimesh.set_instance_transform(i, places[i])


## O lugar da carruagem do teatro (o meio da célula de estrada à frente, no chão, o x ao longo da rua), ou null: só no teatro com
## uma estrada encostada na fachada de entrada.
static func spot(simulation: Simulation, record: BuildingRecord) -> Variant:
	if record == null or record.def_id not in BUILDINGS:
		return null
	var grid := simulation.world.island(record.island_id)
	var def := simulation.def_of(record)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var middle := Vector2(area.position) + Vector2(area.size) * 0.5 - Vector2(0.5, 0.5)
	var best := Vector2i(-1, -1)
	for cell: Vector2i in Footprint.front_cells(record.origin, def.size, record.rotation):
		if not grid.has_road(cell):
			continue
		if best.x < 0 or Vector2(cell).distance_to(middle) < Vector2(best).distance_to(middle):
			best = cell
	if best.x < 0:
		return null
	# ao longo da rua: o eixo da fachada (a rua corre encostada nela)
	var front := Footprint.front_direction(record.rotation)
	var along := Vector3(absf(front.y), 0.0, absf(front.x))
	var foot := grid.cell_world(best)
	foot.y = grid.height_at(foot.x, foot.z)
	if grid.is_paved(best):
		foot.y += PavedDual.LIFT_M
	return Transform3D(Basis(along, Vector3.UP, along.cross(Vector3.UP)), foot)


## A carruagem com o pé no zero, a frente para +x: a caixa laqueada no alto do chassi com as janelas, a porta e o friso dourado, o
## teto com a borda e o corrimão da bagagem, as rodas (as de trás maiores) com os cubos, a boleia na frente com o banco do cocheiro,
## as duas lanternas e os varais pousados no chão.
static func carriage_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body := Vector3(-0.1, BODY_FLOOR_M + BODY_HALF.y, 0.0)
	VertexShapes.box(tool, body, BODY_HALF, LACQUER)
	VertexShapes.box(tool, body + Vector3(0.0, BODY_HALF.y + 0.03, 0.0), BODY_HALF + Vector3(0.06, -BODY_HALF.y + 0.03, 0.05),
			LEATHER)
	VertexShapes.box(tool, body + Vector3(0.0, -BODY_HALF.y * 0.2, 0.0), BODY_HALF + Vector3(0.008, -BODY_HALF.y + 0.015, 0.008),
			TRIM)
	for side: float in [-1.0, 1.0]:
		var face := side * (BODY_HALF.z + 0.004)
		for x: float in [-0.45, 0.25]:
			VertexShapes.box(tool, body + Vector3(x, BODY_HALF.y * 0.35, face), Vector3(0.17, 0.16, 0.006), GLASS)
		VertexShapes.box(tool, body + Vector3(-0.1, -0.05, face), Vector3(0.012, 0.42, 0.008), TRIM)
	# o chassi e as rodas
	VertexShapes.box(tool, Vector3(-0.1, BODY_FLOOR_M - 0.05, 0.0), Vector3(0.95, 0.04, 0.12), WOOD)
	for wheel: Array in [[-0.65, REAR_WHEEL_M], [0.55, FRONT_WHEEL_M]]:
		var x: float = wheel[0]
		var radius: float = wheel[1]
		VertexShapes.box(tool, Vector3(x, radius, 0.0), Vector3(0.03, 0.03, TRACK_M), IRON)
		for side: float in [-1.0, 1.0]:
			var hub := Vector3(x, radius, side * TRACK_M)
			VertexShapes.cylinder(tool, hub - Vector3(0.0, 0.0, 0.03), hub + Vector3(0.0, 0.0, 0.03), radius, WHEEL, 12)
			VertexShapes.cylinder(tool, hub - Vector3(0.0, 0.0, 0.06), hub + Vector3(0.0, 0.0, 0.06), 0.08, IRON, 8)
	# a boleia: o estrado inclinado, o banco do cocheiro e o encosto
	VertexShapes.box(tool, Vector3(0.82, 0.95, 0.0), Vector3(0.2, 0.03, 0.45), WOOD)
	VertexShapes.box(tool, Vector3(0.7, 1.2, 0.0), Vector3(0.12, 0.08, 0.42), LEATHER)
	VertexShapes.oriented_box(tool, Transform3D(Basis(Vector3.BACK, 0.4), Vector3(0.95, 0.8, 0.0)), Vector3(0.2, 0.02, 0.4),
			LACQUER)
	# as duas lanternas na frente da caixa
	for side: float in [-1.0, 1.0]:
		var lamp := Vector3(0.68, 1.05, side * (BODY_HALF.z + 0.08))
		VertexShapes.box(tool, lamp, Vector3(0.05, 0.08, 0.05), IRON)
		VertexShapes.box(tool, lamp, Vector3(0.035, 0.05, 0.055), TRIM)
	# os varais saindo da frente e pousados no chão
	for side: float in [-1.0, 1.0]:
		VertexShapes.strut(tool, Vector3(0.6, FRONT_WHEEL_M, side * 0.38), Vector3(2.1, 0.04, side * 0.42), 0.025, 0.025, WOOD)
	tool.generate_normals()
	return tool.commit()
