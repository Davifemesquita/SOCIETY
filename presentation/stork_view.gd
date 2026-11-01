class_name StorkView
extends Node3D
## Fase 176: a cegonha na chaminé. Numa casa de camponeses ou operários (`TIERS`) a cada STORK_EVERY pelo id, nas ilhas
## temperadas, com chaminé: o ninho de gravetos assentado no capitel, cobrindo os potes (`nest_place`, `nest_mesh`), e a
## cegonha de pé no meio dele (`stork_mesh`), virando para um lado novo de tempos em tempos como as gaivotas do cais (o relógio
## para na pausa). A chaminé com ninho não fumega (`ChimneySmokeView`). No lugar do modelo da casa (`BuildingView.model_place`);
## dois MultiMesh; nada no save; refeito na obra, na demolição, na subida de classe e ao trocar de mundo.

const TIERS: Array[StringName] = [&"peasants", &"workers"]
const STORK_EVERY := 4
const STORK_REST := 3
## O ninho: o raio, a altura acima do capitel e o tom dos gravetos.
const NEST_RADIUS_M := 0.5
const NEST_M := 0.28
const STICKS := 14
const TWIG := Color(0.38, 0.29, 0.2)
const TWIG_DRY := Color(0.55, 0.45, 0.32)
const WHITE := Color(0.95, 0.95, 0.92)
const BLACK := Color(0.08, 0.08, 0.09)
const RED := Color(0.85, 0.25, 0.15)

var _simulation: Simulation
var _nests := MultiMeshInstance3D.new()
var _storks := MultiMeshInstance3D.new()
## O alto de cada ninho (onde a cegonha pisa) e a semente dela (testes: sem tela o MultiMesh devolve zeros).
var spots: Array[Vector3] = []
var headings := PackedFloat32Array()
var _seeds := PackedInt32Array()
var _time := 0.0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	for pair: Array in [[_nests, "StorkNests", nest_mesh()], [_storks, "Storks", stork_mesh()]]:
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
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.house_upgraded.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func stork_count() -> int:
	return spots.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()
	advance(delta * GameClock.clock.speed_multiplier())


func rebuild() -> void:
	_dirty = false
	spots.clear()
	_seeds.clear()
	var nests: Array[Transform3D] = []
	for id: int in _simulation.world.building_ids():
		var found: Variant = nest_place(_simulation, _simulation.world.building(id))
		if found is Transform3D:
			var nest: Transform3D = found
			nests.append(nest)
			spots.append(nest.origin + Vector3(0.0, NEST_M, 0.0))
			_seeds.append(absi(hash([id, &"cegonha"])))
	_nests.multimesh.instance_count = nests.size()
	for i: int in nests.size():
		_nests.multimesh.set_instance_transform(i, nests[i])
	headings.resize(spots.size())
	_storks.multimesh.instance_count = spots.size()
	advance(0.0)


## Anda o relógio das cegonhas seconds de jogo e põe cada uma virada para o lado da vez dela.
func advance(seconds: float) -> void:
	_time += seconds
	for i: int in spots.size():
		headings[i] = PerchedGullView.heading_at(_seeds[i], _time)
		_storks.multimesh.set_instance_transform(i, Transform3D(Basis(Vector3.UP, headings[i]), spots[i]))


## Se a casa tem o ninho: camponeses ou operários do resto certo, numa ilha temperada.
static func has_nest(simulation: Simulation, record: BuildingRecord) -> bool:
	if record == null or not record.is_house() or posmod(record.id, STORK_EVERY) != STORK_REST:
		return false
	if record.tier not in TIERS:
		return false
	return not simulation.world.is_tropical(record.island_id, simulation.data)


