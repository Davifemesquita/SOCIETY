class_name BuoyView
extends Node3D
## Fase 144: as boias do porto. Diante de cada entreposto, do lado do mar, até BUOYS_PER_POST boias em pares marcando a
## entrada (`spots`: a OUT_M da beira dele e SIDE_M para cada lado, só onde boiam pelo `HarborView.afloat`): a vermelha
## à esquerda de quem chega e a verde à direita (`buoy_mesh`: o casco em barril com as faixas, a tampa em cone, a haste e
## a bola no alto). Balançam com as ondas (`pose`, no tempo de jogo: param na pausa). Dois MultiMesh com a caixa fixa do
## arquipélago; nada no save; refeito na obra, na demolição e ao trocar de mundo.

const BUOYS_PER_POST := 4
## Os pontos: [distância da beira do entreposto mar adentro, deslocamento para o lado], além do cais de pedra (que avança
## até ~15 m) e da roda dos botes da Fase 142.
const SPOTS: Array[Vector2] = [Vector2(32.0, -10.0), Vector2(32.0, 10.0), Vector2(46.0, -14.0), Vector2(46.0, 14.0)]
const RADIUS_M := 0.36
const BODY_M := 0.75
const CONE_M := 0.35
const POLE_M := 0.9
## Quanto a boia afunda, sobe e desce e tomba nas ondas.
const DRAFT_M := 0.3
const BOB_M := 0.08
const ROCK := 0.14
const RED := Color(0.72, 0.12, 0.1)
const GREEN := Color(0.12, 0.42, 0.22)
const WHITE := Color(0.9, 0.88, 0.84)
const IRON := Color(0.15, 0.15, 0.16)

var _simulation: Simulation
var _red := MultiMeshInstance3D.new()
var _green := MultiMeshInstance3D.new()
## Por boia: [ponto na água, vermelha (true) ou verde, semente].
var _buoys: Array[Array] = []
var _time: float = 0.0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.6
	for part: Array in [[_red, "RedBuoys", RED], [_green, "GreenBuoys", GREEN]]:
		var layer: MultiMeshInstance3D = part[0]
		layer.name = part[1]
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		var color: Color = part[2]
		layer.multimesh.mesh = buoy_mesh(color)
		layer.material_override = material
		add_child(layer)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func buoy_count() -> int:
	return _buoys.size()


## Anda o relógio das boias à mão (testes e capturas com o jogo pausado).
func advance(seconds: float) -> void:
	_time += seconds
	_bob()


func _mark(_id: int) -> void:
	_dirty = true


func _process(delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()
	var step := delta * GameClock.clock.speed_multiplier()
	if step > 0.0:
		advance(step)


func rebuild() -> void:
	_dirty = false
	_buoys.clear()
	var world := _simulation.world
	for id: int in world.building_ids():
		var record := world.building(id)
		var def := _simulation.def_of(record)
		if not def.is_trading_post:
			continue
		for spot: Array in spots(world, record, def, _simulation.config.cell_size_m):
			_buoys.append([spot[0], spot[1], id * BUOYS_PER_POST + _buoys.size()])
	var reds := _buoys.filter(func(buoy: Array) -> bool:
		var is_red: bool = buoy[1]
		return is_red)
	_red.multimesh.instance_count = reds.size()
	_green.multimesh.instance_count = _buoys.size() - reds.size()
	for layer: MultiMeshInstance3D in [_red, _green]:
		layer.multimesh.custom_aabb = WorldBounds.of(_simulation.config)
	_bob()


func _bob() -> void:
	var red := 0
	var green := 0
	for buoy: Array in _buoys:
		var at: Vector3 = buoy[0]
		var seed_value: int = buoy[2]
		var place := pose(at, seed_value, _time)
		var is_red: bool = buoy[1]
		if is_red:
			_red.multimesh.set_instance_transform(red, place)
			red += 1
		else:
			_green.multimesh.set_instance_transform(green, place)
			green += 1


## As boias do entreposto: [[ponto na água (altura zero), vermelha], ...], só os pontos de SPOTS que boiam. Quem chega do
## mar vem com a proa para −out: a esquerda dele é o +través (out × UP, a vermelha) e a direita o −través (a verde).
static func spots(world: WorldState, record: BuildingRecord, def: BuildingDef, cell_size: float) -> Array[Array]:
	var result: Array[Array] = []
	var grid := world.island(record.island_id)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var center := grid.rect_world(area)
	var out := HarborView.seaward(world, center, area, cell_size, record.rotation)
	var across := Vector3(-out.z, 0.0, out.x)
	var reach := (area.size.x if out.x != 0.0 else area.size.y) * cell_size * 0.5
	for spot: Vector2 in SPOTS:
		var at := center + out * (reach + spot.x) + across * spot.y
		at.y = 0.0
		if HarborView.afloat(world, at):
			result.append([at, spot.y > 0.0])
		if result.size() >= BUOYS_PER_POST:
			break
	return result


## A boia no instante time: subindo e descendo e tombando um pouco com as ondas, afundada DRAFT_M.
static func pose(at: Vector3, seed_value: int, time: float) -> Transform3D:
	var phase := float(seed_value) * 1.37
	var lift := sin(time * 1.4 + phase) * BOB_M - DRAFT_M
	var tilt := Basis(Vector3.RIGHT, sin(time * 1.1 + phase) * ROCK) * Basis(Vector3.BACK, sin(time * 0.8 + phase * 1.7) * ROCK)
	return Transform3D(Basis(Vector3.UP, phase) * tilt, at + Vector3(0.0, lift, 0.0))


## A boia com o fundo no zero: o casco em barril com três faixas (a cor dela, o branco e a cor), a tampa em cone, a haste
## de ferro e a bola no alto, na cor dela.
static func buoy_mesh(color: Color) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var band := BODY_M / 3.0
	for k: int in 3:
		var radius := RADIUS_M * (0.85 if k == 0 else 1.0)
		VertexShapes.cylinder(tool, Vector3(0.0, band * k, 0.0), Vector3(0.0, band * (k + 1), 0.0), radius,
				WHITE if k == 1 else color, 12)
	var top := Vector3(0.0, BODY_M + CONE_M, 0.0)
	for k: int in 12:
		var a0 := TAU * k / 12.0
		var a1 := TAU * (k + 1) / 12.0
		VertexShapes.tri(tool, Vector3(cos(a0), 0.0, sin(a0)) * RADIUS_M + Vector3(0.0, BODY_M, 0.0),
				Vector3(cos(a1), 0.0, sin(a1)) * RADIUS_M + Vector3(0.0, BODY_M, 0.0), top, color)
	VertexShapes.cylinder(tool, top - Vector3(0.0, 0.05, 0.0), top + Vector3(0.0, POLE_M, 0.0), 0.025, IRON, 6)
	VertexShapes.box(tool, top + Vector3(0.0, POLE_M + 0.08, 0.0), Vector3(0.1, 0.1, 0.1), color)
	tool.generate_normals()
	return tool.commit()
