class_name PerchedGullView
extends Node3D
## Fase 168: gaivotas pousadas no cais. Em parte dos cabeços dos píeres, do cais de tábuas e do cais de pedra (os que a
## HarborView desenhou: `HarborView.bollard_places`), um a cada PERCH_EVERY pela posição, uma gaivota de pé no alto do cabeço,
## virando para um lado novo de tempos em tempos (cada uma no seu ritmo, pelo tempo de jogo: para na pausa). Corpo branco, as
## asas dobradas cinza com a ponta preta, a cabeça branca com o bico amarelo e as patas (`gull_mesh`). Um MultiMesh; nada no
## save; refeito quando a HarborView refaz o desenho.

const PERCH_EVERY := 3
## Quanto tempo (s de jogo) cada gaivota fica olhando para um lado, e a altura do alto do cabeço acima do meio dele.
const TURN_EVERY_S := Vector2(4.0, 11.0)
const BOLLARD_TOP_M := HarborView.BOLLARD_HEIGHT_M * 0.5
const WHITE := Color(0.95, 0.95, 0.93)
const GREY := Color(0.62, 0.65, 0.7)
const BLACK := Color(0.1, 0.1, 0.11)
const BEAK := Color(0.92, 0.75, 0.2)
const LEGS := Color(0.85, 0.6, 0.35)

var _harbor: HarborView
var _gulls := MultiMeshInstance3D.new()
## Onde cada gaivota está (o alto do cabeço) e a semente dela; as viradas da vez (testes: sem tela o MultiMesh devolve zeros).
var spots: Array[Vector3] = []
var headings: PackedFloat32Array = PackedFloat32Array()
var _seeds: PackedInt32Array = PackedInt32Array()
var _time := 0.0
var _dirty := true


func setup(harbor: HarborView, config: GameConfig) -> void:
	_harbor = harbor
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.8
	_gulls.name = "PerchedGulls"
	_gulls.multimesh = MultiMesh.new()
	_gulls.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_gulls.multimesh.mesh = gull_mesh()
	_gulls.multimesh.custom_aabb = WorldBounds.of(config)
	_gulls.material_override = material
	_gulls.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_gulls)
	harbor.rebuilt.connect(func() -> void: _dirty = true)


func gull_count() -> int:
	return spots.size()


func _process(delta: float) -> void:
	if _dirty and _harbor != null:
		rebuild()
	advance(delta * GameClock.clock.speed_multiplier())


func rebuild() -> void:
	_dirty = false
	spots.clear()
	_seeds.clear()
	for bollard: Transform3D in _harbor.bollard_places:
		var at := bollard.origin
		var seed := absi(hash(Vector2i(roundi(at.x * 10.0), roundi(at.z * 10.0))))
		if seed % PERCH_EVERY != 0:
			continue
		spots.append(at + Vector3(0.0, BOLLARD_TOP_M, 0.0))
		_seeds.append(seed)
	headings.resize(spots.size())
	_gulls.multimesh.instance_count = spots.size()
	advance(0.0)


## Anda o relógio das gaivotas seconds de jogo e põe cada uma virada para o lado da vez dela.
func advance(seconds: float) -> void:
	_time += seconds
	for i: int in spots.size():
		headings[i] = heading_at(_seeds[i], _time)
		_gulls.multimesh.set_instance_transform(i, Transform3D(Basis(Vector3.UP, headings[i]), spots[i]))


## Para que lado a gaivota da semente seed olha no instante time: um lado sorteado por volta, cada volta com a duração dela.
static func heading_at(seed: int, time: float) -> float:
	var span := lerpf(TURN_EVERY_S.x, TURN_EVERY_S.y, float(seed % 97) / 96.0)
	var turn := floori(time / span + float(seed % 13) / 13.0)
	return float(absi(hash([seed, turn])) % 628) / 100.0


## A gaivota de pé, de frente para −Z, com o pé em y = 0 (cerca de 40 cm de comprimento): o corpo branco, as asas dobradas cinza
## por cima até a ponta preta que passa da cauda, a cabeça com o bico amarelo e as duas patas.
static func gull_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hip := 0.12
	_blob(tool, Transform3D(Basis.from_scale(Vector3(0.09, 0.085, 0.17)), Vector3(0.0, hip + 0.05, 0.02)), WHITE)
	# as asas dobradas, um pouco mais largas que o corpo no alto, e a ponta preta saindo atrás
	for side: float in [-1.0, 1.0]:
		_blob(tool, Transform3D(Basis.from_scale(Vector3(0.045, 0.05, 0.16)), Vector3(side * 0.06, hip + 0.09, 0.05)), GREY)
		VertexShapes.tri(tool, Vector3(side * 0.05, hip + 0.1, 0.16), Vector3(side * 0.02, hip + 0.09, 0.27),
				Vector3(side * 0.06, hip + 0.06, 0.15), BLACK)
	# a cabeça e o bico
	var head := Vector3(0.0, hip + 0.17, -0.13)
	_blob(tool, Transform3D(Basis.from_scale(Vector3(0.05, 0.05, 0.06)), head), WHITE)
	VertexShapes.strut(tool, head + Vector3(0.0, -0.01, -0.045), head + Vector3(0.0, -0.02, -0.11), 0.01, 0.012, BEAK)
	# as patas
	for side: float in [-1.0, 1.0]:
		VertexShapes.strut(tool, Vector3(side * 0.03, hip + 0.01, 0.02), Vector3(side * 0.035, 0.0, 0.0), 0.008, 0.008, LEGS)
		VertexShapes.box(tool, Vector3(side * 0.035, 0.005, -0.02), Vector3(0.02, 0.005, 0.03), LEGS)
	tool.generate_normals()
	return tool.commit()


## Uma bolinha (a esfera baixa do CropView, sem normal: o generate_normals faz junto com as caixas) no referencial place.
static func _blob(tool: SurfaceTool, place: Transform3D, color: Color) -> void:
	var arrays := CropView._sphere(1.0).get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for index: int in indices:
		tool.set_color(color)
		tool.add_vertex(place * vertices[index])
