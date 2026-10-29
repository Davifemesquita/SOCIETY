class_name FestivalView
extends Node3D
## Festa na cidade (Fase 65): enquanto o evento da festa (Fase 11, `festival`) vale numa ilha, cada praça dela (mercado,
## praça com chafariz, coreto; sem nenhum, o entreposto) ganha um mastro na porta, com cordas de bandeirolas coloridas
## que descem até postes ao longo da rua (só por cima da estrada: nunca cruzam telhado); à noite, fogos de artifício
## estouram sobre as praças. Some quando a festa acaba. Só apresentação: lê os eventos e o mundo, não muda nada.
## Desde a Fase 85, cada estouro avisa (exploded): o povo na praça bate palmas e o som do estouro e das palmas toca.
## Desde a Fase 86, o fogo sobe do mastro como um foguete (fire: cabeça acesa e rastro de faíscas, ROCKET_RISE_S) e só
## estoura lá em cima; a subida avisa (launched) para o assobio.

## Um estouro no céu, na ilha da festa (Fase 85).
signal exploded(island_id: int, position: Vector3)
## Um foguete subindo de from até to em rise_s segundos de jogo (Fase 86).
signal launched(island_id: int, from: Vector3, to: Vector3, rise_s: float)

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
## Fase 86: o foguete leva de ROCKET_RISE_S.x a .y segundos de jogo do alto do mastro até o estouro, balançando até
## ROCKET_WOBBLE_M para o lado; no máximo ROCKET_POOL no ar.
const ROCKET_RISE_S := Vector2(0.9, 1.4)
const ROCKET_WOBBLE_M := 0.8
const ROCKET_POOL := 8
## O brilho da cabeça e o tamanho de cada faísca do rastro (m).
const ROCKET_GLOW_M := 1.6
const ROCKET_SPARK_M := 0.7
const FIREWORK_COLORS: Array[Color] = [Color(1.0, 0.35, 0.3), Color(1.0, 0.85, 0.35), Color(0.45, 0.7, 1.0), Color(0.6, 1.0, 0.5),
		Color(1.0, 0.55, 0.95), Color(1.0, 1.0, 0.95)]

var _simulation: Simulation
## ilha → o nó com as bandeirolas dela.
var _decor: Dictionary[int, Node3D] = {}
## Lugares dos fogos (o alto de cada mastro) das ilhas em festa.
var _launch_sites: Array[Vector3] = []
## A ilha de cada lugar (Fase 85).
var _launch_islands := PackedInt32Array()
var _fireworks: Array[GPUParticles3D] = []
var _next_firework: float = 0.0
var _rng := RandomNumberGenerator.new()
## Fase 86: os foguetes (reaproveitados) e o voo de cada um.
var _rockets: Array[Rocket] = []


class Rocket:
	var node: Node3D
	var trail: GPUParticles3D
	var flying: bool = false
	var site := Vector3.ZERO
	var from := Vector3.ZERO
	var to := Vector3.ZERO
	var rise_s: float = 1.0
	var elapsed: float = 0.0
	var wobble := Vector2.ZERO


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	_rng.seed = 1840
	for i: int in FIREWORK_POOL:
		var burst := _burst()
		add_child(burst)
		_fireworks.append(burst)
	for i: int in ROCKET_POOL:
		var rocket := _rocket()
		rocket.node.name = "Rocket%d" % i
		add_child(rocket.node)
		_rockets.append(rocket)
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
	_launch_islands.clear()
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
			_launch_islands.append(island_id)
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
	var game_delta := delta * GameClock.clock.speed_multiplier()
	advance_rockets(game_delta)
	if _launch_sites.is_empty():
		return
	var night := DayClock.night_factor(_simulation.config, GameClock.clock.hour())
	if night < NIGHT_FIREWORKS:
		return
	_next_firework -= game_delta
	if _next_firework > 0.0:
		return
	_next_firework = _rng.randf_range(FIREWORK_EVERY_S.x, FIREWORK_EVERY_S.y)
	fire(_launch_sites[_rng.randi() % _launch_sites.size()])


## Um estouro sobre o lugar: a primeira bomba livre do grupo, numa cor sorteada, a uma altura sorteada.
func launch(site: Vector3) -> void:
	burst_at(site, site + _burst_offset())


## Fase 86: o estouro em at (sobre o lugar site).
func burst_at(site: Vector3, at: Vector3) -> void:
	for burst: GPUParticles3D in _fireworks:
		if burst.emitting:
			continue
		burst.position = at
		var process := burst.process_material as ParticleProcessMaterial
		process.color = FIREWORK_COLORS[_rng.randi() % FIREWORK_COLORS.size()]
		burst.restart()
		exploded.emit(_island_of(site), burst.position)
		return


