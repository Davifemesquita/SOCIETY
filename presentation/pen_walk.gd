class_name PenWalk
extends RefCounted
## Fase 75: o passeio de um bicho dentro do cercado do zoológico. Descansa, escolhe um ponto, vira para ele no lugar e
## anda até lá; toda pose (o alvo, o giro e o caminho) é conferida pelo retângulo do corpo (a pegada, de frente para -Z)
## contra a cerca, então nada atravessa a cerca. Sem pose que caiba, fica parado. Só apresentação: a sorte vem da
## semente (o prédio e a vaga), fora da simulação.

const WALK_M_S := 0.55
const TURN_RAD_S := 1.1
const REST_MIN_S := 2.5
const REST_MAX_S := 7.0
## Folga até a cerca (mourões de 0,12 m).
const FENCE_GAP_M := 0.1
const TRIES := 32
const TURN_CHECK_RAD := 0.05
const TURN_SLACK_M := 0.01
## O ponto sorteado fica nesta parte do cercado (perto da cerca quase nada cabe).
const AIM_SHARE := 0.7
## O bicho cabe com folga para virar: o corpo (o lado maior da pegada) ocupa no máximo esta parte do lado menor do
## cercado; o maior que isso fica menor no cercado (fit_scale).
const FIT_SHARE := 0.72

enum Step { REST, TURN, WALK }

## Meia largura e meia profundidade do cercado, por dentro.
var half: Vector2
## A pegada do corpo com o bicho de frente para -Z (x e z no plano, origem no meio da malha).
var footprint: Rect2
## Onde está (no cercado, a partir do meio) e para onde olha (0 = -Z).
var position := Vector2.ZERO
var heading: float = 0.0
## Fase 77: o retângulo no chão do cercado que o corpo não pode tocar (o bebedouro); vazio = nenhum.
var blocked := Rect2()
## Sem nenhuma pose que caiba: não anda.
var still: bool = false
var step := Step.REST
var _left: float = 0.0
var _target := Vector2.ZERO
var _target_heading: float = 0.0
var _rng := RandomNumberGenerator.new()


func _init(pen_half: Vector2, body: Rect2, seed_value: int, start_heading: float, obstacle: Rect2 = Rect2()) -> void:
	half = pen_half
	footprint = body
	blocked = obstacle
	_rng.seed = seed_value
	heading = start_heading
	# começa no meio, com a pegada centrada; senão, a primeira pose sorteada que couber
	position = -_rotated(footprint.get_center(), heading)
	if not fits(position, heading):
		still = true
		for k: int in TRIES * 4:
			var try_heading := _rng.randf() * TAU
			var try_position := _random_point()
			if fits(try_position, try_heading):
				position = try_position
				heading = try_heading
				still = false
				break
		if still:
			position = Vector2.ZERO
			heading = start_heading
	_left = _rng.randf_range(0.0, REST_MAX_S)


## Os quatro cantos da pegada com o bicho em "at" olhando para "facing".
func corners(at: Vector2, facing: float) -> Array[Vector2]:
	var found: Array[Vector2] = []
	for corner: Vector2 in [footprint.position, Vector2(footprint.end.x, footprint.position.y), footprint.end,
			Vector2(footprint.position.x, footprint.end.y)]:
		found.append(at + _rotated(corner, facing))
	return found


## A pegada inteira dentro da cerca, a "gap" dela, e sem tocar o bebedouro (com a mesma folga).
func fits(at: Vector2, facing: float, gap: float = FENCE_GAP_M) -> bool:
	var limit := half - Vector2(gap, gap)
	var found := corners(at, facing)
	for corner: Vector2 in found:
		if absf(corner.x) > limit.x or absf(corner.y) > limit.y:
			return false
	return _clear(found, _axes(facing), gap)


## Fase 77: o caminho reto de "from" até "to" olhando para "facing" não passa pelo bebedouro. O que o corpo varre andando
## é o fecho convexo dos cantos de saída e de chegada; o teste dos eixos separadores usa os lados do corpo, os do
## bebedouro e o lado paralelo ao caminho.
func path_clear(from: Vector2, to: Vector2, facing: float) -> bool:
	var swept := corners(from, facing) + corners(to, facing)
	var axes := _axes(facing)
	axes.append((to - from).orthogonal())
	return _clear(swept, axes, FENCE_GAP_M)


