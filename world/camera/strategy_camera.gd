class_name StrategyCamera
extends Node3D
## Câmera de estratégia (seção 10): pan por WASD, setas, botão do meio e borda da tela;
## Q/E giram 90°; botão direito gira livre; roda faz zoom no cursor. As contas ficam no
## CameraRig; aqui só entrada e o Camera3D.

## Distância mínima do mouse (px) para o botão direito virar giro em vez de clique.
const DRAG_THRESHOLD_PX := 4.0

## Altura entre o mar e o chão sobre o chão: o raio do clique para no relevo e no mar.
const RAY_TOP_M := 40.0
const RAY_BOTTOM_M := -1.0
const RAY_STEP_M := 1.5

var rig: CameraRig
var camera: Camera3D
## Altura do chão num ponto (x, z) do mundo: Callable(float, float) -> float. Sem ela, chão plano.
var height_at := Callable()

var _middle_anchor: Vector3
var _middle_dragging: bool = false
var _right_pressed: bool = false
var _right_travel: float = 0.0
## Ponto da tela que o zoom suave mantém parado sobre o chão (Fase 31).
var _zoom_anchor: Vector2
## Fase 48: o pan pela borda só vale depois de um movimento de verdade do mouse na janela. Sem ele (janela recém-aberta
## com o mouse em outro lugar, o xvfb do CI, a área de trabalho escondida das medidas) a posição do mouse lida pelo
## motor pode ser um canto, e a câmera saía andando sozinha.
var mouse_seen: bool = false


func setup(config: GameConfig, bounds_m: Rect2) -> void:
	rig = CameraRig.new(config, bounds_m)
	camera = Camera3D.new()
	camera.fov = 45.0
	camera.near = 0.5
	camera.far = 4000.0
	add_child(camera)
	apply()


func apply() -> void:
	camera.global_transform = rig.camera_transform()


## Ponto do chão sob a posição de tela, ou null se o raio não toca o chão. Com relevo, o raio anda
## em passos até ficar abaixo do terreno e acha o ponto por bisseção.
func ground_point(screen_position: Vector2) -> Variant:
	var origin := camera.project_ray_origin(screen_position)
	var normal := camera.project_ray_normal(screen_position)
	if not height_at.is_valid():
		return Plane(Vector3.UP, 0.0).intersects_ray(origin, normal)
	return march(origin, normal, height_at)


static func march(origin: Vector3, direction: Vector3, height: Callable) -> Variant:
	if direction.y >= -0.0001:
		return null
	var t := maxf(0.0, (origin.y - RAY_TOP_M) / -direction.y)
	var t_end := (origin.y - RAY_BOTTOM_M) / -direction.y
	var previous := t
	while t <= t_end:
		var point := origin + direction * t
		var ground: float = height.call(point.x, point.z)
		if point.y <= ground:
			var low := previous
			var high := t
			for i: int in 10:
				var middle := (low + high) * 0.5
				var probe := origin + direction * middle
				var probe_ground: float = height.call(probe.x, probe.z)
				if probe.y <= probe_ground:
					high = middle
				else:
					low = middle
			return origin + direction * high
		previous = t
		t += RAY_STEP_M
	return origin + direction * t_end


func _process(delta: float) -> void:
	rig.pan_speed_scale = Settings.camera_speed
	var input := Input.get_vector(&"camera_pan_left", &"camera_pan_right", &"camera_pan_back", &"camera_pan_forward")
	if Settings.edge_pan and input == Vector2.ZERO:
		input = _edge_input()
	rig.pan(input, delta)
	rig.update(delta)
	if rig.is_zooming():
		_keep_under(_zoom_anchor, func() -> void: rig.ease_zoom(delta))
	if height_at.is_valid():
		var ground: float = height_at.call(rig.focus.x, rig.focus.z)
		rig.follow_ground(ground, delta)
	apply()


func _edge_input() -> Vector2:
	var viewport := get_viewport()
	if not mouse_seen or not viewport.get_window().has_focus():
		return Vector2.ZERO
	var mouse := viewport.get_mouse_position()
	var size := viewport.get_visible_rect().size
	if not Rect2(Vector2.ZERO, size).has_point(mouse):
		return Vector2.ZERO
	var margin := float(GameConfig.get_default().camera_edge_margin_px)
	var input := Vector2.ZERO
	if mouse.x <= margin:
		input.x = -1.0
	elif mouse.x >= size.x - margin:
		input.x = 1.0
	if mouse.y <= margin:
		input.y = 1.0
	elif mouse.y >= size.y - margin:
		input.y = -1.0
	return input


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_seen = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"camera_rotate_left"):
		rig.rotate_quarter(-1)
	elif event.is_action_pressed(&"camera_rotate_right"):
		rig.rotate_quarter(1)
	elif event is InputEventMouseButton:
		var button: InputEventMouseButton = event
		_on_mouse_button(button)
	elif event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event
		_on_mouse_motion(motion)


func _on_mouse_button(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			if event.pressed:
				_zoom_at(event.position, event.factor if event.factor > 0.0 else 1.0)
		MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				_zoom_at(event.position, -(event.factor if event.factor > 0.0 else 1.0))
		MOUSE_BUTTON_MIDDLE:
			var anchor: Variant = ground_point(event.position)
			_middle_dragging = event.pressed and anchor is Vector3
			if _middle_dragging:
				_middle_anchor = anchor
		MOUSE_BUTTON_RIGHT:
			_right_pressed = event.pressed
			if event.pressed:
				_right_travel = 0.0
			elif _right_travel >= DRAG_THRESHOLD_PX:
				get_viewport().set_input_as_handled()


func _on_mouse_motion(event: InputEventMouseMotion) -> void:
	if _middle_dragging:
		var under: Variant = ground_point(event.position)
		if under is Vector3:
			var point: Vector3 = under
			rig.shift_focus(_middle_anchor - point)
			apply()
	if _right_pressed:
		_right_travel += absf(event.relative.x)
		if _right_travel >= DRAG_THRESHOLD_PX:
			rig.rotate_free(event.relative.x)
			apply()


## Zoom no cursor: o ponto do chão sob o mouse continua sob o mouse depois do zoom. Desde a Fase 31 a distância vai
## até o alvo em camera_zoom_seconds, mantendo o ponto quadro a quadro; direto sem tela (testes) e, desde a Fase 43, com
## "reduzir movimento" (SceneFader.still()).
func _zoom_at(screen_position: Vector2, steps: float) -> void:
	if not SceneFader.still():
		_zoom_anchor = screen_position
		rig.zoom_toward(steps)
		return
	_keep_under(screen_position, func() -> void: rig.zoom(steps))


## Faz a mudança de distância em "change" e desloca o foco para o ponto do chão sob "screen_position" ficar lá.
func _keep_under(screen_position: Vector2, change: Callable) -> void:
	var before: Variant = ground_point(screen_position)
	change.call()
	apply()
	var after: Variant = ground_point(screen_position)
	if before is Vector3 and after is Vector3:
		var before_point: Vector3 = before
		var after_point: Vector3 = after
		rig.shift_focus(before_point - after_point)
		apply()


func right_button_dragged() -> bool:
	return _right_travel >= DRAG_THRESHOLD_PX
