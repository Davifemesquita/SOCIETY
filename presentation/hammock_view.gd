class_name HammockView
extends Node3D
## Fase 199: a rede na varanda. Nas casas com o alpendre das ilhas tropicais (a varanda da Fase 23 que a Fase 126 pôs nos
## operários e artesãos), uma a cada HAMMOCK_EVERY pelo id, a rede de dormir listrada pendurada entre dois esteios da frente
## num vão que não é o da porta (o do lado dela pelo id), do lado de dentro do guarda-corpo (`hang`, `spot`): os cabos em leque
## do nó no esteio até a ponta do pano, a vara de cada ponta e o pano caindo no meio e subindo nas beiradas (`hammock_mesh`).
## Balança de leve em volta da linha dos nós, cada uma no seu ritmo, no tempo de jogo (`swing`). No lugar do modelo da casa
## (`BuildingView.model_place`); um MultiMesh; nada no save; refeito na obra, na demolição, na subida de classe e ao trocar de
## mundo.

const HAMMOCK_EVERY := 2
## Entre os nós nos dois esteios (a malha estica para o vão de verdade), a altura dos nós acima do assoalho e o cabo de cada
## ponta (na horizontal).
const SPAN_M := 1.7
const ANCHOR_UP_M := 1.5
const ROPE_RUN_M := 0.3
const ROPE_DROP_M := 0.22
## Quanto o meio do pano desce abaixo das pontas, a largura dele, o quanto as beiradas sobem e do esteio até o meio do pano.
const SAG_M := 0.55
const WIDTH_M := 0.86
const CURL_M := 0.12
const BACK_M := 0.52
const SEGMENTS := 10
const SWING_RAD := 0.05
const SWING_S := Vector2(3.0, 4.5)
const STRIPES: Array[Color] = [Color(0.72, 0.17, 0.14), Color(0.93, 0.87, 0.72), Color(0.9, 0.66, 0.17),
		Color(0.18, 0.4, 0.6), Color(0.93, 0.87, 0.72), Color(0.72, 0.17, 0.14)]
const ROPE := Color(0.78, 0.7, 0.52)
const STICK := Color(0.45, 0.32, 0.2)

var _simulation: Simulation
var _hammocks := MultiMeshInstance3D.new()
## O lugar de cada rede (o meio do vão na linha dos esteios, no assoalho, o z para dentro) e a semente do balanço (testes).
var places: Array[Transform3D] = []
var _seeds := PackedInt32Array()
var _time := 0.0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_hammocks.name = "Hammocks"
	_hammocks.multimesh = MultiMesh.new()
	_hammocks.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_hammocks.multimesh.mesh = hammock_mesh()
	_hammocks.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_hammocks.material_override = material
	add_child(_hammocks)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.house_upgraded.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func hammock_count() -> int:
	return places.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()
	advance(delta * GameClock.clock.speed_multiplier())


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
			_seeds.append(FireflyView.cell_hash(world.building(id).island_id, id, 0, 199))
	_hammocks.multimesh.instance_count = places.size()
	advance(0.0)


## Anda o relógio das redes seconds de jogo e põe cada uma no balanço da vez.
func advance(seconds: float) -> void:
	_time += seconds
	for i: int in places.size():
		_hammocks.multimesh.set_instance_transform(i, places[i] * swing(_seeds[i], _time))


## O balanço da rede de semente seed no instante time: um giro pequeno em volta da linha dos nós.
static func swing(seed_value: int, time: float) -> Transform3D:
	var period := lerpf(SWING_S.x, SWING_S.y, float(seed_value % 97) / 96.0)
	var angle := SWING_RAD * sin(TAU * time / period + float(seed_value % 31))
	var pivot := Transform3D(Basis.IDENTITY, Vector3(0.0, ANCHOR_UP_M, 0.1))
	return pivot * Transform3D(Basis(Vector3.RIGHT, angle), Vector3.ZERO) * pivot.affine_inverse()


## O lugar da rede da casa no mundo, ou null.
static func spot(simulation: Simulation, record: BuildingRecord) -> Variant:
	if record == null or not record.is_house() or posmod(record.id, HAMMOCK_EVERY) != 0:
		return null
	var grid := simulation.world.island(record.island_id)
	var spec := BuildingKit.spec_for(simulation, record, grid.cell_size)
	var found: Variant = hang(spec, record.id)
	if found == null:
		return null
	var local: Transform3D = found
	var def := simulation.def_of(record)
	return BuildingView.model_place(grid, record, Footprint.rect(record.origin, def.size, record.rotation)) * local


