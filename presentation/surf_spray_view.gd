class_name SurfSprayView
extends Node3D
## Fase 123: o borrifo nas falésias. Onde o mar bate na rocha (os rochedos e as rochas das falésias da `RockView`,
## `spray_sites`), de tempos em tempos sobe um jato de espuma branca que se abre e cai: a cada `delay` (entre
## INTERVAL_S), com a câmera perto do chão (até CAMERA_M), um dos pontos até RANGE_M de onde ela olha (`pick`, pelo
## sorteio da vez) ganha um jato, na beira da rocha do lado do mar (`spot`). Os jatos são um punhado de
## partículas `one_shot` reaproveitadas (POOL), desenhadas depois da água (`ShipView.ABOVE_WATER`) e em menos partículas
## nos níveis gráficos baixos. No tempo de jogo: parado na pausa. Só apresentação; nada no save.

const POOL := 6
const INTERVAL_S := Vector2(0.5, 1.6)
const CAMERA_M := 260.0
const RANGE_M := 140.0
const NEAREST := 12
const AMOUNT := 18
const LIFETIME_S := 2.2
const PUFF_M := 2.4
const RISE_M_S := Vector2(4.0, 8.5)
const SPREAD_DEG := 28.0
const WATER_Y := 0.15
const SIDES := 6

var _sites: Callable
var _height: Callable
var _particles_ratio := 1.0
var _pool: Array[GPUParticles3D] = []
var _next := 0
var _wait := 0.0
var _count := 0
var _material: StandardMaterial3D


## sites devolve os pontos atuais (x, z, raio): a `RockView` é refeita a cada mundo novo; height dá a altura do chão.
func setup(sites: Callable, height: Callable = Callable()) -> void:
	_sites = sites
	_height = height
	_material = StandardMaterial3D.new()
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_material.vertex_color_use_as_albedo = true
	_material.albedo_texture = SmokeView._puff_texture()
	_material.render_priority = ShipView.ABOVE_WATER
	for i: int in POOL:
		var jet := _build_jet()
		jet.name = "Spray_%d" % i
		add_child(jet)
		_pool.append(jet)


func set_quality(preset: GraphicsPresetDef) -> void:
	_particles_ratio = preset.particles_ratio if preset != null else 1.0
	for jet: GPUParticles3D in _pool:
		jet.amount = maxi(6, roundi(AMOUNT * _particles_ratio))


## Jatos lançados desde o começo (testes).
func spray_count() -> int:
	return _count


func _process(delta: float) -> void:
	var speed := GameClock.clock.speed_multiplier()
	for jet: GPUParticles3D in _pool:
		jet.speed_scale = speed
	if speed <= 0.0 or not _sites.is_valid():
		return
	_wait -= delta * speed
	if _wait > 0.0:
		return
	_wait = delay(_count)
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	if camera == null:
		return
	var forward := -camera.global_basis.z
	if forward.y > -0.01:
		return
	var focus := camera.global_position + forward * (-camera.global_position.y / forward.y)
	if camera.global_position.distance_to(focus) > CAMERA_M:
		return
	var sites: PackedVector3Array = _sites.call()
	var site := pick(sites, Vector2(focus.x, focus.z), _count)
	if site.z < 0.0:
		return
	launch(spot(site, _count, _height))


## Lança um jato no ponto (reaproveita o jato usado há mais tempo).
func launch(at: Vector3) -> void:
	var jet := _pool[_next]
	_next = (_next + 1) % _pool.size()
	jet.global_position = at
	jet.restart()
	jet.emitting = true
	_count += 1


## O tempo até o próximo jato, pelo número dele (sem sorteio de estado).
static func delay(index: int) -> float:
	var roll := float(absi(hash([index, &"spray"])) % 1000) / 1000.0
	return lerpf(INTERVAL_S.x, INTERVAL_S.y, roll)


## O ponto (x, z, raio) da vez entre os NEAREST mais perto de focus, até RANGE_M; z < 0 se nenhum.
static func pick(sites: PackedVector3Array, focus: Vector2, index: int) -> Vector3:
	var near: Array = []
	for site: Vector3 in sites:
		var meters := Vector2(site.x, site.y).distance_to(focus)
		if meters <= RANGE_M:
			near.append([meters, site])
	if near.is_empty():
		return Vector3(0.0, 0.0, -1.0)
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var count := mini(near.size(), NEAREST)
	var chosen: Vector3 = near[absi(hash([index, &"spray_site"])) % count][1]
	return chosen


## Onde o jato sobe: na beira da rocha (o raio dela), na água. Com a altura do chão (height, x e z → m), dos SIDES lados a
## partir do da vez fica o mais baixo — o do mar (o jato do lado da terra subia na grama); sem ela, o lado da vez.
static func spot(site: Vector3, index: int, height: Callable = Callable()) -> Vector3:
	var start := float(absi(hash([index, &"spray_side"])) % 360) * PI / 180.0
	var reach := site.z * 0.9
	var best := Vector3(site.x + cos(start) * reach, WATER_Y, site.y + sin(start) * reach)
	if not height.is_valid():
		return best
	var lowest := INF
	for k: int in SIDES:
		var angle := start + TAU * k / SIDES
		var at := Vector3(site.x + cos(angle) * reach, WATER_Y, site.y + sin(angle) * reach)
		var ground: float = height.call(at.x, at.z)
		if ground < lowest:
			lowest = ground
			best = at
	return best


func _build_jet() -> GPUParticles3D:
	var jet := GPUParticles3D.new()
	jet.one_shot = true
	jet.emitting = false
	jet.explosiveness = 0.85
	jet.amount = AMOUNT
	jet.lifetime = LIFETIME_S
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.8
	process.direction = Vector3.UP
	process.spread = SPREAD_DEG
	process.initial_velocity_min = RISE_M_S.x
	process.initial_velocity_max = RISE_M_S.y
	process.gravity = Vector3(0.0, -7.5, 0.0)
	process.damping_min = 0.6
	process.damping_max = 1.2
	process.scale_min = 0.7
	process.scale_max = 1.6
	var size := Curve.new()
	size.add_point(Vector2(0.0, 0.5))
	size.add_point(Vector2(1.0, 1.4))
	var size_texture := CurveTexture.new()
	size_texture.curve = size
	process.scale_curve = size_texture
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 1.0, 1.0, 0.8))
	fade.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	process.color_ramp = ramp
	jet.process_material = process
	var puff := QuadMesh.new()
	puff.size = Vector2(PUFF_M, PUFF_M)
	puff.material = _material
	jet.draw_pass_1 = puff
	jet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	jet.visibility_aabb = AABB(Vector3(-6.0, -1.0, -6.0), Vector3(12.0, 12.0, 12.0))
	return jet
