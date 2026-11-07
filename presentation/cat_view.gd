class_name CatView
extends Node3D
## Fase 200: o gato na porta. Numa casa a cada CAT_EVERY pelo id (resto CAT_REST), menos as que têm cão (AnimalView.DOG_EVERY),
## um gato sentado no chão ao lado da porta, SIDE_M do meio dela para o lado que não é o do banco da Fase 174 e antes dos vasos
## da Fase 15, de frente para a rua, um pouco torto e um pouco maior que de verdade (`spot`, `SIZE`). O corpo sentado com o rabo
## enrolado nas patas (`body_mesh`) é parado; a cabeça (`head_mesh`) olha para um lado ou para o outro de tempos em tempos, cada
## gato no seu ritmo: o giro é do `shaders/cat_head.gdshader`, no tempo visual, com a conta de `glance` (a CPU não mexe nas
## cabeças a cada quadro: com ~120 gatos na cidade do benchmark, mexer pesava no quadro). A pelagem (ruivo, preto, cinza,
## branco, creme) é a cor da instância. Dois MultiMesh sem sombra; nada no save; refeito na obra, na demolição, na subida de
## classe e ao trocar de mundo.

const CAT_EVERY := 4
const CAT_REST := 3
const SIDE_M := 0.62
## O gato um pouco maior que de verdade, na escala das galinhas e do cão, para se ver da câmera do jogo.
const SIZE := 1.3
const OUT_M := 0.26
## O pescoço (o pivô da cabeça) e quanto ela vira.
const NECK := Vector3(0.0, 0.2, -0.05)
const LOOK_RAD := 0.9
const LOOK_EVERY_S := Vector2(4.0, 9.0)
const FURS: Array[Color] = [Color(0.85, 0.5, 0.22), Color(0.14, 0.13, 0.13), Color(0.52, 0.52, 0.53), Color(0.93, 0.92, 0.9),
		Color(0.86, 0.76, 0.6)]
const FUR := Color(1.0, 1.0, 1.0)
const BELLY := Color(1.0, 0.97, 0.94)
const EYE := Color(0.25, 0.32, 0.1)
const NOSE := Color(0.75, 0.48, 0.48)
const SALT := 200

var _simulation: Simulation
var _bodies := MultiMeshInstance3D.new()
var _heads := MultiMeshInstance3D.new()
## Cada gato (o pé no chão, de frente para −z) e a semente dele (testes: sem tela o MultiMesh devolve zeros).
var places: Array[Transform3D] = []
var _seeds := PackedInt32Array()
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var fur := StandardMaterial3D.new()
	fur.vertex_color_use_as_albedo = true
	fur.vertex_color_is_srgb = true
	fur.roughness = 0.8
	var head := ShaderMaterial.new()
	head.shader = load("res://shaders/cat_head.gdshader") as Shader
	head.set_shader_parameter(&"look_rad", LOOK_RAD)
	for part: Array in [[_bodies, "CatBodies", body_mesh(), fur], [_heads, "CatHeads", head_mesh(), head]]:
		var layer: MultiMeshInstance3D = part[0]
		var label: String = part[1]
		var mesh: ArrayMesh = part[2]
		var material: Material = part[3]
		layer.name = label
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.use_colors = true
		layer.multimesh.use_custom_data = layer == _heads
		layer.multimesh.mesh = mesh
		layer.multimesh.custom_aabb = WorldBounds.of(simulation.config)
		layer.material_override = material
		# pequeno demais para a sombra valer as passadas dela
		layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(layer)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.house_upgraded.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func cat_count() -> int:
	return places.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	places.clear()
	_seeds.clear()
	var world := _simulation.world
	for id: int in world.building_ids():
		var found: Variant = spot(_simulation, world.building(id))
		if found is Transform3D:
			var place: Transform3D = found
			places.append(place)
			_seeds.append(FireflyView.cell_hash(world.building(id).island_id, id, 0, SALT))
	for layer: MultiMeshInstance3D in [_bodies, _heads]:
		layer.multimesh.instance_count = places.size()
	for i: int in places.size():
		var fur := FURS[_seeds[i] % FURS.size()]
		_bodies.multimesh.set_instance_transform(i, places[i])
		_bodies.multimesh.set_instance_color(i, fur)
		_heads.multimesh.set_instance_transform(i, places[i] * Transform3D(Basis.IDENTITY, NECK))
		_heads.multimesh.set_instance_color(i, fur)
		_heads.multimesh.set_instance_custom_data(i, glance_data(_seeds[i]))


## O ritmo da cabeça do gato de semente seed para o shader: [a volta (s), onde ela começa, o lado da primeira volta].
static func glance_data(seed_value: int) -> Color:
	return Color(lerpf(LOOK_EVERY_S.x, LOOK_EVERY_S.y, float(seed_value % 89) / 88.0), float(seed_value % 19) / 19.0,
			float(posmod(seed_value, 2)), 0.0)


