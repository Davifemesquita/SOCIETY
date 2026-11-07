class_name HeronView
extends Node3D
## Fase 265: as garças no rio. Pela busca das margens das canoas da Fase 254 (`CanoeView.river_banks`, numa rede de HERON_STEP
## células e com a chance HERON_CHANCE, longe das vilas pela regra das focas), fora das margens que têm canoa: uma garça-real de pé
## na água rasa junto da terra (`spot`), de frente para o rio e virando de tempos em tempos para um lado e para o outro
## (`PerchedGullView.heading_at`), com o corpo cinza-azulado, o pescoço em S, o penacho preto e o bico amarelo (`heron_mesh`). Um
## MultiMesh sem sombra; nada no save; refeito na obra, na demolição, na estrada, na derrubada de árvores e ao trocar de mundo.

const HERON_STEP := 9
const HERON_CHANCE := 0.75
const SALT := 265
## Quanto a garça sai do meio da célula da margem para o rio (fração da célula), o quanto a água pode cobrir as patas no máximo e
## quanto ela vira para cada lado de frente para o rio.
const INTO_RIVER := 0.62
const WADE_M := 0.2
const SWING := 0.9
const GREY := Color(0.56, 0.6, 0.66)
const PALE := Color(0.86, 0.87, 0.86)
const DARK := Color(0.12, 0.12, 0.14)
const BILL := Color(0.86, 0.7, 0.22)
const LEG := Color(0.42, 0.36, 0.26)

var _simulation: Simulation
var _herons := MultiMeshInstance3D.new()
## O pé de cada garça, o lado do rio (ângulo em y) e a semente dela (testes: sem tela o MultiMesh devolve zeros).
var spots: Array[Vector3] = []
var faces := PackedFloat32Array()
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
	_herons.name = "Herons"
	_herons.multimesh = MultiMesh.new()
	_herons.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_herons.multimesh.mesh = heron_mesh()
	_herons.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_herons.material_override = material
	_herons.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_herons)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.trees_changed.connect(_mark_trees)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func heron_count() -> int:
	return spots.size()


func _mark(_id: int) -> void:
	_dirty = true


func _mark_trees(_island_id: int, _area: Rect2i) -> void:
	_dirty = true


func _process(delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()
	advance(delta * GameClock.clock.speed_multiplier())


func rebuild() -> void:
	_dirty = false
	spots.clear()
	faces.clear()
	_seeds.clear()
	var world := _simulation.world
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		var canoes: Dictionary[Vector2i, bool] = {}
		for bank: Array in CanoeView.banks(world, _simulation.data, island_id):
			canoes[bank[0]] = true
		for bank: Array in CanoeView.river_banks(world, island_id, HERON_STEP, SALT, HERON_CHANCE):
			var cell: Vector2i = bank[0]
			if canoes.has(cell):
				continue
			var river: Vector2i = bank[1]
			spots.append(spot(grid, cell, river))
			# a frente da garça (−z) para o rio
			faces.append(atan2(-float(river.x), -float(river.y)))
			_seeds.append(FireflyView.cell_hash(island_id, cell.x, cell.y, SALT))
	headings.resize(spots.size())
	_herons.multimesh.instance_count = spots.size()
	advance(0.0)


## Anda o relógio das garças seconds de jogo e põe cada uma de frente para o rio, virada para o lado da vez dela.
func advance(seconds: float) -> void:
	_time += seconds
	for i: int in spots.size():
		headings[i] = faces[i] + (PerchedGullView.heading_at(_seeds[i], _time) / TAU - 0.5) * 2.0 * SWING
		_herons.multimesh.set_instance_transform(i, Transform3D(Basis(Vector3.UP, headings[i]), spots[i]))


## O pé da garça: do meio da célula da margem para o rio, na água rasa (no fundo, mas no máximo WADE_M abaixo da água).
static func spot(grid: IslandGrid, cell: Vector2i, river: Vector2i) -> Vector3:
	var middle := grid.cell_world(cell)
	var at := middle + Vector3(river.x, 0.0, river.y) * grid.cell_size * INTO_RIVER
	at.y = maxf(grid.height_at(at.x, at.z), -WADE_M)
	return at


## A garça-real de pé, de frente para −Z, com o pé em y = 0 (cerca de 90 cm de altura): as patas compridas, o corpo cinza-azulado
## inclinado, a asa dobrada mais escura, o pescoço claro em S, a cabeça com o penacho preto e o bico amarelo comprido.
static func heron_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: float in [-1.0, 1.0]:
		VertexShapes.strut(tool, Vector3(side * 0.035, 0.0, 0.0), Vector3(side * 0.04, 0.46, 0.02), 0.01, 0.01, LEG)
		VertexShapes.box(tool, Vector3(side * 0.035, 0.005, -0.04), Vector3(0.02, 0.005, 0.07), LEG)
		PerchedGullView._blob(tool, Transform3D(Basis(Vector3.RIGHT, -0.25).scaled(Vector3(0.06, 0.08, 0.2)),
				Vector3(side * 0.06, 0.6, 0.05)), GREY.darkened(0.25))
	# o corpo inclinado, mais baixo atrás, e a cauda curta
	PerchedGullView._blob(tool, Transform3D(Basis(Vector3.RIGHT, -0.3).scaled(Vector3(0.1, 0.11, 0.24)), Vector3(0.0, 0.58, 0.02)),
			GREY)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.06, 0.04, 0.08)), Vector3(0.0, 0.52, 0.22)), GREY.darkened(0.3))
	# o pescoço em S: sobe para a frente, recua e volta
	var base := Vector3(0.0, 0.64, -0.16)
	var middle := Vector3(0.0, 0.77, -0.13)
	var top := Vector3(0.0, 0.88, -0.2)
	VertexShapes.strut(tool, base, middle, 0.045, 0.035, PALE)
	VertexShapes.strut(tool, middle, top, 0.035, 0.03, PALE)
	# a lista preta da frente do pescoço
	VertexShapes.strut(tool, base + Vector3(0.0, 0.01, -0.03), middle + Vector3(0.0, 0.0, -0.025), 0.012, 0.01, DARK)
	var head := top + Vector3(0.0, 0.02, -0.02)
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.04, 0.04, 0.06)), head), PALE)
	# o penacho preto para trás e o bico amarelo, comprido e afiado
	VertexShapes.strut(tool, head + Vector3(0.0, 0.02, 0.02), head + Vector3(0.0, 0.0, 0.13), 0.012, 0.004, DARK)
	VertexShapes.strut(tool, head + Vector3(0.0, -0.005, -0.04), head + Vector3(0.0, -0.03, -0.2), 0.013, 0.003, BILL)
	tool.generate_normals()
	return tool.commit()
