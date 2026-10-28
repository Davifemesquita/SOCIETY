class_name FestivalView
extends Node3D
## Festa na cidade (Fase 65): enquanto o evento da festa (Fase 11, `festival`) vale numa ilha, cada praça dela (mercado,
## praça com chafariz, coreto; sem nenhum, o entreposto) ganha um mastro na porta, com cordas de bandeirolas coloridas
## que descem até postes ao longo da rua (só por cima da estrada: nunca cruzam telhado); à noite, fogos de artifício
## estouram sobre as praças. Some quando a festa acaba. Só apresentação: lê os eventos e o mundo, não muda nada.

## Prédios que viram praça da festa, na ordem de preferência; o entreposto só se a ilha não tem nenhum.
const SQUARES: Array[StringName] = [&"fountain_square", &"bandstand", &"market"]
const MAX_SQUARES := 6
## Mastro: altura; cordas até postes desta altura, no último trecho reto de rua de até STRING_CELLS células.
const MAST_M := 7.5
const POLE_M := 3.6
const STRING_CELLS := 5
const MIN_STRING_CELLS := 2
## Bandeirola: largura, comprimento e espaço entre elas ao longo da corda; quanto a corda cede no meio.
const PENNANT_W := 0.42
const PENNANT_H := 0.55
const PENNANT_EVERY_M := 0.7
const SAG_M := 0.6
const COLORS: Array[Color] = [Color(0.8, 0.14, 0.12), Color(0.95, 0.78, 0.2), Color(0.18, 0.4, 0.72), Color(0.95, 0.95, 0.9),
		Color(0.2, 0.55, 0.25)]
const ROPE_COLOR := Color(0.3, 0.25, 0.2)
const WOOD_COLOR := Color(0.45, 0.32, 0.2)
## Fogos: acima desta noite (DayClock.night_factor), um estouro a cada FIREWORK_EVERY_S (sorteado), a esta altura.
const NIGHT_FIREWORKS := 0.45
const FIREWORK_EVERY_S := Vector2(0.9, 2.2)
const FIREWORK_HEIGHT_M := Vector2(28.0, 42.0)
const FIREWORK_POOL := 6
const FIREWORK_COLORS: Array[Color] = [Color(1.0, 0.35, 0.3), Color(1.0, 0.85, 0.35), Color(0.45, 0.7, 1.0), Color(0.6, 1.0, 0.5),
		Color(1.0, 0.55, 0.95), Color(1.0, 1.0, 0.95)]

var _simulation: Simulation
## ilha → o nó com as bandeirolas dela.
var _decor: Dictionary[int, Node3D] = {}
## Lugares dos fogos (o alto de cada mastro) das ilhas em festa.
var _launch_sites: Array[Vector3] = []
var _fireworks: Array[GPUParticles3D] = []
var _next_firework: float = 0.0
var _rng := RandomNumberGenerator.new()


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	_rng.seed = 1840
	for i: int in FIREWORK_POOL:
		var burst := _burst()
		add_child(burst)
		_fireworks.append(burst)
	EventBus.world_event_started.connect(func(_def: StringName, _island: int) -> void: rebuild())
	EventBus.world_event_ended.connect(func(_def: StringName, _island: int) -> void: rebuild())
	EventBus.world_replaced.connect(rebuild)
	# obra ou rua nova durante a festa: as praças e as cordas mudam
	EventBus.building_placed.connect(func(_id: int) -> void: _rebuild_if_festive())
	EventBus.building_removed.connect(func(_id: int) -> void: _rebuild_if_festive())
	EventBus.roads_changed.connect(func(_island: int) -> void: _rebuild_if_festive())
	rebuild()


func _rebuild_if_festive() -> void:
	if not _decor.is_empty():
		rebuild()


## Ilhas com a festa valendo agora.
static func festival_islands(world: WorldState) -> Array[int]:
	var result: Array[int] = []
	for event: WorldEvent in world.events_state.events:
		if event.def_id == &"festival" and event.island_id >= 0 and not result.has(event.island_id):
			result.append(event.island_id)
	return result


## As praças da festa na ilha (ids de prédio): as SQUARES que há, até MAX_SQUARES; sem nenhuma, o entreposto.
static func squares(simulation: Simulation, island_id: int) -> Array[int]:
	var found: Array[int] = []
	var posts: Array[int] = []
	for building_id: int in simulation.world.building_ids():
		var record := simulation.world.building(building_id)
		if record.island_id != island_id:
			continue
		var def_id := simulation.def_of(record).id
		if SQUARES.has(def_id):
			found.append(building_id)
		elif def_id == &"trading_post":
			posts.append(building_id)
	found.sort()
	posts.sort()
	return (found if not found.is_empty() else posts).slice(0, MAX_SQUARES)


## As cordas de uma praça: [o alto do mastro, o alto do poste] para cada direção em que a rua da porta segue reta por
## pelo menos MIN_STRING_CELLS células (até STRING_CELLS). Vazio se a porta não dá para uma estrada.
static func strings_of(simulation: Simulation, building_id: int) -> Array[PackedVector3Array]:
	var record := simulation.world.building(building_id)
	var def := simulation.def_of(record)
	var grid := simulation.world.island(record.island_id)
	var door := Footprint.entrance_cell(record.origin, def.size, record.rotation)
	var result: Array[PackedVector3Array] = []
	if not grid.in_bounds(door) or grid.roads[grid.index(door)] == IslandGrid.Road.NONE:
		return result
	var mast := grid.surface_world(door) + Vector3(0.0, MAST_M, 0.0)
	for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var reach := 0
		for k: int in range(1, STRING_CELLS + 1):
			var cell := door + step * k
			if not grid.in_bounds(cell) or grid.roads[grid.index(cell)] == IslandGrid.Road.NONE:
				break
			reach = k
		if reach >= MIN_STRING_CELLS:
			result.append(PackedVector3Array([mast, grid.surface_world(door + step * reach) + Vector3(0.0, POLE_M, 0.0)]))
	return result


