class_name TopiaryView
extends Node3D
## Fase 212: o buxo na porta. Nas casas de pórtico (`TierDef.HouseTrim.PORTICO`, os investidores), dois vasos de pedra com o buxo
## podado em bola, um de cada lado da porta, por fora das colunas da Fase 13 (`places_of`: SIDE_CELLS da largura da célula do
## meio da porta para cada lado, OUT_M à frente da parede, na frente da sebe). O vaso torneado com a borda e o pé, a terra e a
## bola de folhas escuras com um tufo mais claro (`pot_mesh`). No lugar do modelo (`BuildingView.model_place`); um MultiMesh;
## nada no save; refeito na obra, na demolição, na subida de classe e ao trocar de mundo.

const SIDE_CELLS := 0.68
const OUT_M := 0.62
const STONE := Color(0.72, 0.7, 0.65)
const STONE_DARK := Color(0.56, 0.54, 0.5)
const SOIL := Color(0.26, 0.19, 0.14)
const LEAVES := Color(0.13, 0.27, 0.12)
const LEAVES_LIGHT := Color(0.2, 0.36, 0.16)
## O perfil do vaso (raio, altura), de baixo para cima: o pé, a cintura, o bojo e a borda.
const POT_PROFILE: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(0.2, 0.0), Vector2(0.2, 0.06), Vector2(0.13, 0.1),
		Vector2(0.15, 0.2), Vector2(0.22, 0.42), Vector2(0.24, 0.5), Vector2(0.24, 0.55), Vector2(0.2, 0.55)]
const BALL_R_M := 0.36
const SIDES := 10

var _simulation: Simulation
var _pots := MultiMeshInstance3D.new()
## Os lugares dos vasos (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.85
	_pots.name = "Topiary"
	_pots.multimesh = MultiMesh.new()
	_pots.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_pots.multimesh.mesh = pot_mesh()
	_pots.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_pots.material_override = material
	add_child(_pots)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.house_upgraded.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func pot_count() -> int:
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
		places.append_array(places_of(_simulation, world.building(id)))
	_pots.multimesh.instance_count = places.size()
	for i: int in places.size():
		_pots.multimesh.set_instance_transform(i, places[i])


## Os dois vasos da casa de pórtico (no mundo, o pé no chão), ou nenhum.
static func places_of(simulation: Simulation, record: BuildingRecord) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	if record == null or not record.is_house():
		return result
	var tier := simulation.data.tier(record.tier)
	if tier == null or tier.house_trim != TierDef.HouseTrim.PORTICO:
		return result
	var grid := simulation.world.island(record.island_id)
	var spec := BuildingKit.spec_for(simulation, record, grid.cell_size)
	if spec == null:
		return result
	var hall := spec.hall()
	var door := spec.hall_offset() + BuildingKit._wall_point(hall, 0, hall.door_index, 0)
	var step := hall.size_m().x / hall.cells.x
	var def := simulation.def_of(record)
	var model := BuildingView.model_place(grid, record, Footprint.rect(record.origin, def.size, record.rotation))
	for side: float in [-1.0, 1.0]:
		var local := Vector3(door.x + side * SIDE_CELLS * step, 0.0, door.z - OUT_M)
		var place := model * Transform3D(Basis.IDENTITY, local)
		place.origin.y = maxf(grid.height_at(place.origin.x, place.origin.z), model.origin.y - 0.6)
		result.append(place)
	return result


## O vaso com o pé no zero: o perfil torneado de pedra (a borda mais escura), a terra e a bola de buxo podada com um tufo mais
## claro em cima.
static func pot_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in POT_PROFILE.size() - 1:
		var a := POT_PROFILE[i]
		var b := POT_PROFILE[i + 1]
		var color := STONE_DARK if i >= POT_PROFILE.size() - 3 or i == 0 else STONE
		for k: int in SIDES:
			var t0 := TAU * k / SIDES
			var t1 := TAU * (k + 1) / SIDES
			var p0 := Vector3(cos(t0), 0.0, sin(t0))
			var p1 := Vector3(cos(t1), 0.0, sin(t1))
			VertexShapes.quad(tool, p0 * a.x + Vector3(0.0, a.y, 0.0), p1 * a.x + Vector3(0.0, a.y, 0.0),
					p1 * b.x + Vector3(0.0, b.y, 0.0), p0 * b.x + Vector3(0.0, b.y, 0.0), color)
	VertexShapes.cylinder(tool, Vector3(0.0, 0.5, 0.0), Vector3(0.0, 0.52, 0.0), 0.2, SOIL, SIDES)
	var ball := Vector3(0.0, 0.52 + BALL_R_M * 0.85, 0.0)
	TopiaryView._ball(tool, Transform3D(Basis.from_scale(Vector3.ONE * BALL_R_M), ball), LEAVES)
	TopiaryView._ball(tool, Transform3D(Basis.from_scale(Vector3(0.6, 0.45, 0.6) * BALL_R_M), ball + Vector3(0.04, BALL_R_M * 0.6,
			-0.03)), LEAVES_LIGHT)
	tool.generate_normals()
	return tool.commit()


## Uma bola no lugar place, sem normal (o generate_normals do fim faz todas, como no pombo da Fase 210).
static func _ball(tool: SurfaceTool, place: Transform3D, color: Color) -> void:
	var sphere := CropView._sphere(1.0)
	# mais redonda que a das plantas: é o buxo podado, de perto, e são poucos vasos na cidade
	sphere.radial_segments = 10
	sphere.rings = 5
	var arrays := sphere.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for index: int in indices:
		tool.set_color(color)
		tool.add_vertex(place * vertices[index])
