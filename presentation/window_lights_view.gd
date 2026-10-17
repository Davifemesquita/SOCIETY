class_name WindowLightsView
extends Node3D
## Janelas acesas à noite (seções 9 e 11): vidros em todas as fachadas, num MultiMesh só, que
## acendem com a noite (global night_light) se o prédio está aceso — casa com morador, produção
## trabalhando, serviço com estrada. Perto da câmera, um grupo fixo de AreaLight3D (novo no 4.7)
## ilumina a rua na frente dos prédios acesos mais próximos. Só lê a simulação.

const SHADER := preload("res://shaders/window_light.gdshader")
const WINDOW_SIZE := Vector2(0.9, 1.1)
const FLOOR_HEIGHT_M := 2.8
const FIRST_WINDOW_Y_M := 1.7
const COLUMN_SPACING_M := 2.4
## Folga entre o vidro e a parede (sem briga de profundidade).
const WALL_GAP_M := 0.03
## A mesma folga das caixas dos prédios na BuildingView.
const BUILDING_INSET_M := 0.3
## Largura da porta na BuildingView: nenhuma janela do térreo encosta nela.
const DOOR_WIDTH_M := 1.4
const REFRESH_SECONDS := 0.5
const AREA_LIGHT_SECONDS := 0.25
const AREA_LIGHT_RADIUS_M := 90.0
const AREA_LIGHT_ENERGY := 3.0
const AREA_LIGHT_RANGE_M := 9.0
const HIDDEN := Transform3D(Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO), Vector3.ZERO)

var _simulation: Simulation
var _config: GameConfig
var _instance := MultiMeshInstance3D.new()
var _slots: Dictionary[int, PackedInt32Array] = {}
var _lit: Dictionary[int, bool] = {}
var _free := PackedInt32Array()
var _transforms: Array[Transform3D] = []
var _thresholds := PackedFloat32Array()
var _slot_lit := PackedByteArray()
var _area_lights: Array[AreaLight3D] = []
## Luzes de área em uso (o nível gráfico escolhe; as outras ficam apagadas).
var area_light_limit: int = 12
var _refresh_left: float = 0.0
var _area_left: float = 0.0
var _rng := RandomNumberGenerator.new()


func setup(simulation: Simulation, config: GameConfig) -> void:
	_simulation = simulation
	_config = config
	_rng.seed = 7
	var quad := QuadMesh.new()
	# o tamanho do vidro vem na escala de cada instância
	quad.size = Vector2.ONE
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter(&"light_color", config.window_light_color)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = quad
	_instance.multimesh = multimesh
	_instance.material_override = material
	_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_instance)
	area_light_limit = config.night_area_lights
	var most := config.night_area_lights
	for preset: GraphicsPresetDef in config.graphics_presets:
		most = maxi(most, preset.area_lights)
	for i: int in most:
		var light := AreaLight3D.new()
		light.light_color = config.window_light_color
		light.area_size = Vector2(2.5, 1.2)
		light.area_range = AREA_LIGHT_RANGE_M
		light.shadow_enabled = false
		light.visible = false
		add_child(light)
		_area_lights.append(light)
	EventBus.building_placed.connect(_add)
	EventBus.building_removed.connect(_remove)
	EventBus.house_upgraded.connect(func(building_id: int) -> void:
		_remove(building_id)
		_add(building_id))
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func rebuild() -> void:
	for building_id: int in _slots.keys():
		_remove(building_id)
	for building_id: int in _simulation.world.building_ids():
		_add(building_id)


func window_count() -> int:
	var total := 0
	for slots: PackedInt32Array in _slots.values():
		total += slots.size()
	return total


func is_building_lit(building_id: int) -> bool:
	return _lit.get(building_id, false)


func lit_area_lights() -> int:
	return _area_lights.filter(func(light: AreaLight3D) -> bool: return light.visible).size()