## O pé do ninho no mundo (o alto do capitel da chaminé, no lugar do modelo) ou null: casa sem ninho ou sem chaminé.
static func nest_place(simulation: Simulation, record: BuildingRecord) -> Variant:
	if not has_nest(simulation, record):
		return null
	var grid := simulation.world.island(record.island_id)
	var spec := BuildingKit.spec_for(simulation, record, grid.cell_size)
	var top: Variant = BuildingKit.chimney_top(spec)
	if top == null:
		return null
	var mouth: Vector3 = top
	var def := simulation.def_of(record)
	var model := BuildingView.model_place(grid, record, Footprint.rect(record.origin, def.size, record.rotation))
	# o capitel fica embaixo dos potes; o ninho cobre os dois
	var turn := float(posmod(record.id * 53, 360)) * PI / 180.0
	return model * Transform3D(Basis(Vector3.UP, turn), mouth - Vector3(0.0, BuildingKit.CHIMNEY_POT_M, 0.0))


## O ninho com o pé no zero: o monte de gravetos mais largo em cima, o miolo afundado e os gravetos soltos saindo da borda.
static func nest_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.cylinder(tool, Vector3(0.0, -0.04, 0.0), Vector3(0.0, NEST_M * 0.55, 0.0), NEST_RADIUS_M * 0.82, TWIG, 9)
	VertexShapes.cylinder(tool, Vector3(0.0, NEST_M * 0.5, 0.0), Vector3(0.0, NEST_M, 0.0), NEST_RADIUS_M, TWIG_DRY, 9)
	VertexShapes.cylinder(tool, Vector3(0.0, NEST_M, 0.0), Vector3(0.0, NEST_M + 0.01, 0.0), NEST_RADIUS_M * 0.7, TWIG, 9)
	var random := RandomNumberGenerator.new()
	random.seed = 176
	for k: int in STICKS:
		var angle := TAU * k / STICKS + random.randf_range(-0.2, 0.2)
		var out := Vector3(cos(angle), 0.0, -sin(angle))
		var height := random.randf_range(0.05, NEST_M * 0.95)
		var inner := out * NEST_RADIUS_M * 0.6 + Vector3(0.0, height, 0.0)
		var outer := out * random.randf_range(NEST_RADIUS_M + 0.08, NEST_RADIUS_M + 0.22) \
				+ Vector3(random.randf_range(-0.12, 0.12), height + random.randf_range(-0.1, 0.06), 0.0)
		VertexShapes.strut(tool, inner, outer, 0.012, 0.012, TWIG_DRY if k % 2 == 0 else TWIG)
	tool.generate_normals()
	return tool.commit()


## A cegonha de pé, de frente para −Z, com o pé em y = 0 (cerca de 1 m de alto): o corpo branco, as asas dobradas brancas na
## frente e pretas atrás, o pescoço e a cabeça brancos, o bico comprido e as pernas vermelhas.
static func stork_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.13, 0.13, 0.27)), Vector3(0.0, 0.6, 0.04)), WHITE)
	for side: float in [-1.0, 1.0]:
		PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.07, 0.1, 0.15)), Vector3(side * 0.09, 0.64, -0.02)),
				WHITE)
		PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.065, 0.085, 0.2)), Vector3(side * 0.085, 0.63, 0.17)),
				BLACK)
		VertexShapes.strut(tool, Vector3(side * 0.05, 0.5, 0.05), Vector3(side * 0.06, 0.0, 0.03), 0.013, 0.013, RED)
		VertexShapes.box(tool, Vector3(side * 0.06, 0.006, -0.02), Vector3(0.025, 0.006, 0.05), RED)
	# o pescoço, a cabeça e o bico
	VertexShapes.strut(tool, Vector3(0.0, 0.66, -0.17), Vector3(0.0, 0.88, -0.23), 0.04, 0.035, WHITE)
	var head := Vector3(0.0, 0.92, -0.25)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.05, 0.05, 0.07)), head), WHITE)
	VertexShapes.strut(tool, head + Vector3(0.0, -0.01, -0.05), head + Vector3(0.0, -0.06, -0.26), 0.014, 0.018, RED)
	tool.generate_normals()
	return tool.commit()
