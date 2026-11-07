class_name CrowView
extends Node3D
## Fase 270: os corvos no campo. Nos campos com dono que a CropView desenha, um a cada CROW_EVERY pelo id, enquanto a plantação
## ainda é nova (crescimento até YOUNG_UNTIL), um corvo em parte dos vãos entre as fileiras (os lugares da colheita da Fase 157,
## `CropView.harvest_places`, que só aparecem perto da colheita: quando os caixotes chegam, os corvos já foram) (`crow_spots`),
## virando de tempos em tempos (`PerchedGullView.heading_at`) e bicando a terra em rajadas (`peck`), no tempo de jogo; somem à
## noite. `crow_mesh`: o corpo preto, a cabeça com o bico cinza e as patas. Um MultiMesh sem sombra; nada no save; conferido a
## cada REFRESH_S.

const CROW_EVERY := 2
## Dos lugares de cada campo, os que levam corvo: o resto CROW_REST de CROW_SPOT_EVERY pela posição na lista.
const CROW_SPOT_EVERY := 2
const YOUNG_UNTIL := 0.45
const REFRESH_S := 0.5
## A partir de quanto da noite os corvos vão embora.
const NIGHT_HIDE := 0.5
## O bico: quanto o corvo inclina, de quanto em quanto tempo vem a rajada, quanto ela dura e a frequência das bicadas.
const PECK_TILT := 0.6
const PECK_CYCLE_S := 3.2
const PECK_BURST_S := 1.1
const PECK_HZ := 2.4
const SALT := 270
const BLACK := Color(0.07, 0.07, 0.08)
const SHEEN := Color(0.12, 0.13, 0.17)
const BEAK := Color(0.24, 0.23, 0.22)
const LEGS := Color(0.15, 0.14, 0.13)

var _crops: CropView
var _config: GameConfig
var _crows := MultiMeshInstance3D.new()
## O pé de cada corvo e a semente dele (testes: sem tela o MultiMesh devolve zeros).
var spots: Array[Vector3] = []
var _seeds := PackedInt32Array()
var _time := 0.0
var _since := REFRESH_S


func setup(crops: CropView, config: GameConfig) -> void:
	_crops = crops
	_config = config
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.6
	_crows.name = "Crows"
	_crows.multimesh = MultiMesh.new()
	_crows.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_crows.multimesh.mesh = crow_mesh()
	_crows.multimesh.custom_aabb = WorldBounds.of(config)
	_crows.material_override = material
	_crows.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_crows)
	refresh()


func crow_count() -> int:
	return spots.size()


func _process(delta: float) -> void:
	var clock := GameClock.clock
	_crows.visible = DayClock.night_factor(_config, clock.hour()) < NIGHT_HIDE
	_since += delta
	if _since >= REFRESH_S:
		_since = 0.0
		refresh()
	advance(delta * clock.speed_multiplier())


## Refaz a lista dos corvos pelos campos novos da CropView.
func refresh() -> void:
	if _crops == null:
		return
	spots.clear()
	_seeds.clear()
	for field_id: int in _crops.field_ids():
		for spot: Vector3 in crow_spots(field_id, _crops.growth_of(field_id), _crops.harvest_places(field_id)):
			spots.append(spot)
			_seeds.append(absi(hash(Vector3i(roundi(spot.x * 10.0), roundi(spot.z * 10.0), SALT))))
	_crows.multimesh.instance_count = spots.size()
	advance(0.0)


## Os pés dos corvos de um campo: nenhum se o campo não é da vez ou a plantação já passou de YOUNG_UNTIL; senão um em cada
## CROW_SPOT_EVERY lugares da colheita (os vãos entre as fileiras).
static func crow_spots(field_id: int, growth: float, places: Array[Transform3D]) -> Array[Vector3]:
	var result: Array[Vector3] = []
	if posmod(field_id, CROW_EVERY) != 0 or growth < 0.0 or growth > YOUNG_UNTIL:
		return result
	for k: int in places.size():
		if posmod(k + field_id, CROW_SPOT_EVERY) == 0:
			result.append(places[k].origin)
	return result


## Anda o relógio dos corvos seconds de jogo: cada um virado para o lado da vez dele e bicando em rajadas.
func advance(seconds: float) -> void:
	_time += seconds
	for i: int in spots.size():
		var heading := PerchedGullView.heading_at(_seeds[i], _time)
		var basis := Basis(Vector3.UP, heading) * Basis(Vector3.RIGHT, -peck(_seeds[i], _time))
		_crows.multimesh.set_instance_transform(i, Transform3D(basis, spots[i]))


## Quanto o corvo da semente seed inclina para a frente no instante time: nada fora da rajada, as bicadas dentro dela.
static func peck(seed: int, time: float) -> float:
	var into := fposmod(time + float(seed % 97) * 0.13, PECK_CYCLE_S)
	if into >= PECK_BURST_S:
		return 0.0
	return maxf(sin(into * TAU * PECK_HZ), 0.0) * PECK_TILT


## O corvo de pé, de frente para −Z, com o pé em y = 0 (cerca de 45 cm de comprimento): o corpo preto com o brilho azulado nas
## asas dobradas, a cauda em leque, a cabeça, o bico grosso e as patas.
static func crow_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ball := CropView._sphere(1.0)
	RoofPigeonView._ball(tool, ball, Transform3D(Basis(Vector3.RIGHT, -0.25).scaled(Vector3(0.08, 0.08, 0.16)),
			Vector3(0.0, 0.16, 0.02)), BLACK)
	for side: float in [-1.0, 1.0]:
		RoofPigeonView._ball(tool, ball, Transform3D(Basis(Vector3.RIGHT, -0.2).scaled(Vector3(0.03, 0.06, 0.15)),
				Vector3(side * 0.06, 0.18, 0.05)), SHEEN)
		VertexShapes.strut(tool, Vector3(side * 0.03, 0.0, 0.0), Vector3(side * 0.03, 0.09, 0.0), 0.007, 0.007, LEGS)
		VertexShapes.box(tool, Vector3(side * 0.03, 0.004, -0.02), Vector3(0.012, 0.004, 0.035), LEGS)
	RoofPigeonView._ball(tool, ball, Transform3D(Basis.from_scale(Vector3(0.05, 0.05, 0.055)), Vector3(0.0, 0.25, -0.12)), BLACK)
	# o bico grosso para a frente
	VertexShapes.strut(tool, Vector3(0.0, 0.25, -0.16), Vector3(0.0, 0.235, -0.23), 0.016, 0.004, BEAK)
	# a cauda em leque, chata, para trás e um pouco para baixo
	VertexShapes.tri(tool, Vector3(-0.02, 0.15, 0.15), Vector3(0.02, 0.15, 0.15), Vector3(0.0, 0.11, 0.3), BLACK)
	VertexShapes.tri(tool, Vector3(0.02, 0.15, 0.15), Vector3(-0.02, 0.15, 0.15), Vector3(0.0, 0.11, 0.3), BLACK)
	VertexShapes.tri(tool, Vector3(-0.05, 0.12, 0.29), Vector3(0.05, 0.12, 0.29), Vector3(0.0, 0.15, 0.15), BLACK)
	VertexShapes.tri(tool, Vector3(0.05, 0.12, 0.29), Vector3(-0.05, 0.12, 0.29), Vector3(0.0, 0.15, 0.15), BLACK)
	tool.generate_normals()
	return tool.commit()