func decorated_islands() -> Array[int]:
	return _decor.keys()


func firework_sites() -> Array[Vector3]:
	return _launch_sites


func rebuild() -> void:
	for node: Node3D in _decor.values():
		node.queue_free()
	_decor.clear()
	_launch_sites.clear()
	for island_id: int in festival_islands(_simulation.world):
		var node := Node3D.new()
		node.name = "Festival_%d" % island_id
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for building_id: int in squares(_simulation, island_id):
			var lines := strings_of(_simulation, building_id)
			if lines.is_empty():
				continue
			var mast_top: Vector3 = lines[0][0]
			_launch_sites.append(mast_top)
			_post(tool, mast_top, MAST_M, 0.09)
			for line: PackedVector3Array in lines:
				_post(tool, line[1], POLE_M, 0.06)
				_string(tool, line[0], line[1])
		var instance := MeshInstance3D.new()
		instance.mesh = tool.commit()
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.vertex_color_is_srgb = true
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.roughness = 0.8
		instance.material_override = material
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(instance)
		add_child(node)
		_decor[island_id] = node


func _process(delta: float) -> void:
	if _launch_sites.is_empty():
		return
	var night := DayClock.night_factor(_simulation.config, GameClock.clock.hour())
	if night < NIGHT_FIREWORKS:
		return
	_next_firework -= delta * GameClock.clock.speed_multiplier()
	if _next_firework > 0.0:
		return
	_next_firework = _rng.randf_range(FIREWORK_EVERY_S.x, FIREWORK_EVERY_S.y)
	launch(_launch_sites[_rng.randi() % _launch_sites.size()])


## Um estouro sobre o lugar: a primeira bomba livre do grupo, numa cor sorteada, a uma altura sorteada.
func launch(site: Vector3) -> void:
	for burst: GPUParticles3D in _fireworks:
		if burst.emitting:
			continue
		var offset := Vector3(_rng.randf_range(-12.0, 12.0), _rng.randf_range(FIREWORK_HEIGHT_M.x, FIREWORK_HEIGHT_M.y), _rng.randf_range(-12.0, 12.0))
		burst.position = site + offset
		var process := burst.process_material as ParticleProcessMaterial
		process.color = FIREWORK_COLORS[_rng.randi() % FIREWORK_COLORS.size()]
		burst.restart()
		return


## Mastro ou poste: caixa fina de madeira do chão (top - height) até top.
static func _post(tool: SurfaceTool, top: Vector3, height: float, half: float) -> void:
	var bottom := top - Vector3(0.0, height, 0.0)
	var corners := [Vector3(-half, 0.0, -half), Vector3(half, 0.0, -half), Vector3(half, 0.0, half), Vector3(-half, 0.0, half)]
	for i: int in 4:
		var a: Vector3 = corners[i]
		var b: Vector3 = corners[(i + 1) % 4]
		var normal := ((a + b) * 0.5).normalized()
		for point: Vector3 in [bottom + a, top + a, top + b, bottom + a, top + b, bottom + b]:
			tool.set_color(WOOD_COLOR)
			tool.set_normal(normal)
			tool.add_vertex(point)


## Corda cedendo no meio de from a to, com as bandeirolas penduradas (triângulos de ponta para baixo, cores alternadas).
static func _string(tool: SurfaceTool, from: Vector3, to: Vector3) -> void:
	var length := from.distance_to(to)
	var count := maxi(2, floori(length / PENNANT_EVERY_M))
	var along := (to - from).normalized()
	var flat := Vector3(along.x, 0.0, along.z).normalized()
	var normal := flat.cross(Vector3.UP).normalized()
	var previous := from
	for i: int in range(1, count + 1):
		var t := float(i) / count
		var point := from.lerp(to, t) - Vector3(0.0, SAG_M * 4.0 * t * (1.0 - t), 0.0)
		# a corda: fita fina de previous até point
		var thick := Vector3(0.0, 0.025, 0.0)
		for corner: Vector3 in [previous - thick, previous + thick, point + thick, previous - thick, point + thick, point - thick]:
			tool.set_color(ROPE_COLOR)
			tool.set_normal(normal)
			tool.add_vertex(corner)
		if i < count:
			var color := COLORS[i % COLORS.size()]
			var half := flat * PENNANT_W * 0.5
			for corner: Vector3 in [point - half, point + half, point - Vector3(0.0, PENNANT_H, 0.0)]:
				tool.set_color(color)
				tool.set_normal(normal)
				tool.add_vertex(corner)
		previous = point


## Uma bomba de fogos: estouro de uma vez em todas as direções, que cai devagar e apaga.
static func _burst() -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.amount = 70
	particles.lifetime = 1.8
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emitting = false
	particles.visibility_aabb = AABB(Vector3(-20, -20, -20), Vector3(40, 40, 40))
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 180.0
	process.initial_velocity_min = 9.0
	process.initial_velocity_max = 12.0
	process.gravity = Vector3(0.0, -4.0, 0.0)
	process.damping_min = 2.0
	process.damping_max = 3.0
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	fade.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	process.color_ramp = ramp
	particles.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(0.6, 0.6)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = SmokeView._puff_texture()
	quad.material = material
	particles.draw_pass_1 = quad
	return particles