## Para onde o gato de semente seed olha no instante time (rad, em volta do pescoço): quase sempre para a frente, uma vez por
## volta vira a cabeça para um lado (que muda a cada volta) e volta. A conta do `shaders/cat_head.gdshader`, pelo glance_data.
static func glance(seed_value: int, time: float) -> float:
	var data := glance_data(seed_value)
	var turns := time / data.r + data.g
	var phase := fposmod(turns, 1.0)
	var side := 1.0 if posmod(floori(turns) + int(data.b), 2) == 0 else -1.0
	return side * LOOK_RAD * smoothstep(0.5, 0.6, phase) * (1.0 - smoothstep(0.85, 0.95, phase))


## O lugar do gato da casa (o pé no chão, de frente para a rua), ou null.
static func spot(simulation: Simulation, record: BuildingRecord) -> Variant:
	if record == null or not record.is_house() or posmod(record.id, CAT_EVERY) != CAT_REST \
			or record.id % AnimalView.DOG_EVERY == 0:
		return null
	var grid := simulation.world.island(record.island_id)
	var spec := BuildingKit.spec_for(simulation, record, grid.cell_size)
	if spec == null:
		return null
	var hall := spec.hall()
	var door := BuildingKit._wall_point(hall, 0, hall.door_index, 0)
	# do lado da porta que o banco da Fase 174 não usa (ele fica do lado com mais parede)
	var side := -1.0 if hall.door_index < hall.cells.x / 2 else 1.0
	var local := spec.hall_offset() + Vector3(door.x + side * SIDE_M, 0.0, door.z - OUT_M)
	var def := simulation.def_of(record)
	var model := BuildingView.model_place(grid, record, Footprint.rect(record.origin, def.size, record.rotation))
	var seed_value := FireflyView.cell_hash(record.island_id, record.id, 1, SALT)
	var turn := (float(seed_value % 100) / 99.0 - 0.5) * 0.9
	var place := model * Transform3D(Basis(Vector3.UP, turn).scaled(Vector3.ONE * SIZE), local)
	place.origin.y = maxf(grid.height_at(place.origin.x, place.origin.z), model.origin.y - 0.6)
	return place


## O corpo sentado com o pé no zero, de frente para −z (uns 25 cm de alto até o pescoço): o tronco, as ancas, o peito claro, as
## patas da frente e o rabo enrolado em volta delas. Branco: a pelagem vem da cor da instância.
static func body_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.075, 0.11, 0.09)), Vector3(0.0, 0.12, 0.0)), FUR)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.09, 0.07, 0.1)), Vector3(0.0, 0.07, 0.04)), FUR)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.05, 0.07, 0.03)), Vector3(0.0, 0.13, -0.075)), BELLY)
	for side: float in [-1.0, 1.0]:
		VertexShapes.strut(tool, Vector3(side * 0.03, 0.014, -0.07), Vector3(side * 0.03, 0.15, -0.05), 0.014, 0.014, FUR)
		PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.022, 0.014, 0.03)), Vector3(side * 0.03, 0.014,
				-0.085)), BELLY)
	# o rabo: de trás das ancas, rente ao chão, em volta do lado direito até a frente das patas
	var last := Vector3(0.0, 0.03, 0.13)
	for k: int in range(1, 8):
		var angle := PI * 0.5 + k * 0.32
		var point := Vector3(cos(angle) * -0.11, 0.025, sin(angle) * 0.12 - 0.0)
		VertexShapes.strut(tool, last, point, 0.016, 0.016, FUR)
		last = point
	tool.generate_normals()
	return tool.commit()


## A cabeça com o pivô no pescoço, o focinho para −z: a cabeça redonda, o focinho, as orelhas em ponta, os olhos e o nariz.
static func head_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.06, 0.055, 0.055)), Vector3(0.0, 0.05, -0.02)), FUR)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.03, 0.022, 0.025)), Vector3(0.0, 0.035, -0.07)), BELLY)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.009, 0.007, 0.006)), Vector3(0.0, 0.045, -0.094)), NOSE)
	for side: float in [-1.0, 1.0]:
		var base_a := Vector3(side * 0.018, 0.09, -0.03)
		var base_b := Vector3(side * 0.052, 0.075, -0.015)
		var tip := Vector3(side * 0.042, 0.135, -0.02)
		VertexShapes.tri(tool, base_a, tip, base_b, FUR)
		VertexShapes.tri(tool, base_a, base_b, tip, FUR)
		PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.011, 0.009, 0.006)), Vector3(side * 0.024, 0.063,
				-0.07)), EYE)
	tool.generate_normals()
	return tool.commit()
