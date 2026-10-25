class_name CameraRig
extends RefCounted
## As contas da câmera de estratégia, sem nó: foco no chão, giro, distância e inclinação.
## Yaw 0 põe a câmera em +Z do foco olhando para −Z. A inclinação sai do zoom: perto fica
## mais horizontal (ruas), longe mais vertical (visão geral).

## Velocidade do pan escolhida nas opções (Fase 10), multiplicando a do GameConfig.
var pan_speed_scale: float = 1.0
var focus: Vector3 = Vector3.ZERO
var yaw: float = 0.0
var target_yaw: float = 0.0
var distance: float
## Distância aonde o zoom suave da roda vai (Fase 31); só vale enquanto is_zooming().
var target_distance: float

## Altura do chão sob o foco (o foco fica no plano y = 0; a câmera sobe com o relevo). Suavizada.
var ground_height: float = 0.0
var _config: GameConfig
var _bounds: Rect2
var _center_target: Vector3
var _centering: bool = false
var _zooming: bool = false


## bounds_m é a área da ilha em metros no plano XZ (x = X, y = Z).
func _init(config: GameConfig, bounds_m: Rect2) -> void:
	_config = config
	_bounds = bounds_m.grow(config.camera_bounds_margin_m)
	distance = config.camera_start_distance_m
	target_distance = distance
	focus = Vector3(bounds_m.get_center().x, 0.0, bounds_m.get_center().y)


## Ângulo abaixo do horizonte, em radianos.
func pitch() -> float:
	var t := inverse_lerp(_config.camera_min_distance_m, _config.camera_max_distance_m, distance)
	return deg_to_rad(lerpf(_config.camera_pitch_near_deg, _config.camera_pitch_far_deg, clampf(t, 0.0, 1.0)))


## Ponto para onde a câmera olha: o foco na altura do chão.
func look_target() -> Vector3:
	return focus + Vector3(0.0, ground_height, 0.0)


func camera_position() -> Vector3:
	var p := pitch()
	var offset := Vector3(sin(yaw) * cos(p), sin(p), cos(yaw) * cos(p)) * distance
	var position := look_target() + offset
	position.y = maxf(position.y, ground_height + _config.camera_min_height_m)
	return position


func camera_transform() -> Transform3D:
	var position := camera_position()
	return Transform3D(Basis.IDENTITY, position).looking_at(look_target(), Vector3.UP)


## Acompanha a altura do chão sob o foco, sem pulo nas encostas.
func follow_ground(height: float, delta: float) -> void:
	ground_height = lerpf(ground_height, height, 1.0 - exp(-delta / 0.2))


## Troca a área que a câmera alcança (o arquipélago inteiro, com folga).
func set_bounds(bounds_m: Rect2) -> void:
	_bounds = bounds_m.grow(_config.camera_bounds_margin_m)
	focus = _clamped(focus)


## Frente e direita no chão, relativas ao giro atual.
func ground_forward() -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


func ground_right() -> Vector3:
	return Vector3(cos(yaw), 0.0, -sin(yaw))


## input.x = direita, input.y = frente; a velocidade acompanha a distância (o zoom).
func pan(input: Vector2, delta: float) -> void:
	if input == Vector2.ZERO:
		return
	_centering = false
	var step := (ground_right() * input.x + ground_forward() * input.y) * _config.camera_pan_speed * pan_speed_scale * distance * delta
	shift_focus(step)


func shift_focus(offset: Vector3) -> void:
	focus = _clamped(focus + Vector3(offset.x, 0.0, offset.z))


## steps > 0 aproxima, < 0 afasta.
func zoom(steps: float) -> void:
	var factor := pow(1.0 - _config.camera_zoom_step, steps)
	distance = clampf(distance * factor, _config.camera_min_distance_m, _config.camera_max_distance_m)
	target_distance = distance
	_zooming = false


## Zoom suave (Fase 31): o alvo anda o passo, e ease_zoom leva a distância até ele. Toques seguidos somam no alvo.
func zoom_toward(steps: float) -> void:
	var start := target_distance if _zooming else distance
	var factor := pow(1.0 - _config.camera_zoom_step, steps)
	target_distance = clampf(start * factor, _config.camera_min_distance_m, _config.camera_max_distance_m)
	_zooming = target_distance != distance


func is_zooming() -> bool:
	return _zooming


## Aproxima a distância do alvo do zoom suave; termina exatamente nele.
func ease_zoom(delta: float) -> void:
	if not _zooming:
		return
	distance = lerpf(distance, target_distance, 1.0 - exp(-delta / _config.camera_zoom_seconds))
	if absf(distance - target_distance) < target_distance * 0.001:
		distance = target_distance
		_zooming = false


## Q/E: gira 90° a partir de onde o giro vai parar, para toques seguidos somarem.
func rotate_quarter(direction: int) -> void:
	target_yaw += direction * PI / 2.0


func rotate_free(pixels: float) -> void:
	yaw += deg_to_rad(pixels * _config.camera_free_rotate_deg_per_px)
	target_yaw = yaw


func center_on(point: Vector3) -> void:
	_center_target = _clamped(Vector3(point.x, 0.0, point.z))
	_centering = true


func is_rotating() -> bool:
	return yaw != target_yaw


## Anima o giro do Q/E (velocidade constante, termina exatamente alinhado) e a centralização.
func update(delta: float) -> void:
	if yaw != target_yaw:
		var speed := (PI / 2.0) / _config.camera_rotate_seconds
		yaw = move_toward(yaw, target_yaw, speed * delta)
	if _centering:
		var weight := 1.0 - exp(-delta / _config.camera_center_seconds)
		focus = focus.lerp(_center_target, weight)
		if focus.distance_to(_center_target) < 0.05:
			focus = _center_target
			_centering = false


func _clamped(point: Vector3) -> Vector3:
	return Vector3(
		clampf(point.x, _bounds.position.x, _bounds.end.x),
		0.0,
		clampf(point.z, _bounds.position.y, _bounds.end.y))


func to_dict() -> Dictionary:
	return {"focus": focus, "yaw": target_yaw, "distance": distance}


func load_dict(data: Dictionary) -> void:
	var raw_focus: Variant = data.get("focus")
	var raw_yaw: Variant = data.get("yaw")
	var raw_distance: Variant = data.get("distance")
	if raw_focus is Vector3:
		var saved_focus: Vector3 = raw_focus
		focus = _clamped(saved_focus)
	if raw_yaw is float:
		var saved_yaw: float = raw_yaw
		yaw = saved_yaw
		target_yaw = saved_yaw
	if raw_distance is float:
		var saved_distance: float = raw_distance
		distance = clampf(saved_distance, _config.camera_min_distance_m, _config.camera_max_distance_m)
	target_distance = distance
	_centering = false
	_zooming = false
