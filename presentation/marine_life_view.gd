class_name MarineLifeView
extends Node3D
## Vida no mar (Fase 64): baleias no mar aberto e golfinhos em águas médias, longe da costa, geradas no código (sem
## asset). A baleia nada num círculo grande em volta do lugar dela e, uma vez por ciclo, sobe, sopra o esguicho, mostra
## o dorso e mergulha erguendo a cauda; o resto do ciclo fica no fundo. O bando de golfinhos dá a volta no lugar dele e
## cada golfinho salta em arco, um depois do outro. Os lugares saem do campo de distância da costa (CoastField) e da
## semente do mundo; o movimento é contado aqui a cada quadro no tempo de jogo (para na pausa). Só apresentação: nada
## lê ou muda a simulação.

const WHALES := 4
const DOLPHIN_PODS := 3
const DOLPHINS_PER_POD := 4
## Distância até a costa (m, negativa na água) de cada um: a baleia no mar aberto (o campo corta em -64), o golfinho em
## águas médias.
const WHALE_COAST_M := -60.0
const DOLPHIN_COAST_M := Vector2(-45.0, -14.0)
## Até onde fora das ilhas o lugar pode cair (m).
const MARGIN_M := 260.0
## Baleia: comprimento, raio do círculo, velocidade, ciclo, quanto dele ela fica à tona e quanto dura o mergulho.
const WHALE_LENGTH_M := 14.0
const WHALE_CIRCLE_M := 120.0
const WHALE_SPEED_M_S := 2.0
const WHALE_CYCLE_S := 40.0
const WHALE_SURFACE_S := 8.0
const WHALE_DIVE_S := 3.0
## O dorso da baleia à tona fica tanto acima d'água (m); no fundo ela some.
const WHALE_SURFACE_Y := -0.7
const WHALE_DEEP_Y := -14.0
## Golfinho: comprimento, raio da volta do bando, velocidade, ciclo dos saltos, duração e altura do salto.
const DOLPHIN_LENGTH_M := 2.4
const DOLPHIN_CIRCLE_M := 60.0
const DOLPHIN_SPEED_M_S := 6.0
const DOLPHIN_CYCLE_S := 4.0
const DOLPHIN_JUMP_S := 1.2
const DOLPHIN_JUMP_M := 1.5
const DOLPHIN_DEEP_Y := -2.5
const WHALE_COLOR := Color(0.2, 0.23, 0.28)
const WHALE_BELLY := Color(0.55, 0.57, 0.58)
const DOLPHIN_COLOR := Color(0.42, 0.47, 0.53)
const DOLPHIN_BELLY := Color(0.82, 0.83, 0.82)
const VISIBLE_UNTIL_M := 1600.0
const HIDDEN := Transform3D(Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO), Vector3.ZERO)

var _whales := MultiMeshInstance3D.new()
var _dolphins := MultiMeshInstance3D.new()
var _spouts: Array[GPUParticles3D] = []
## Lugares (meio da volta) de cada baleia e de cada bando, no mundo (y = 0).
var _whale_sites: Array[Vector3] = []
var _pod_sites: Array[Vector3] = []
var _surfaced: Array[bool] = []
var _time: float = 0.0


func setup(coast: CoastField, bounds: Rect2, seed_value: int) -> void:
	var area := bounds.grow(MARGIN_M)
	_whale_sites = sites(coast, area, WHALES, -INF, WHALE_COAST_M, hash([seed_value, &"baleias"]))
	_pod_sites = sites(coast, area, DOLPHIN_PODS, DOLPHIN_COAST_M.x, DOLPHIN_COAST_M.y, hash([seed_value, &"golfinhos"]))
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.35
	for part: Array in [[_whales, "Whales", whale_mesh(), _whale_sites.size()],
			[_dolphins, "Dolphins", dolphin_mesh(), _pod_sites.size() * DOLPHINS_PER_POD]]:
		var layer: MultiMeshInstance3D = part[0]
		layer.name = part[1]
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.mesh = part[2]
		layer.multimesh.instance_count = part[3]
		layer.material_override = material
		layer.visibility_range_end = VISIBLE_UNTIL_M
		# a caixa do MultiMesh muda a cada quadro: sem ela o motor recalcularia (e cortaria) os bichos
		layer.custom_aabb = AABB(Vector3(area.position.x, -20.0, area.position.y), Vector3(area.size.x, 40.0, area.size.y))
		add_child(layer)
	for index: int in _whale_sites.size():
		var spout := _spout()
		add_child(spout)
		_spouts.append(spout)
		_surfaced.append(false)
	_place()


func whale_count() -> int:
	return _whale_sites.size()


func pod_count() -> int:
	return _pod_sites.size()


func whale_site(index: int) -> Vector3:
	return _whale_sites[index]


func pod_site(index: int) -> Vector3:
	return _pod_sites[index]


func time() -> float:
	return _time


## Anda o relógio à mão (testes e capturas com o jogo pausado).
func advance(seconds: float) -> void:
	_time += seconds
	_place()