## A rede na forma spec (no referencial do modelo): o meio do vão escolhido entre dois esteios, na altura do assoalho, na linha
## dos esteios, com o x ao longo da frente (esticado para o vão) e o z para dentro da varanda; null sem a varanda.
static func hang(spec: BuildingKit.Spec, id: int) -> Variant:
	if spec.silhouette != BuildingDef.Silhouette.VERANDA or spec.cells.x < 2:
		return null
	# o vão do lado da porta (um ou outro pelo id), dentro da frente
	var bay := spec.door_index + (1 if posmod(id / HAMMOCK_EVERY, 2) == 0 else -1)
	if bay < 0 or bay >= spec.cells.x:
		bay = spec.door_index - (bay - spec.door_index)
	if bay < 0 or bay >= spec.cells.x or bay == spec.door_index:
		return null
	var posts := post_xs(spec)
	var box := BuildingKit.veranda_box(spec)
	var post_z := box.position.z + BuildingKit.VERANDA_STEP_M + BuildingKit.VERANDA_POST_M * 0.5 + 0.04
	var inner := posts[bay + 1] - posts[bay] - BuildingKit.VERANDA_POST_M
	var middle := Vector3((posts[bay] + posts[bay + 1]) * 0.5, BuildingKit.VERANDA_DECK_M, post_z)
	return Transform3D(Basis.from_scale(Vector3(inner / SPAN_M, 1.0, 1.0)), middle)


## O x de cada esteio da frente da varanda, como a BuildingKit os põe (um em cada divisa de célula, os das pontas para dentro).
static func post_xs(spec: BuildingKit.Spec) -> Array[float]:
	var box := BuildingKit.veranda_box(spec)
	var left := box.position.x
	var right := box.end.x
	var step := (right - left) / spec.cells.x
	var result: Array[float] = []
	for k: int in spec.cells.x + 1:
		result.append(clampf(left + step * k, left + BuildingKit.VERANDA_POST_M * 0.5, right - BuildingKit.VERANDA_POST_M * 0.5))
	return result


## A rede com o meio do vão na origem (no assoalho, na linha dos esteios), o x ao longo dele e o z para dentro: os nós nos
## esteios em ±SPAN_M / 2, os cabos em leque até a vara de cada ponta e o pano listrado no comprido, caindo no meio.
static func hammock_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := SPAN_M * 0.5 - ROPE_RUN_M
	var end_y := ANCHOR_UP_M - ROPE_DROP_M
	var bands := STRIPES.size()
	var grid: Array[PackedVector3Array] = []
	for i: int in SEGMENTS + 1:
		var u := -1.0 + 2.0 * i / SEGMENTS
		var row := PackedVector3Array()
		# junto das varas o pano se fecha; no meio abre a largura toda e as beiradas sobem
		var wide := WIDTH_M * 0.5 * (0.45 + 0.55 * (1.0 - u * u))
		for j: int in bands + 1:
			var v := -1.0 + 2.0 * j / bands
			var y := end_y - SAG_M * (1.0 - u * u) + CURL_M * v * v * (1.0 - u * u)
			row.append(Vector3(u * half, y, BACK_M + v * wide))
		grid.append(row)
	for i: int in SEGMENTS:
		for j: int in bands:
			var a := grid[i][j]
			var b := grid[i + 1][j]
			var c := grid[i + 1][j + 1]
			var d := grid[i][j + 1]
			VertexShapes.quad(tool, a, b, c, d, STRIPES[j])
	for side: float in [-1.0, 1.0]:
		var i := 0 if side < 0.0 else SEGMENTS
		var anchor := Vector3(side * SPAN_M * 0.5, ANCHOR_UP_M, 0.1)
		# a vara de ponta a ponta do pano e os cabos do nó até ela
		VertexShapes.strut(tool, grid[i][0], grid[i][bands], 0.015, 0.015, STICK)
		for j: int in range(0, bands + 1, 2):
			VertexShapes.strut(tool, anchor, grid[i][j], 0.006, 0.006, ROPE)
	tool.generate_normals()
	return tool.commit()
