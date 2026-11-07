class_name RainbowView
extends Node3D
## Fase 188: o arco-íris. Quando a chuva de um dia chuvoso passa (de pouco antes do fim dela até AFTER_RAIN_H horas depois,
## `amount_at`), de dia e com o sol baixo o bastante para o arco ficar acima do horizonte, um anel de RAINBOW_DEG graus em
## volta do ponto oposto ao sol, posto a DISTANCE_M da câmera a cada quadro (`ring_mesh`, `place`), desenhado pelo
## `shaders/rainbow.gdshader` (somado, sem profundidade, cortado no mar). Só visual; nada no save.

const RAINBOW_DEG := 42.0
const BAND := 0.08
const DISTANCE_M := 900.0
const SEGMENTS := 96
## Quanto antes do fim da chuva ele começa a aparecer e quanto tempo depois ele dura (horas).
const BEFORE_END_H := 0.25
const AFTER_RAIN_H := 1.4

var _simulation: Simulation
var _sky: SkyAdapter
var _ring := MeshInstance3D.new()
var _material := ShaderMaterial.new()
## Quanto o arco aparece agora (testes e capturas).
var amount := 0.0
## Horas totais a usar no lugar do relógio (capturas); negativo segue o relógio.
var hours_override := -1.0


func setup(simulation: Simulation, sky: SkyAdapter) -> void:
	_simulation = simulation
	_sky = sky
	_material.shader = load("res://shaders/rainbow.gdshader") as Shader
	_ring.name = "Rainbow"
	_ring.mesh = ring_mesh()
	_ring.material_override = _material
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.visible = false
	add_child(_ring)


func _process(_delta: float) -> void:
	if _simulation == null:
		return
	var hours := hours_override if hours_override >= 0.0 else GameClock.clock.total_hours()
	var daylight := 1.0 - DayClock.night_factor(_simulation.config, fposmod(hours, 24.0))
	amount = amount_at(_simulation.world.seed, hours, _simulation.config) * daylight
	var camera := get_viewport().get_camera_3d()
	var sun := _sky.sun() if _sky != null else null
	if amount <= 0.01 or camera == null or sun == null or not sun.is_inside_tree():
		_ring.visible = false
		return
	var toward_sun := sun.global_basis.z.normalized()
	var found: Variant = place(camera.global_position, toward_sun)
	if found == null:
		_ring.visible = false
		return
	_ring.visible = true
	_ring.global_transform = found
	_material.set_shader_parameter(&"amount", amount)


## Quanto o arco-íris aparece (0 a 1) nas horas totais dadas: só no dia de chuva, subindo um pouco antes do fim dela e
## sumindo AFTER_RAIN_H horas depois.
static func amount_at(seed_value: int, total_hours: float, config: GameConfig) -> float:
	var index := floori(total_hours / 24.0)
	var today := WeatherCycle.day(seed_value, index, config)
	if today.kind != WeatherCycle.Kind.RAIN:
		return 0.0
	var since := total_hours - index * 24.0 - today.rain_end
	return smoothstep(-BEFORE_END_H, 0.1, since) * (1.0 - smoothstep(AFTER_RAIN_H * 0.6, AFTER_RAIN_H, since))


## Onde o anel fica (mundo): em volta do ponto oposto ao sol, a DISTANCE_M do olho, do tamanho de RAINBOW_DEG graus; null
## com o sol abaixo do horizonte ou alto demais (o arco todo abaixo dele).
static func place(eye: Vector3, toward_sun: Vector3) -> Variant:
	var elevation := rad_to_deg(asin(clampf(toward_sun.y, -1.0, 1.0)))
	if elevation <= 0.0 or elevation >= RAINBOW_DEG - 2.0:
		return null
	var away := -toward_sun
	var side := away.cross(Vector3.UP).normalized()
	var up := side.cross(away).normalized()
	var radius := DISTANCE_M * tan(deg_to_rad(RAINBOW_DEG))
	return Transform3D(Basis(side * radius, up * radius, away * radius), eye + away * DISTANCE_M)


## O anel de raio 1 no plano xy, da borda de dentro (UV.y = 0) à de fora (UV.y = 1), BAND de largura.
static func ring_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k: int in SEGMENTS:
		var a0 := TAU * k / SEGMENTS
		var a1 := TAU * (k + 1) / SEGMENTS
		var inner0 := Vector3(cos(a0), sin(a0), 0.0) * (1.0 - BAND * 0.5)
		var outer0 := Vector3(cos(a0), sin(a0), 0.0) * (1.0 + BAND * 0.5)
		var inner1 := Vector3(cos(a1), sin(a1), 0.0) * (1.0 - BAND * 0.5)
		var outer1 := Vector3(cos(a1), sin(a1), 0.0) * (1.0 + BAND * 0.5)
		for corner: Array in [[inner0, 0.0], [outer0, 1.0], [outer1, 1.0], [inner0, 0.0], [outer1, 1.0], [inner1, 0.0]]:
			var point: Vector3 = corner[0]
			var band: float = corner[1]
			tool.set_uv(Vector2(float(k) / SEGMENTS, band))
			tool.add_vertex(point)
	return tool.commit()