## O lugar de agora da baleia e do golfinho (testes e capturas).
func whale_transform(index: int) -> Transform3D:
	return _whales.multimesh.get_instance_transform(index)


func dolphin_transform(index: int) -> Transform3D:
	return _dolphins.multimesh.get_instance_transform(index)


func spouting(index: int) -> bool:
	return _spouts[index].emitting


func _process(delta: float) -> void:
	_time += delta * GameClock.clock.speed_multiplier()
	_place()


func _place() -> void:
	for index: int in _whale_sites.size():
		var pose := whale_pose(_whale_sites[index], index, _time)
		_whales.multimesh.set_instance_transform(index, pose)
		# o esguicho sai uma vez a cada subida, no alto da cabeça
		var up := fposmod(_time + index * WHALE_CYCLE_S / WHALES, WHALE_CYCLE_S) < WHALE_SURFACE_S
		if up and not _surfaced[index]:
			_spouts[index].position = pose * Vector3(0.0, 1.2, WHALE_LENGTH_M * 0.3)
			_spouts[index].restart()
		_surfaced[index] = up
	for pod: int in _pod_sites.size():
		for k: int in DOLPHINS_PER_POD:
			_dolphins.multimesh.set_instance_transform(pod * DOLPHINS_PER_POD + k, dolphin_pose(_pod_sites[pod], pod, k, _time))


## Pose da baleia index (lugar site) no tempo dado: dá a volta no círculo e, no começo de cada ciclo, sobe (dorso fora
## d'água), mergulha inclinando o nariz e erguendo a cauda, e some no fundo o resto do ciclo. A malha olha para +z.
static func whale_pose(site: Vector3, index: int, time: float) -> Transform3D:
	var angle := (time * WHALE_SPEED_M_S / WHALE_CIRCLE_M) + index * TAU / WHALES
	var position := site + Vector3(cos(angle), 0.0, sin(angle)) * WHALE_CIRCLE_M
	# tangente da volta (sentido anti-horário visto de cima): para onde ela nada
	var heading := Vector3(-sin(angle), 0.0, cos(angle))
	var phase := fposmod(time + index * WHALE_CYCLE_S / WHALES, WHALE_CYCLE_S)
	var pitch := 0.0
	if phase < WHALE_SURFACE_S:
		position.y = WHALE_SURFACE_Y + 0.15 * sin(phase * 1.3)
	elif phase < WHALE_SURFACE_S + WHALE_DIVE_S:
		var t := (phase - WHALE_SURFACE_S) / WHALE_DIVE_S
		# o nariz desce e a cauda sobe: gira em volta da cabeça, que afunda
		pitch = lerpf(0.0, 0.75, t)
		position.y = lerpf(WHALE_SURFACE_Y, WHALE_SURFACE_Y - 3.0, t)
	else:
		return HIDDEN
	var level := Basis.looking_at(-heading, Vector3.UP)
	var basis := level * Basis(Vector3.RIGHT, pitch)
	# o giro do mergulho é em volta da cabeça (fica onde estava): o nariz desce e a cauda (em -z) sobe
	var head := Vector3(0.0, 0.0, WHALE_LENGTH_M * 0.35)
	return Transform3D(basis, position + level * head - basis * head)


## Pose do golfinho k do bando pod no tempo dado: o bando dá a volta e cada um salta em arco na sua vez (no resto do
## ciclo, fundo d'água). A malha olha para +z; no salto ela aponta para onde vai (sobe e desce).
static func dolphin_pose(site: Vector3, pod: int, k: int, time: float) -> Transform3D:
	var angle := (time * DOLPHIN_SPEED_M_S / DOLPHIN_CIRCLE_M) + pod * 2.1
	var heading := Vector3(-sin(angle), 0.0, cos(angle))
	var side := Vector3(cos(angle), 0.0, sin(angle))
	var position := site + side * (DOLPHIN_CIRCLE_M + (k - DOLPHINS_PER_POD * 0.5) * 2.5) + heading * (k % 2) * 3.0
	var phase := fposmod(time - k * 0.55 + pod * 1.3, DOLPHIN_CYCLE_S)
	if phase >= DOLPHIN_JUMP_S:
		return HIDDEN
	var t := phase / DOLPHIN_JUMP_S
	# arco: sai d'água, sobe DOLPHIN_JUMP_M e volta; a inclinação segue a derivada do arco
	position.y = DOLPHIN_JUMP_M * 4.0 * t * (1.0 - t) - 0.3
	var rise := DOLPHIN_JUMP_M * 4.0 * (1.0 - 2.0 * t) / (DOLPHIN_SPEED_M_S * DOLPHIN_JUMP_S)
	var pitch := -atan(rise)
	var basis := Basis.looking_at(-heading, Vector3.UP) * Basis(Vector3.RIGHT, pitch)
	return Transform3D(basis, position)