func _burst_offset() -> Vector3:
	return Vector3(_rng.randf_range(-12.0, 12.0), _rng.randf_range(FIREWORK_HEIGHT_M.x, FIREWORK_HEIGHT_M.y), _rng.randf_range(-12.0, 12.0))


func _island_of(site: Vector3) -> int:
	var site_index := _launch_sites.find(site)
	return _launch_islands[site_index] if site_index >= 0 else -1


## Fase 86: um foguete sobe do alto do mastro (site) até o ponto do estouro e estoura lá. Sem foguete livre, nada.
func fire(site: Vector3) -> bool:
	for rocket: Rocket in _rockets:
		if rocket.flying:
			continue
		rocket.flying = true
		rocket.site = site
		rocket.from = site
		rocket.to = site + _burst_offset()
		rocket.rise_s = _rng.randf_range(ROCKET_RISE_S.x, ROCKET_RISE_S.y)
		rocket.elapsed = 0.0
		rocket.wobble = Vector2(_rng.randf_range(0.0, TAU), _rng.randf_range(2.0, 4.0))
		rocket.node.position = site
		rocket.node.visible = true
		rocket.trail.emitting = true
		launched.emit(_island_of(site), rocket.from, rocket.to, rocket.rise_s)
		return true
	return false


## Fase 86: anda os foguetes no ar game_delta segundos de jogo; o que chega em cima estoura.
func advance_rockets(game_delta: float) -> void:
	for rocket: Rocket in _rockets:
		if not rocket.flying or game_delta <= 0.0:
			continue
		rocket.elapsed += game_delta
		if rocket.elapsed >= rocket.rise_s:
			rocket.flying = false
			rocket.node.visible = false
			rocket.trail.emitting = false
			burst_at(rocket.site, rocket.to)
			continue
		rocket.node.position = rocket_point(rocket, rocket.elapsed / rocket.rise_s)


## Ponto do foguete na fração t da subida: rápido no começo e devagar no alto (perde força), balançando para o lado.
static func rocket_point(rocket: Rocket, t: float) -> Vector3:
	var climb := 1.0 - (1.0 - t) * (1.0 - t)
	var side := sin(rocket.wobble.x + t * rocket.wobble.y * TAU) * ROCKET_WOBBLE_M * sin(t * PI)
	var across := Vector3(rocket.to.z - rocket.from.z, 0.0, rocket.from.x - rocket.to.x).normalized()
	return rocket.from.lerp(rocket.to, climb) + across * side


func rockets_flying() -> int:
	var count := 0
	for rocket: Rocket in _rockets:
		count += int(rocket.flying)
	return count


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


## Fase 86: o foguete: a cabeça acesa (um brilho de ROCKET_GLOW_M sempre de frente para a câmera: uma esfera de verdade
## sumia na distância da câmera da cidade) e o rastro de faíscas, que ficam no mundo e caem.
static func _rocket() -> Rocket:
	var rocket := Rocket.new()
	rocket.node = Node3D.new()
	rocket.node.name = "Rocket"
	rocket.node.visible = false
	var head := MeshInstance3D.new()
	var glow_quad := QuadMesh.new()
	glow_quad.size = Vector2(ROCKET_GLOW_M, ROCKET_GLOW_M)
	var glow := StandardMaterial3D.new()
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	glow.albedo_color = Color(1.0, 0.85, 0.55)
	glow.albedo_texture = SmokeView._puff_texture()
	glow_quad.material = glow
	head.mesh = glow_quad
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rocket.node.add_child(head)
	var trail := GPUParticles3D.new()
	trail.amount = 90
	trail.lifetime = 0.9
	trail.local_coords = false
	trail.emitting = false
	trail.visibility_aabb = AABB(Vector3(-25, -45, -25), Vector3(50, 50, 50))
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.DOWN
	process.spread = 25.0
	process.initial_velocity_min = 0.5
	process.initial_velocity_max = 1.5
	process.gravity = Vector3(0.0, -3.0, 0.0)
	process.color = Color(1.0, 0.7, 0.35)
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	fade.set_color(1, Color(1.0, 0.5, 0.2, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	process.color_ramp = ramp
	trail.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(ROCKET_SPARK_M, ROCKET_SPARK_M)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = SmokeView._puff_texture()
	quad.material = material
	trail.draw_pass_1 = quad
	rocket.node.add_child(trail)
	rocket.trail = trail
	return rocket


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
