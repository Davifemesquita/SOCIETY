class_name WindpumpView
extends Node3D
## Fase 149: o cata-vento do pasto. Junto do cocho de cada pasto (Fase 118), do lado do meio da cerca de trás (`spot`), uma
## torre de quatro pés de madeira travados em xis com a plataforma no alto e o cano descendo até o cocho (`tower_mesh`); em
## cima, a roda de lâminas e o leme (`rotor_mesh`), que viram de frente para o vento e giram mais depressa quanto mais forte
## ele sopra (`rotor_pose`), pelo vento do `WeatherView` no tempo de jogo (param na pausa). A torre é um MultiMesh parado;
## a roda, um MultiMesh refeito a cada quadro. Só a ilha com relevo (o cocho é dela); nada no save; refeito na obra, na
## demolição e ao trocar de mundo.

const TOWER_M := 5.0
const FOOT_M := 0.75
const TOP_M := 0.22
const WHEEL_M := 1.1
const BLADES := 12
const TAIL_M := 1.5
## Giro da roda (rad/s): parada com o ar parado, até SPIN_MAX com o vento cheio; a roda vira para o vento em TURN_S.
const SPIN_MAX := 6.0
const CALM := 0.08
const TURN_S := 3.0
## O cata-vento fica ao lado do cocho, para o meio da cerca, a esta distância do meio do cocho.
const BESIDE_M := 1.7
const WOOD := Color(0.5, 0.42, 0.32)
const IRON := Color(0.36, 0.36, 0.37)
const VANE := Color(0.62, 0.14, 0.1)

var _simulation: Simulation
var _weather: WeatherView
var _towers := MultiMeshInstance3D.new()
var _rotors := MultiMeshInstance3D.new()
var _spots: Array[Vector3] = []
var _yaw := 0.0
var _turn := 0.0
var _dirty := true


func setup(simulation: Simulation, weather: WeatherView = null) -> void:
	_simulation = simulation
	_weather = weather
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.8
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for part: Array in [[_towers, "WindpumpTowers", tower_mesh()], [_rotors, "WindpumpRotors", rotor_mesh()]]:
		var layer: MultiMeshInstance3D = part[0]
		layer.name = part[1]
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.mesh = part[2]
		layer.material_override = material
		add_child(layer)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func pump_count() -> int:
	return _spots.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()
	var step := delta * GameClock.clock.speed_multiplier()
	if step > 0.0 and _weather != null:
		turn(_weather.sample.wind_direction, _weather.sample.wind, step)


## Anda a roda seconds de jogo com o vento dado: vira para ele e gira pela força.
func turn(direction: Vector2, strength: float, seconds: float) -> void:
	var facing := WindFlag.yaw_of(direction) + PI * 0.5
	_yaw = lerp_angle(_yaw, facing, clampf(seconds / TURN_S, 0.0, 1.0))
	_turn += spin_of(strength) * seconds
	_place_rotors()


func rebuild() -> void:
	_dirty = false
	_spots.clear()
	var world := _simulation.world
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.def_id != &"pasture":
			continue
		var grid := world.island(record.island_id)
		if grid == null or grid.flat:
			continue
		_spots.append(spot(grid, record, _simulation.data.building(record.def_id)))
	_towers.multimesh.instance_count = _spots.size()
	_rotors.multimesh.instance_count = _spots.size()
	for layer: MultiMeshInstance3D in [_towers, _rotors]:
		layer.multimesh.custom_aabb = WorldBounds.of(_simulation.config)
	for i: int in _spots.size():
		_towers.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, _spots[i]))
	_place_rotors()


func _place_rotors() -> void:
	for i: int in _spots.size():
		_rotors.multimesh.set_instance_transform(i, rotor_pose(_spots[i], _yaw, _turn + float(i) * 0.7))


## O giro da roda (rad/s) com o vento de força strength (0 a 1): nada abaixo de CALM.
static func spin_of(strength: float) -> float:
	return SPIN_MAX * smoothstep(CALM, 1.0, strength)


## O pé do cata-vento do pasto (mundo): ao lado do cocho, BESIDE_M para o meio da cerca de trás, no chão.
static func spot(grid: IslandGrid, record: BuildingRecord, def: BuildingDef) -> Vector3:
	var trough := RoadMask.trough_of(record, def, grid.cell_size)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var middle := (Vector2(area.position) + Vector2(area.size) * 0.5) * grid.cell_size
	var along := trough[1]
	var inward := -along if (trough[0] - middle).dot(along) > 0.0 else along
	var at := trough[0] + inward * BESIDE_M
	var x := grid.origin_m.x + at.x
	var z := grid.origin_m.y + at.y
	return Vector3(x, grid.height_at(x, z), z)


