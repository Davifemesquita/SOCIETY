class_name StrategyCamera
extends Node3D
## Câmera de estratégia (seção 10): pan por WASD, setas, botão do meio e borda da tela;
## Q/E giram 90°; botão direito gira livre; roda faz zoom no cursor. As contas ficam no
## CameraRig; aqui só entrada e o Camera3D.

## Distância mínima do mouse (px) para o botão direito virar giro em vez de clique.
const DRAG_THRESHOLD_PX := 4.0

var rig: CameraRig
var camera: Camera3D

var _middle_anchor: Vector3
var _middle_dragging: bool = false
var _right_pressed: bool = false
var _right_travel: float = 0.0


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


## Ponto do chão (y = 0) sob a posição de tela, ou null se o raio não toca o chão.
func ground_point(screen_position: Vector2) -> Variant:
	var origin := camera.project_ray_origin(screen_position)
	var normal := camera.project_ray_normal(screen_position)
	return Plane(Vector3.UP, 0.0).intersects_ray(origin, normal)


func _process(delta: float) -> void:
	var input := Input.get_vector(&"camera_pan_left", &"camera_pan_right", &"camera_pan_back", &"camera_pan_forward")
	if Settings.edge_pan and input == Vector2.ZERO:
		input = _edge_input()
	rig.pan(input, delta)
	rig.update(delta)
	apply()


func _edge_input() -> Vector2:
	var viewport := get_viewport()
	if not viewport.get_window().has_focus():
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


## Zoom no cursor: o ponto do chão sob o mouse continua sob o mouse depois do zoom.
func _zoom_at(screen_position: Vector2, steps: float) -> void:
	var before: Variant = ground_point(screen_position)
	rig.zoom(steps)
	apply()
	var after: Variant = ground_point(screen_position)
	if before is Vector3 and after is Vector3:
		var before_point: Vector3 = before
		var after_point: Vector3 = after
		rig.shift_focus(before_point - after_point)
		apply()


func right_button_dragged() -> bool:
	return _right_travel >= DRAG_THRESHOLD_PX
