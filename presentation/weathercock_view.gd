class_name WeathercockView
extends Node3D
## Fase 182: o galo do cata-vento. No alto da cumeeira de cada fazenda de FARMS das ilhas temperadas (`spot`: o meio do telhado
## do corpo, no lugar do modelo), a haste de ferro com a rosa dos ventos (`mast_mesh`) e, em cima dela, a seta com o galo de
## bronze (`cock_mesh`), que vira com a cabeça para o lado de onde vem o vento (o WeatherView) e treme um pouco com as rajadas,
## no tempo de jogo (para na pausa). Dois MultiMesh; nada no save; refeito na obra, na demolição e ao trocar de mundo.

const FARMS: Array[StringName] = [&"wheat_farm", &"potato_farm", &"hop_farm", &"sheep_farm", &"pig_farm", &"vineyard"]
## Quanto tempo (s de jogo) o galo leva para virar para o vento novo, e o tremor com o vento forte.
const TURN_S := 3.0
const SHAKE_RAD := 0.12
const MAST_M := 1.1
const COCK_AT_M := 0.95
const IRON := Color(0.14, 0.14, 0.15)
const BRONZE := Color(0.66, 0.5, 0.22)
const COMB := Color(0.62, 0.16, 0.1)

var _simulation: Simulation
var _weather: WeatherView
var _masts := MultiMeshInstance3D.new()
var _cocks := MultiMeshInstance3D.new()
## O pé de cada haste no alto da cumeeira e para onde o galo está virado (testes: sem tela o MultiMesh devolve zeros).
var spots: Array[Vector3] = []
var heading := 0.0
var _time := 0.0
var _strength := 0.0
var _dirty := true


func setup(simulation: Simulation, weather: WeatherView = null) -> void:
	_simulation = simulation
	_weather = weather
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.45
	material.metallic = 0.5
	# a chapa recortada do galo é vista dos dois lados
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for pair: Array in [[_masts, "WeathercockMasts", mast_mesh()], [_cocks, "Weathercocks", cock_mesh()]]:
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
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func cock_count() -> int:
	return spots.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()
	var step := delta * GameClock.clock.speed_multiplier()
	if step > 0.0 and _weather != null:
		turn(_weather.sample.wind_direction, _weather.sample.wind, step)


## Anda o galo seconds de jogo com o vento dado: a cabeça vira para o lado de onde ele vem.
func turn(direction: Vector2, strength: float, seconds: float) -> void:
	_time += seconds
	_strength = strength
	heading = lerp_angle(heading, WindFlag.yaw_of(direction), clampf(seconds / TURN_S, 0.0, 1.0))
	_place_cocks()


func rebuild() -> void:
	_dirty = false
	spots.clear()
	var world := _simulation.world
	for id: int in world.building_ids():
		var found: Variant = spot(_simulation, world.building(id))
		if found is Vector3:
			spots.append(found)
	_masts.multimesh.instance_count = spots.size()
	_cocks.multimesh.instance_count = spots.size()
	for i: int in spots.size():
		_masts.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, spots[i]))
	_place_cocks()


func _place_cocks() -> void:
	for i: int in spots.size():
		var shake := SHAKE_RAD * smoothstep(0.3, 1.0, _strength) * sin(_time * 2.3 + float(i) * 1.7)
		_cocks.multimesh.set_instance_transform(i, Transform3D(Basis(Vector3.UP, heading + shake), spots[i]))


## O pé da haste no alto da cumeeira da fazenda (mundo) ou null: fazenda de FARMS numa ilha temperada, com telhado.
static func spot(simulation: Simulation, record: BuildingRecord) -> Variant:
	if record == null or record.def_id not in FARMS:
		return null
	if simulation.world.is_tropical(record.island_id, simulation.data):
		return null
	var grid := simulation.world.island(record.island_id)
	var spec := BuildingKit.spec_for(simulation, record, grid.cell_size)
	if spec == null or spec.roof == BuildingKit.Roof.FLAT:
		return null
	var hall := spec.hall()
	var def := simulation.def_of(record)
	var model := BuildingView.model_place(grid, record, Footprint.rect(record.origin, def.size, record.rotation))
	return model * (spec.hall_offset() + Vector3(0.0, hall.height_m + hall.roof_m, 0.0))


