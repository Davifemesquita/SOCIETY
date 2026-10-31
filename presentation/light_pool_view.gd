class_name LightPoolView
extends Node3D
## Fase 119: as poças de luz à noite. Debaixo de cada poste (`LampView.lamp_points`), em volta de cada fogueira
## (`LampView.fire_points`) e diante da porta de cada casa com morador (`RoadMask.doors`), um disco de luz quente deitado
## no chão e inclinado com ele (`pools`), somado à cena pelo `shaders/light_pool.gdshader`, que acende com o global
## night_light. Sem luz de verdade: o OmniLight3D continua só nos postes perto da câmera. Um MultiMesh do arquipélago,
## escondido de dia; refeito quando os postes mudam, na obra e na demolição, e quando muda o número de casas com
## morador (conferido a cada CHECK_S de noite). Nada no save.

const LAMP_RADIUS_M := 3.2
const FIRE_RADIUS_M := 2.6
const DOOR_RADIUS_M := 1.6
## Quanto a poça da porta sai para a rua, a partir da divisa.
const DOOR_OUT_M := 0.7
const LIFT_M := 0.12
const LAMP_COLOR := Color(1.0, 0.78, 0.45)
const FIRE_COLOR := Color(1.0, 0.5, 0.18)
const DOOR_COLOR := Color(1.0, 0.72, 0.4)
## A força de cada tipo (no alfa da cor da instância).
const LAMP_STRENGTH := 1.0
const FIRE_STRENGTH := 0.9
const DOOR_STRENGTH := 0.45
const CHECK_S := 5.0
## A noite (DayClock.night_factor) a partir da qual as poças aparecem.
const SHOW_AT := 0.02

var _simulation: Simulation
var _lamps: LampView
var _pools := MultiMeshInstance3D.new()
var _dirty := true
var _lit_houses := -1
var _wait := 0.0


func setup(simulation: Simulation, lamps: LampView) -> void:
	_simulation = simulation
	_lamps = lamps
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	quad.orientation = PlaneMesh.FACE_Y
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/light_pool.gdshader") as Shader
	quad.material = material
	_pools.name = "LightPools"
	_pools.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pools.multimesh = MultiMesh.new()
	_pools.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_pools.multimesh.use_colors = true
	_pools.multimesh.mesh = quad
	add_child(_pools)
	if _lamps != null:
		_lamps.rebuilt.connect(_mark)
	EventBus.building_placed.connect(_mark_id)
	EventBus.building_removed.connect(_mark_id)
	EventBus.world_replaced.connect(_mark)
	rebuild()


func pool_count() -> int:
	return _pools.multimesh.instance_count


func _mark() -> void:
	_dirty = true


func _mark_id(_id: int) -> void:
	_dirty = true


func _process(delta: float) -> void:
	if _simulation == null:
		return
	var night := DayClock.night_factor(_simulation.config, GameClock.clock.hour())
	_pools.visible = night >= SHOW_AT
	if not _pools.visible:
		return
	_wait -= delta
	if _wait <= 0.0:
		_wait = CHECK_S
		if lit_houses(_simulation.world) != _lit_houses:
			_dirty = true
	if _dirty:
		rebuild()


## Quantas casas têm morador (a porta delas fica acesa).
static func lit_houses(world: WorldState) -> int:
	var count := 0
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.is_house() and record.residents > 0.0:
			count += 1
	return count


func rebuild() -> void:
	_dirty = false
	_lit_houses = lit_houses(_simulation.world)
	var lamps: Array[Vector3] = []
	var fires: Array[Vector3] = []
	if _lamps != null:
		lamps = _lamps.lamp_points()
		fires = _lamps.fire_points()
	var list := pools(_simulation.world, _simulation.data, lamps, fires)
	var multimesh := _pools.multimesh
	multimesh.instance_count = list.size()
	for i: int in list.size():
		var pool: Array = list[i]
		var place: Transform3D = pool[0]
		var color: Color = pool[1]
		multimesh.set_instance_transform(i, place)
		multimesh.set_instance_color(i, color)
	multimesh.custom_aabb = WorldBounds.of(_simulation.config)


## As poças: [lugar (o disco de 2 m de lado escalado para o raio, deitado no chão), cor com a força no alfa].
static func pools(world: WorldState, data: GameData, lamps: Array[Vector3], fires: Array[Vector3]) -> Array[Array]:
	var result: Array[Array] = []
	for point: Vector3 in lamps:
		var place: Variant = _on_ground(world, Vector2(point.x, point.z), LAMP_RADIUS_M)
		if place != null:
			result.append([place, Color(LAMP_COLOR, LAMP_STRENGTH)])
	for point: Vector3 in fires:
		var place: Variant = _on_ground(world, Vector2(point.x, point.z), FIRE_RADIUS_M)
		if place != null:
			result.append([place, Color(FIRE_COLOR, FIRE_STRENGTH)])
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		var doors := RoadMask.doors(world, data, island_id)
		for id: int in doors:
			var record := world.buildings[id]
			if not record.is_house() or record.residents <= 0.0:
				continue
			var front := Vector2(Footprint.front_direction(record.rotation))
			var spot := grid.origin_m + doors[id] + front * DOOR_OUT_M
			var place: Variant = _on_ground(world, spot, DOOR_RADIUS_M)
			if place != null:
				result.append([place, Color(DOOR_COLOR, DOOR_STRENGTH)])
	return result


## O disco deitado no chão no ponto (x, z), inclinado com o relevo (pela altura a meio raio dos quatro lados) e LIFT_M
## acima dele; null no mar.
static func _on_ground(world: WorldState, spot: Vector2, radius: float) -> Variant:
	var height := world.surface_height(spot.x, spot.y)
	if height < -0.5:
		return null
	var reach := radius * 0.5
	var dx := (world.surface_height(spot.x + reach, spot.y) - world.surface_height(spot.x - reach, spot.y)) / (2.0 * reach)
	var dz := (world.surface_height(spot.x, spot.y + reach) - world.surface_height(spot.x, spot.y - reach)) / (2.0 * reach)
	var up := Vector3(-dx, 1.0, -dz).normalized()
	var x := Vector3(1.0, dx, 0.0).normalized()
	var z := x.cross(up).normalized()
	x = up.cross(z).normalized()
	var basis := Basis(x * radius, up, z * radius)
	return Transform3D(basis, Vector3(spot.x, height + LIFT_M, spot.y))