## count lugares (y = 0) dentro da área com a distância até a costa entre low e high (m), sorteados pela semente, longe
## um do outro (pelo menos 1/4 da diagonal da área dividida pelo número); menos se a área não tem água assim.
static func sites(coast: CoastField, area: Rect2, count: int, low: float, high: float, seed_value: int) -> Array[Vector3]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var result: Array[Vector3] = []
	var spacing := area.size.length() * 0.25 / maxf(count, 1)
	for attempt: int in 400:
		if result.size() >= count:
			break
		var point := Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y))
		var distance := coast.at(point.x, point.y)
		if distance < low or distance > high:
			continue
		var close := false
		for other: Vector3 in result:
			if Vector2(other.x, other.z).distance_to(point) < spacing:
				close = true
				break
		if not close:
			result.append(Vector3(point.x, 0.0, point.y))
	return result


## Esguicho da baleia: névoa branca de uma vez, que sobe e se abre.
static func _spout() -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.amount = 24
	particles.lifetime = 2.5
	particles.one_shot = true
	particles.explosiveness = 0.7
	particles.emitting = false
	particles.visibility_aabb = AABB(Vector3(-6, -1, -6), Vector3(12, 14, 12))
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 10.0
	process.initial_velocity_min = 5.0
	process.initial_velocity_max = 7.5
	process.gravity = Vector3(0.0, -2.5, 0.0)
	process.scale_min = 0.6
	process.scale_max = 1.1
	var growth := Curve.new()
	growth.add_point(Vector2(0.0, 0.5))
	growth.add_point(Vector2(1.0, 2.4))
	var scale_curve := CurveTexture.new()
	scale_curve.curve = growth
	process.scale_curve = scale_curve
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 1.0, 1.0, 0.8))
	fade.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	process.color_ramp = ramp
	particles.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(1.4, 1.4)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = SmokeView._puff_texture()
	quad.material = material
	particles.draw_pass_1 = quad
	return particles


## Baleia de WHALE_LENGTH_M, olhando para +z: corpo de seção oval que afina para a cauda, barriga clara e a cauda em
## duas aletas horizontais.
static func whale_mesh() -> ArrayMesh:
	return _body(WHALE_LENGTH_M, Vector2(1.7, 1.5), WHALE_COLOR, WHALE_BELLY, 4.2, 0.0)


## Golfinho de DOLPHIN_LENGTH_M: corpo fino com bico, barriga clara, nadadeira dorsal e a cauda.
static func dolphin_mesh() -> ArrayMesh:
	return _body(DOLPHIN_LENGTH_M, Vector2(0.28, 0.3), DOLPHIN_COLOR, DOLPHIN_BELLY, 0.7, 0.32)


## Corpo de bicho do mar: anéis ao longo de z (de -length/2 na cauda a +length/2 no nariz) com o raio pelo perfil, a cor
## de cima no dorso e a da barriga embaixo; aletas da cauda de envergadura fluke_span e nadadeira dorsal de fin_m (0 sem).
static func _body(length: float, radius: Vector2, back: Color, belly: Color, fluke_span: float, fin_m: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 12
	var sides := 10
	var points: Array[PackedVector3Array] = []
	for r: int in rings + 1:
		var t := float(r) / rings
		# cauda fina (t = 0), mais gordo a 60%, nariz arredondado (t = 1)
		var profile := pow(sin(PI * clampf(t * 0.92 + 0.04, 0.0, 1.0)), 0.7) * (0.25 + 0.75 * smoothstep(0.0, 0.55, t))
		var ring := PackedVector3Array()
		for s: int in sides:
			var a := TAU * s / sides
			ring.append(Vector3(cos(a) * radius.x * profile, sin(a) * radius.y * profile, lerpf(-0.5, 0.5, t) * length))
		points.append(ring)
	for r: int in rings:
		for s: int in sides:
			var quad := [points[r][s], points[r + 1][s], points[r + 1][(s + 1) % sides], points[r][(s + 1) % sides]]
			for corner: int in [0, 1, 2, 0, 2, 3]:
				var p: Vector3 = quad[corner]
				var normal := Vector3(p.x / maxf(radius.x, 0.01), p.y / maxf(radius.y, 0.01), 0.0).normalized()
				tool.set_normal(normal)
				tool.set_color(belly if p.y < -radius.y * 0.15 else back)
				tool.add_vertex(p)
	# aletas da cauda: um triângulo para cada lado, horizontal, um pouco atrás da ponta
	var tail := Vector3(0.0, 0.0, -0.5 * length)
	for side: float in [-1.0, 1.0]:
		var tri := [tail, tail + Vector3(side * fluke_span * 0.5, 0.0, -fluke_span * 0.28), tail + Vector3(side * fluke_span * 0.12, 0.0, fluke_span * 0.18)]
		for p: Vector3 in tri:
			tool.set_normal(Vector3.UP)
			tool.set_color(back)
			tool.add_vertex(p)
	if fin_m > 0.0:
		var base := Vector3(0.0, radius.y * 0.85, 0.0)
		var fin := [base + Vector3(0.0, 0.0, length * 0.12), base + Vector3(0.0, fin_m, -length * 0.06), base + Vector3(0.0, 0.0, -length * 0.1)]
		for p: Vector3 in fin:
			tool.set_normal(Vector3.RIGHT)
			tool.set_color(back)
			tool.add_vertex(p)
	return tool.commit()