## A haste com o pé no zero: a base que abraça a cumeeira, a haste de ferro, a bolinha e a rosa dos ventos (os quatro braços
## com a bola na ponta).
static func mast_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.box(tool, Vector3(0.0, 0.03, 0.0), Vector3(0.09, 0.05, 0.09), IRON)
	VertexShapes.cylinder(tool, Vector3(0.0, 0.0, 0.0), Vector3(0.0, MAST_M, 0.0), 0.018, IRON, 6)
	VertexShapes.box(tool, Vector3(0.0, 0.32, 0.0), Vector3(0.035, 0.035, 0.035), BRONZE)
	for arm: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		VertexShapes.strut(tool, Vector3(0.0, 0.6, 0.0), Vector3(0.0, 0.6, 0.0) + arm * 0.3, 0.008, 0.008, IRON)
		VertexShapes.box(tool, Vector3(0.0, 0.6, 0.0) + arm * 0.32, Vector3(0.025, 0.025, 0.025), BRONZE)
	tool.generate_normals()
	return tool.commit()


## A seta com o galo, no zero da haste e a cabeça para −x (o +x, o rabo largo, vai a favor do vento): a seta de ferro com a
## ponta e a pena, e o galo de bronze recortado (o corpo, o rabo em leque, o pescoço, a cabeça com a crista e o bico, as pernas).
static func cock_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y := COCK_AT_M
	var thick := 0.012
	# a seta: a vareta, a ponta para o vento e a pena atrás
	VertexShapes.strut(tool, Vector3(-0.36, y - 0.1, 0.0), Vector3(0.36, y - 0.1, 0.0), 0.008, 0.008, IRON)
	_plate(tool, [Vector2(-0.44, y - 0.1), Vector2(-0.34, y - 0.05), Vector2(-0.34, y - 0.15)], thick, IRON)
	_plate(tool, [Vector2(0.26, y - 0.1), Vector2(0.4, y - 0.02), Vector2(0.4, y - 0.18)], thick, IRON)
	# o galo: o corpo, o rabo em leque, o pescoço e a cabeça
	_plate(tool, [Vector2(-0.12, y), Vector2(0.12, y), Vector2(0.15, y + 0.1), Vector2(0.0, y + 0.16),
			Vector2(-0.14, y + 0.1)], thick, BRONZE)
	_plate(tool, [Vector2(0.1, y + 0.03), Vector2(0.3, y + 0.32), Vector2(0.22, y + 0.34), Vector2(0.06, y + 0.14)], thick,
			BRONZE)
	_plate(tool, [Vector2(0.08, y + 0.05), Vector2(0.27, y + 0.18), Vector2(0.24, y + 0.24)], thick, BRONZE)
	_plate(tool, [Vector2(-0.14, y + 0.08), Vector2(-0.07, y + 0.14), Vector2(-0.12, y + 0.28), Vector2(-0.19, y + 0.24)],
			thick, BRONZE)
	_plate(tool, [Vector2(-0.17, y + 0.32), Vector2(-0.11, y + 0.27), Vector2(-0.2, y + 0.24)], thick, BRONZE)
	# a crista e o bico
	_plate(tool, [Vector2(-0.18, y + 0.32), Vector2(-0.15, y + 0.37), Vector2(-0.12, y + 0.31)], thick, COMB)
	_plate(tool, [Vector2(-0.2, y + 0.29), Vector2(-0.26, y + 0.27), Vector2(-0.2, y + 0.26)], thick, BRONZE)
	# as pernas até a seta
	for x: float in [-0.04, 0.04]:
		VertexShapes.strut(tool, Vector3(x, y, 0.0), Vector3(x, y - 0.1, 0.0), 0.007, 0.007, BRONZE)
	tool.generate_normals()
	return tool.commit()


## Uma chapa recortada no plano xy (o polígono convexo "points", em leque do primeiro ponto) com a espessura thick em z: as
## duas faces e a borda.
static func _plate(tool: SurfaceTool, points: Array[Vector2], thick: float, color: Color) -> void:
	var front: Array[Vector3] = []
	var back: Array[Vector3] = []
	for point: Vector2 in points:
		front.append(Vector3(point.x, point.y, thick * 0.5))
		back.append(Vector3(point.x, point.y, -thick * 0.5))
	for k: int in range(1, points.size() - 1):
		VertexShapes.tri(tool, front[0], front[k + 1], front[k], color)
		VertexShapes.tri(tool, back[0], back[k], back[k + 1], color)
	for k: int in points.size():
		var next := (k + 1) % points.size()
		VertexShapes.quad(tool, front[k], back[k], back[next], front[next], color)