## Vidros do prédio de modelo: um em cada janela do BuildingKit, girado com o prédio. Sem o kit (ou
## para campo e píer), o desenho antigo de windows_of.
static func building_windows(simulation: Simulation, record: BuildingRecord) -> Array[Transform3D]:
	var grid := simulation.world.island(record.island_id)
	var def := simulation.def_of(record)
	var spec := BuildingKit.spec_for(simulation, record, grid.cell_size)
	var height := simulation.data.tier(record.tier).house_height_m if record.is_house() else def.height_m
	if spec == null:
		return windows_of(grid, record, def, height)
	var center := grid.rect_world(Footprint.rect(record.origin, def.size, record.rotation))
	var place := Transform3D(Basis(Vector3.UP, -PI * 0.5 * posmod(record.rotation, 4)), center)
	var result: Array[Transform3D] = []
	for window: Transform3D in BuildingKit.windows(spec):
		result.append(place * window)
	return result


## Vidros de um prédio (caixa): em cada fachada, colunas a cada ~2,4 m e um andar a cada 2,8 m; no térreo
## da frente, nada no lugar da porta.
static func windows_of(grid: IslandGrid, record: BuildingRecord, def: BuildingDef, height: float) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var cell_size := grid.cell_size
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var center := grid.rect_world(area)
	var half := Vector2(area.size.x * cell_size - BUILDING_INSET_M, area.size.y * cell_size - BUILDING_INSET_M) * 0.5
	var front := Footprint.front_direction(record.rotation)
	var entrance := grid.cell_world(Footprint.entrance_cell(record.origin, def.size, record.rotation))
	var door := Vector3(entrance.x - center.x, 0.0, entrance.z - center.z)
	var floors := maxi(1, floori((height - 0.5) / FLOOR_HEIGHT_M))
	for side: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var normal := Vector3(side.x, 0.0, side.y)
		var along := normal.cross(Vector3.UP)
		var depth := half.x if side.x != 0 else half.y
		var length := (half.y if side.x != 0 else half.x) * 2.0
		var columns := maxi(1, floori((length - 0.6) / COLUMN_SPACING_M))
		for level: int in floors:
			var y := FIRST_WINDOW_Y_M + level * FLOOR_HEIGHT_M
			if y + WINDOW_SIZE.y * 0.5 > height - 0.3:
				break
			for column: int in columns:
				var t := -length * 0.5 + length * (column + 0.5) / columns
				# em prédio de largura par a porta fica meia célula fora do meio
				if side == front and level == 0 and absf(t - door.dot(along)) < (WINDOW_SIZE.x + DOOR_WIDTH_M) * 0.5 + 0.1:
					continue
				var origin := Vector3(center.x, center.y + y, center.z) + normal * (depth + WALL_GAP_M) + along * t
				result.append(Transform3D(Basis.looking_at(-normal, Vector3.UP).scaled_local(Vector3(WINDOW_SIZE.x, WINDOW_SIZE.y, 1.0)), origin))
	return result


## Prédio aceso à noite: casa com morador, produção trabalhando, serviço ou depósito com estrada.
static func is_lit(simulation: Simulation, record: BuildingRecord) -> bool:
	var def := simulation.def_of(record)
	match def.kind:
		BuildingDef.Kind.RESIDENCE:
			return record.residents > 0.5
		BuildingDef.Kind.PRODUCTION:
			return not record.paused and record.productivity >= 0.3
		BuildingDef.Kind.MODULE:
			return false
	return simulation.has_road_access(record.id)


func _process(delta: float) -> void:
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		refresh_lit()
	_area_left -= delta
	if _area_left <= 0.0:
		_area_left = AREA_LIGHT_SECONDS
		var night := DayClock.night_factor(_config, GameClock.clock.hour())
		var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
		if camera != null:
			place_area_lights(camera.global_position, -camera.global_basis.z, night)


func _add(building_id: int) -> void:
	var record := _simulation.world.building(building_id)
	if record == null or _slots.has(building_id):
		return
	var def := _simulation.def_of(record)
	# campo e pasto, píer (trapiche, Fase 15) e decoração (Fase 16) não têm fachada
	if def.kind in [BuildingDef.Kind.MODULE, BuildingDef.Kind.PIER, BuildingDef.Kind.DECORATION]:
		return
	var windows := building_windows(_simulation, record)
	var slots := PackedInt32Array()
	var lit := is_lit(_simulation, record)
	for window: Transform3D in windows:
		var slot := _take_slot()
		_transforms[slot] = window
		_thresholds[slot] = _rng.randf()
		slots.append(slot)
		_write(slot, lit)
	_slots[building_id] = slots
	_lit[building_id] = lit


