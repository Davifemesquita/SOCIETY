extends GdUnitTestSuite
## Contas da câmera: inclinação pelo zoom, limites, movimento relativo ao giro, Q/E alinhado.

var _config: GameConfig
var _rig: CameraRig


func before_test() -> void:
	_config = GameConfig.new()
	_rig = CameraRig.new(_config, Rect2(0, 0, 500, 500))


func test_starts_centered_on_island() -> void:
	assert_vector(_rig.focus).is_equal(Vector3(250, 0, 250))


func test_pitch_is_flatter_near_and_steeper_far() -> void:
	_rig.distance = _config.camera_min_distance_m
	assert_float(rad_to_deg(_rig.pitch())).is_equal_approx(_config.camera_pitch_near_deg, 0.001)
	_rig.distance = _config.camera_max_distance_m
	assert_float(rad_to_deg(_rig.pitch())).is_equal_approx(_config.camera_pitch_far_deg, 0.001)


func test_zoom_is_clamped() -> void:
	_rig.zoom(100.0)
	assert_float(_rig.distance).is_equal(_config.camera_min_distance_m)
	_rig.zoom(-100.0)
	assert_float(_rig.distance).is_equal(_config.camera_max_distance_m)


func test_camera_looks_at_focus_from_above() -> void:
	var transform := _rig.camera_transform()
	assert_float(transform.origin.y).is_greater(0.0)
	var forward := -transform.basis.z
	var to_focus := (_rig.focus - transform.origin).normalized()
	assert_float(forward.dot(to_focus)).is_equal_approx(1.0, 0.0001)


func test_forward_pan_moves_away_from_camera_at_every_quarter() -> void:
	for quarter: int in 4:
		_rig.yaw = quarter * PI / 2.0
		_rig.target_yaw = _rig.yaw
		_rig.focus = Vector3(250, 0, 250)
		var camera_before := _rig.camera_position()
		_rig.pan(Vector2(0, 1), 0.1)
		var moved := _rig.focus - Vector3(250, 0, 250)
		var away := Vector3(250 - camera_before.x, 0, 250 - camera_before.z).normalized()
		assert_float(moved.normalized().dot(away)).is_equal_approx(1.0, 0.0001)


func test_pan_speed_follows_zoom() -> void:
	_rig.distance = 50.0
	_rig.pan(Vector2(1, 0), 0.1)
	var near_step := _rig.focus.distance_to(Vector3(250, 0, 250))
	_rig.focus = Vector3(250, 0, 250)
	_rig.distance = 200.0
	_rig.pan(Vector2(1, 0), 0.1)
	var far_step := _rig.focus.distance_to(Vector3(250, 0, 250))
	assert_float(far_step / near_step).is_equal_approx(4.0, 0.001)


func test_focus_stays_inside_map_bounds() -> void:
	_rig.shift_focus(Vector3(10000, 0, -10000))
	assert_float(_rig.focus.x).is_equal(500 + _config.camera_bounds_margin_m)
	assert_float(_rig.focus.z).is_equal(-_config.camera_bounds_margin_m)


func test_camera_never_goes_below_minimum_height() -> void:
	_config.camera_pitch_near_deg = 0.0
	_rig.distance = _config.camera_min_distance_m
	assert_float(_rig.camera_position().y).is_greater_equal(_config.camera_min_height_m)


func test_quarter_turns_end_exactly_aligned() -> void:
	_rig.rotate_quarter(1)
	assert_bool(_rig.is_rotating()).is_true()
	for frame: int in 30:
		_rig.update(1.0 / 60.0)
	assert_bool(_rig.is_rotating()).is_false()
	assert_float(_rig.yaw).is_equal(PI / 2.0)


func test_quarter_turn_takes_the_configured_time() -> void:
	_rig.rotate_quarter(-1)
	_rig.update(_config.camera_rotate_seconds * 0.5)
	assert_float(_rig.yaw).is_equal_approx(-PI / 4.0, 0.0001)


func test_four_quarter_turns_return_to_start_view() -> void:
	var start := _rig.camera_position()
	for turn: int in 4:
		_rig.rotate_quarter(1)
		_rig.update(1.0)
	assert_vector(_rig.camera_position()).is_equal_approx(start, Vector3(0.001, 0.001, 0.001))


func test_free_rotation_stops_where_released() -> void:
	_rig.rotate_free(100.0)
	assert_bool(_rig.is_rotating()).is_false()
	assert_float(rad_to_deg(_rig.yaw)).is_equal_approx(100.0 * _config.camera_free_rotate_deg_per_px, 0.0001)


func test_center_on_point_arrives() -> void:
	_rig.center_on(Vector3(100, 5, 120))
	for frame: int in 120:
		_rig.update(1.0 / 60.0)
	assert_vector(_rig.focus).is_equal(Vector3(100, 0, 120))


func test_dict_round_trip() -> void:
	_rig.shift_focus(Vector3(-30, 0, 12))
	_rig.zoom(3.0)
	_rig.rotate_quarter(1)
	var copy := CameraRig.new(_config, Rect2(0, 0, 500, 500))
	copy.load_dict(_rig.to_dict())
	assert_vector(copy.focus).is_equal(_rig.focus)
	assert_float(copy.distance).is_equal(_rig.distance)
	assert_float(copy.yaw).is_equal(_rig.target_yaw)
