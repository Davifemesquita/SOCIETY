class_name RoofPigeonView
extends Node3D
## Fase 210: os pombos na cumeeira. Numa casa a cada PIGEON_EVERY pelo id (resto PIGEON_REST), de telhado de duas águas (sem a
## ala da Fase 96, a mansarda nem a abóbada), uma fila de três a cinco pombos pousados na capa da cumeeira, na metade dela longe
## da chaminé, cada um virado para uma das águas e um pouco torto (`pigeons`), um pouco maiores que de verdade (`SIZE`). Parados
## (com centenas de casas, virar as cabeças a cada quadro pesaria); o pombo cinza-azulado da rua (`pigeon_mesh`). No lugar do
## modelo (`BuildingView.model_place`); um MultiMesh sem sombra; nada no save; refeito na obra, na demolição, na subida de classe e
## ao trocar de mundo.

const PIGEON_EVERY := 5
const PIGEON_REST := 2
const SIZE := 1.3
## A fila: do meio da cumeeira o primeiro, o passo entre eles e a folga até a ponta.
const FIRST_M := 0.3
const STEP_M := 0.42
const END_CLEAR_M := 0.3
const MAX_TURN_RAD := 0.5
const SALT := 210
const BODY := Color(0.42, 0.44, 0.5)
const DARK := Color(0.2, 0.21, 0.25)
const NECK := Color(0.32, 0.45, 0.42)
const FEET := Color(0.72, 0.3, 0.28)
const BEAK := Color(0.22, 0.2, 0.2)

var _simulation: Simulation
var _pigeons := MultiMeshInstance3D.new()
## Os lugares dos pombos (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	_pigeons.name = "RoofPigeons"
	_pigeons.multimesh = MultiMesh.new()
	_pigeons.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_pigeons.multimesh.mesh = pigeon_mesh()
	_pigeons.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_pigeons.material_override = material
	_pigeons.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_pigeons)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.house_upgraded.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func pigeon_count() -> int:
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
		places.append_array(pigeons(_simulation, world.building(id)))
	_pigeons.multimesh.instance_count = places.size()
	for i: int in places.size():
		_pigeons.multimesh.set_instance_transform(i, places[i])


## Os pombos da casa (no mundo, o pé na capa da cumeeira, a frente −z para uma das águas), ou nenhum.
static func pigeons(simulation: Simulation, record: BuildingRecord) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	if record == null or not record.is_house() or posmod(record.id, PIGEON_EVERY) != PIGEON_REST:
		return result
	var grid := simulation.world.island(record.island_id)
	var spec := BuildingKit.spec_for(simulation, record, grid.cell_size)
	if spec == null or spec.roof not in [BuildingKit.Roof.GABLE_X, BuildingKit.Roof.GABLE_Z] or spec.wing != 0 \
			or spec.mansard or spec.vault:
		return result
	var hall := spec.hall()
	var along_x := spec.roof == BuildingKit.Roof.GABLE_X
	var along := Vector3(1.0, 0.0, 0.0) if along_x else Vector3(0.0, 0.0, 1.0)
	var half := (hall.size_m().x if along_x else hall.size_m().y) * 0.5
	var ridge := spec.hall_offset() + Vector3(0.0, hall.height_m + hall.roof_m + BuildingKit.RIDGE_CAP_M * 0.6, 0.0)
	var seed_value := FireflyView.cell_hash(record.island_id, record.id, 0, SALT)
	# a metade da cumeeira longe da chaminé (sem chaminé, pelo hash)
	var side := 1.0 if seed_value % 2 == 0 else -1.0
	var chimney: Variant = BuildingKit.chimney_top(spec)
	if chimney is Vector3:
		var top: Vector3 = chimney
		side = -1.0 if (top - ridge).dot(along) > 0.0 else 1.0
	var count := 3 + (seed_value >> 4) % 3
	var def := simulation.def_of(record)
	var model := BuildingView.model_place(grid, record, Footprint.rect(record.origin, def.size, record.rotation))
	# de frente para uma das águas: o −z da malha de través da cumeeira
	var across_yaw := 0.0 if along_x else PI * 0.5
	for k: int in count:
		var u := FIRST_M + k * STEP_M
		if u > half - END_CLEAR_M:
			break
		var h := FireflyView.cell_hash(record.island_id, record.id, k + 1, SALT)
		var yaw := across_yaw + (PI if h % 2 == 0 else 0.0) + (float((h >> 3) % 100) / 99.0 - 0.5) * 2.0 * MAX_TURN_RAD
		var local := Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * SIZE), ridge + along * side * u)
		result.append(model * local)
	return result


## O pombo de pé, de frente para −z, com o pé em y = 0 (uns 30 cm de comprimento), em poucas faces (são centenas no telhado da
## cidade): o corpo e a cabeça em bolas de 6 × 3 faces (`CropView._sphere`, `_ball`) esticadas, o peito furta-cor, o rabo
## escuro em cunha e as duas faixas escuras da asa em placas, e as patas.
static func pigeon_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ball := CropView._sphere(1.0)
	_ball(tool, ball, Transform3D(Basis.from_scale(Vector3(0.075, 0.07, 0.12)), Vector3(0.0, 0.1, 0.0)), BODY)
	_ball(tool, ball, Transform3D(Basis.from_scale(Vector3(0.05, 0.055, 0.05)), Vector3(0.0, 0.13, -0.08)), NECK)
	_ball(tool, ball, Transform3D(Basis.from_scale(Vector3(0.035, 0.035, 0.04)), Vector3(0.0, 0.2, -0.11)), BODY)
	# o rabo: uma cunha chata e escura saindo de trás
	var root := Vector3(0.0, 0.12, 0.09)
	for flip: Array in [[-1.0, 1.0], [1.0, -1.0]]:
		var a: float = flip[0]
		var b: float = flip[1]
		VertexShapes.tri(tool, root + Vector3(a * 0.03, 0.0, 0.0), root + Vector3(b * 0.03, 0.0, 0.0),
				root + Vector3(0.0, 0.01, 0.14), DARK)
	for side: float in [-1.0, 1.0]:
		for z: float in [0.02, 0.06]:
			VertexShapes.quad(tool, Vector3(side * 0.074, 0.13, z), Vector3(side * 0.076, 0.13, z + 0.02),
					Vector3(side * 0.074, 0.11, z + 0.02), Vector3(side * 0.072, 0.11, z), DARK)
		VertexShapes.strut(tool, Vector3(side * 0.025, 0.0, 0.0), Vector3(side * 0.025, 0.05, 0.0), 0.006, 0.006, FEET)
	tool.generate_normals()
	return tool.commit()


## Uma bola no lugar place, sem normal (o generate_normals do fim faz todas: misturar a normal do `CropView._part` com as faces
## sem normal do `VertexShapes` no mesmo SurfaceTool faz o Godot reclamar).
static func _ball(tool: SurfaceTool, mesh: PrimitiveMesh, place: Transform3D, color: Color) -> void:
	var arrays := mesh.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for index: int in indices:
		tool.set_color(color)
		tool.add_vertex(place * vertices[index])