func _remove(building_id: int) -> void:
	if not _slots.has(building_id):
		return
	var multimesh := _instance.multimesh
	for slot: int in _slots[building_id]:
		_transforms[slot] = HIDDEN
		multimesh.set_instance_transform(slot, HIDDEN)
		_free.append(slot)
	_slots.erase(building_id)
	_lit.erase(building_id)


func _take_slot() -> int:
	if _free.is_empty():
		var old := _transforms.size()
		var capacity := maxi(256, old * 2)
		_transforms.resize(capacity)
		_thresholds.resize(capacity)
		_slot_lit.resize(capacity)
		for slot: int in range(capacity - 1, old - 1, -1):
			_transforms[slot] = HIDDEN
			_free.append(slot)
		# mudar o tamanho apaga o MultiMesh: escreve tudo de novo
		_instance.multimesh.instance_count = capacity
		for slot: int in old:
			_write(slot, _slot_lit[slot] == 1)
		for slot: int in range(old, capacity):
			_instance.multimesh.set_instance_transform(slot, HIDDEN)
	var slot := _free[_free.size() - 1]
	_free.resize(_free.size() - 1)
	return slot


func _write(slot: int, lit: bool) -> void:
	_slot_lit[slot] = 1 if lit else 0
	_instance.multimesh.set_instance_transform(slot, _transforms[slot])
	_instance.multimesh.set_instance_custom_data(slot, Color(_thresholds[slot], 1.0 if lit else 0.0, 0.0, 0.0))


func refresh_lit() -> void:
	for building_id: int in _slots:
		var record := _simulation.world.building(building_id)
		if record == null:
			continue
		var lit := is_lit(_simulation, record)
		if lit != _lit.get(building_id, false):
			_lit[building_id] = lit
			for slot: int in _slots[building_id]:
				_write(slot, lit)


## Põe as luzes de área nos prédios acesos mais perto de onde a câmera olha, de noite e com a
## câmera perto; senão, apaga todas.
func place_area_lights(camera_position: Vector3, camera_forward: Vector3, night: float) -> void:
	var focus := camera_position
	if camera_forward.y < -0.01:
		focus = camera_position + camera_forward * (-camera_position.y / camera_forward.y)
	var close := camera_position.distance_to(focus) <= _config.night_area_light_camera_distance_m
	var chosen: Array[Vector2] = []
	if night > 0.05 and close:
		for building_id: int in _lit:
			if not _lit[building_id]:
				continue
			var record := _simulation.world.building(building_id)
			var def := _simulation.def_of(record)
			var center := _simulation.world.island(record.island_id).rect_world(Footprint.rect(record.origin, def.size, record.rotation))
			var gap := Vector2(center.x - focus.x, center.z - focus.z).length_squared()
			if gap <= AREA_LIGHT_RADIUS_M * AREA_LIGHT_RADIUS_M:
				chosen.append(Vector2(gap, building_id))
		chosen.sort()
	for index: int in _area_lights.size():
		var light := _area_lights[index]
		light.visible = index < chosen.size() and index < area_light_limit
		if light.visible:
			_aim(light, _simulation.world.building(int(chosen[index].y)), night)


## Luz na fachada da frente, à altura das janelas do térreo, apontando para a rua.
func _aim(light: AreaLight3D, record: BuildingRecord, night: float) -> void:
	var def := _simulation.def_of(record)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var center := _simulation.world.island(record.island_id).rect_world(area)
	var front := Footprint.front_direction(record.rotation)
	var outward := Vector3(front.x, 0.0, front.y)
	var depth := (area.size.x if front.x != 0 else area.size.y) * _config.cell_size_m * 0.5
	var width := (area.size.y if front.x != 0 else area.size.x) * _config.cell_size_m
	light.global_transform = Transform3D(Basis.looking_at(outward, Vector3.UP),
			Vector3(center.x, center.y + FIRST_WINDOW_Y_M, center.z) + outward * (depth + 0.2))
	light.area_size = Vector2(minf(width * 0.6, 4.0), 1.2)
	light.light_energy = AREA_LIGHT_ENERGY * night