## Os pontos (um corpo convexo) não tocam o bebedouro crescido de "gap": separados em algum dos eixos (os do bebedouro e
## os dados).
func _clear(points: Array[Vector2], axes: Array[Vector2], gap: float) -> bool:
	if not blocked.has_area():
		return true
	var box := blocked.grow(gap)
	var box_corners: Array[Vector2] = [box.position, Vector2(box.end.x, box.position.y), box.end,
			Vector2(box.position.x, box.end.y)]
	var all_axes: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN]
	all_axes.append_array(axes)
	for axis: Vector2 in all_axes:
		if axis.is_zero_approx():
			continue
		var mine := _span(points, axis)
		var theirs := _span(box_corners, axis)
		if mine.y < theirs.x or theirs.y < mine.x:
			return true
	return false


## Os dois lados do corpo olhando para "facing".
static func _axes(facing: float) -> Array[Vector2]:
	return [_rotated(Vector2.RIGHT, facing), _rotated(Vector2.DOWN, facing)]


## Onde os pontos caem projetados em "axis": (menor, maior).
static func _span(points: Array[Vector2], axis: Vector2) -> Vector2:
	var low := INF
	var high := -INF
	for point: Vector2 in points:
		var at := point.dot(axis)
		low = minf(low, at)
		high = maxf(high, at)
	return Vector2(low, high)


func advance(seconds: float) -> void:
	if still:
		return
	var left := seconds
	while left > 0.0:
		match step:
			Step.REST:
				var used := minf(left, _left)
				_left -= used
				left -= used
				if _left <= 0.0:
					_choose()
			Step.TURN:
				var turn := angle_difference(heading, _target_heading)
				var used := minf(left, absf(turn) / TURN_RAD_S)
				heading += signf(turn) * used * TURN_RAD_S
				left -= used
				if is_zero_approx(angle_difference(heading, _target_heading)) or used >= absf(turn) / TURN_RAD_S:
					heading = _target_heading
					step = Step.WALK
			Step.WALK:
				var gap := _target - position
				var used := minf(left, gap.length() / WALK_M_S)
				position += gap.limit_length(used * WALK_M_S)
				left -= used
				if position.distance_to(_target) < 0.001:
					position = _target
					_rest()


## O próximo ponto: o primeiro sorteado em que o alvo, o giro no lugar e (pela pegada convexa) o caminho reto cabem.
func _choose() -> void:
	for k: int in TRIES:
		var target := _random_point()
		var gap := target - position
		if gap.length() < 0.3:
			continue
		var facing := atan2(-gap.x, -gap.y)
		if fits(target, facing) and _turn_fits(facing) and path_clear(position, target, facing):
			_target = target
			_target_heading = facing
			step = Step.TURN
			return
	# sem caminho que caiba: só vira no lugar (pastando), se der
	for k: int in TRIES:
		var facing := heading + _rng.randf_range(-PI, PI)
		if _turn_fits(facing):
			_target = position
			_target_heading = facing
			step = Step.TURN
			return
	_rest()


## O giro no lugar até "facing" cabe: conferido a cada TURN_CHECK_RAD com folga a mais (o canto entre duas conferidas
## sai da corda bem menos que ela).
func _turn_fits(facing: float) -> bool:
	var turn := angle_difference(heading, facing)
	var checks := maxi(1, ceili(absf(turn) / TURN_CHECK_RAD))
	for k: int in range(1, checks + 1):
		if not fits(position, heading + turn * k / checks, FENCE_GAP_M + TURN_SLACK_M):
			return false
	return true


func _rest() -> void:
	step = Step.REST
	_left = _rng.randf_range(REST_MIN_S, REST_MAX_S)


func _random_point() -> Vector2:
	var aim := half * AIM_SHARE
	return Vector2(_rng.randf_range(-aim.x, aim.x), _rng.randf_range(-aim.y, aim.y))


## A escala do bicho no cercado: 1 se ele cabe com folga, menor se o corpo passa de FIT_SHARE do lado menor do cercado.
static func fit_scale(pen_half: Vector2, body: Rect2) -> float:
	var room := (minf(pen_half.x, pen_half.y) - FENCE_GAP_M) * 2.0 * FIT_SHARE
	return minf(1.0, room / maxf(body.size.x, body.size.y))


## "point" girado como o bicho que olha para "facing" (o mesmo giro de Basis(UP, facing) no plano x-z).
static func _rotated(point: Vector2, facing: float) -> Vector2:
	var turned := Basis(Vector3.UP, facing) * Vector3(point.x, 0.0, point.y)
	return Vector2(turned.x, turned.z)