## A roda no alto da torre do pé foot: virada para yaw (a roda de frente para o vento, o leme atrás) e girada spin em volta
## do eixo dela.
static func rotor_pose(foot: Vector3, yaw: float, spin: float) -> Transform3D:
	var hub := foot + Vector3(0.0, TOWER_M + 0.35, 0.0)
	return Transform3D(Basis(Vector3.UP, yaw), hub) * Transform3D(Basis(Vector3.BACK, spin), Vector3.ZERO)


## A torre com o pé no zero: quatro pés de madeira afinando para o alto, travessas e xis em três lanços, a plataforma no
## alto e o cano descendo pelo meio até perto do chão.
static func tower_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners: Array[Vector2] = [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	var foot: Array[Vector3] = []
	var head: Array[Vector3] = []
	for c: Vector2 in corners:
		foot.append(Vector3(c.x * FOOT_M, -0.1, c.y * FOOT_M))
		head.append(Vector3(c.x * TOP_M, TOWER_M, c.y * TOP_M))
	for k: int in 4:
		VertexShapes.strut(tool, foot[k], head[k], 0.05, 0.05, WOOD)
	for level: int in 3:
		var t0 := float(level) / 3.0
		var t1 := float(level + 1) / 3.0
		for k: int in 4:
			var j := (k + 1) % 4
			var a0 := foot[k].lerp(head[k], t0)
			var b0 := foot[j].lerp(head[j], t0)
			var a1 := foot[k].lerp(head[k], t1)
			var b1 := foot[j].lerp(head[j], t1)
			VertexShapes.strut(tool, a1, b1, 0.025, 0.025, WOOD)
			VertexShapes.strut(tool, a0, b1, 0.018, 0.018, WOOD)
			VertexShapes.strut(tool, b0, a1, 0.018, 0.018, WOOD)
	VertexShapes.box(tool, Vector3(0.0, TOWER_M + 0.03, 0.0), Vector3(TOP_M + 0.12, 0.03, TOP_M + 0.12), WOOD)
	VertexShapes.cylinder(tool, Vector3(0.0, 0.25, 0.0), Vector3(0.0, TOWER_M + 0.35, 0.0), 0.035, IRON, 6)
	tool.generate_normals()
	return tool.commit()


## A roda e o leme no referencial do cubo (a roda no plano xy, de frente para −Z; o leme para +Z): o cubo, BLADES lâminas
## de chapa inclinadas, o aro e o leme de chapa vermelha na ponta da haste.
static func rotor_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.cylinder(tool, Vector3(0.0, 0.0, -0.15), Vector3(0.0, 0.0, 0.15), 0.08, IRON, 8)
	for k: int in BLADES:
		var angle := TAU * k / BLADES
		var out := Vector3(cos(angle), sin(angle), 0.0)
		var side := Vector3(-sin(angle), cos(angle), 0.0)
		var root := out * 0.2 + Vector3(0.0, 0.0, -0.12)
		var tip := out * WHEEL_M + Vector3(0.0, 0.0, -0.12)
		# a lâmina torcida: mais larga na ponta, inclinada como hélice
		var w0 := side * 0.05 + Vector3(0.0, 0.0, 0.03)
		var w1 := side * 0.14 + Vector3(0.0, 0.0, 0.07)
		VertexShapes.quad(tool, root - w0, tip - w1, tip + w1, root + w0, IRON.lightened(0.15))
	for k: int in BLADES:
		var a0 := TAU * k / BLADES
		var a1 := TAU * (k + 1) / BLADES
		VertexShapes.strut(tool, Vector3(cos(a0), sin(a0), 0.0) * WHEEL_M * 0.97 + Vector3(0.0, 0.0, -0.12),
				Vector3(cos(a1), sin(a1), 0.0) * WHEEL_M * 0.97 + Vector3(0.0, 0.0, -0.12), 0.015, 0.015, IRON)
	VertexShapes.strut(tool, Vector3(0.0, 0.0, 0.1), Vector3(0.0, 0.0, TAIL_M), 0.025, 0.025, IRON)
	VertexShapes.box(tool, Vector3(0.0, 0.12, TAIL_M - 0.2), Vector3(0.012, 0.3, 0.35), VANE)
	tool.generate_normals()
	return tool.commit()
