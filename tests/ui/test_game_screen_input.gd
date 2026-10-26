extends GdUnitTestSuite
## A partida inteira com entrada simulada de mouse e teclado: o caminho real do clique até o
## comando, a câmera (zoom no cursor, arrasto do meio, Q/E, giro livre) e os atalhos.

const GAME := "res://ui/screens/game_screen.tscn"
const TEST_SAVE_DIR := "user://test_saves_input"

var _runner: GdUnitSceneRunner
var _game: GameScreen
var _previous_save_dir: String


func before_test() -> void:
	# mouse simulado: o pan pela borda leria o cursor de verdade (num canto) e mexeria na câmera entre os quadros
	Settings.edge_pan = false
	GameScreen.use_sky3d = false
	GameScreen.flat_world = true
	_previous_save_dir = SaveSystem.save_dir
	SaveSystem.save_dir = TEST_SAVE_DIR
	GameScreen.load_slot_on_start = ""
	_runner = scene_runner(GAME)
	_game = _runner.scene()
	_game.simulation.free_build = true
	GameClock.set_speed(0)
	_runner.simulate_mouse_move(_center())
	await _runner.await_input_processed()


func after_test() -> void:
	Settings.edge_pan = true
	GameScreen.use_sky3d = true
	GameScreen.flat_world = false
	SaveSystem.save_dir = _previous_save_dir
	if DirAccess.dir_exists_absolute(TEST_SAVE_DIR):
		for file_name: String in DirAccess.get_files_at(TEST_SAVE_DIR):
			DirAccess.remove_absolute(TEST_SAVE_DIR.path_join(file_name))
		DirAccess.remove_absolute(TEST_SAVE_DIR)


func _center() -> Vector2:
	return _game.get_viewport().get_visible_rect().size * 0.5


func _cell_under(screen_position: Vector2) -> Vector2i:
	var point: Vector3 = _game.camera.ground_point(screen_position)
	return GridSpace.world_to_cell(point, GameConfig.get_default().cell_size_m)


func test_left_click_builds_under_the_mouse() -> void:
	_game.tool.start_building(_game.simulation.data.building(&"house"))
	_runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	await _runner.await_input_processed()
	var building_id := _game.simulation.world.island(0).building_at(_cell_under(_center()))
	assert_int(building_id).is_greater(0)
	assert_int(_game.building_view.building_count()).is_equal(1)


func test_drag_with_road_tool_builds_the_road() -> void:
	_runner.simulate_key_pressed(KEY_T)
	await _runner.await_input_processed()
	assert_int(_game.tool.mode).is_equal(BuildTool.Mode.ROAD)
	# O runner do gdUnit4 põe o clique seguinte a uma tecla em (0, 0); reposiciona o mouse.
	_runner.simulate_mouse_move(_center())
	await _runner.await_input_processed()
	var start := _cell_under(_center())
	_runner.simulate_mouse_button_press(MOUSE_BUTTON_LEFT)
	await _runner.await_input_processed()
	_runner.simulate_mouse_move(_center() + Vector2(300, 0))
	await _runner.await_input_processed()
	var finish := _cell_under(_center() + Vector2(300, 0))
	_runner.simulate_mouse_button_release(MOUSE_BUTTON_LEFT)
	await _runner.await_input_processed()
	var grid := _game.simulation.world.island(0)
	assert_bool(grid.has_road(start)).is_true()
	assert_bool(grid.has_road(finish)).is_true()
	assert_int(grid.road_cells().size()).is_equal(RoadPath.l_path(start, finish).size())
	# Fase 38: na ilha com relevo a terra é pintada no terreno, sem ladrilho
	assert_int(_game.road_view.tile_count() + _game.road_view.painted_count()).is_equal(grid.road_cells().size())


func test_wheel_zooms_toward_the_point_under_the_cursor() -> void:
	var spot := _center() + Vector2(350, 180)
	_runner.simulate_mouse_move(spot)
	await _runner.await_input_processed()
	var before: Vector3 = _game.camera.ground_point(spot)
	var distance_before := _game.camera.rig.distance
	_runner.simulate_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP)
	await _runner.await_input_processed()
	var after: Vector3 = _game.camera.ground_point(spot)
	assert_float(_game.camera.rig.distance).is_less(distance_before)
	assert_vector(after).is_equal_approx(before, Vector3(0.05, 0.05, 0.05))


func test_middle_drag_keeps_the_grabbed_point_under_the_mouse() -> void:
	var grabbed: Vector3 = _game.camera.ground_point(_center())
	_runner.simulate_mouse_button_press(MOUSE_BUTTON_MIDDLE)
	await _runner.await_input_processed()
	var target := _center() + Vector2(-240, 120)
	_runner.simulate_mouse_move(target)
	await _runner.await_input_processed()
	_runner.simulate_mouse_button_release(MOUSE_BUTTON_MIDDLE)
	await _runner.await_input_processed()
	var now_under: Vector3 = _game.camera.ground_point(target)
	assert_vector(now_under).is_equal_approx(grabbed, Vector3(0.05, 0.05, 0.05))


func test_q_and_e_turn_ninety_degrees() -> void:
	_runner.simulate_key_pressed(KEY_E)
	await _runner.simulate_frames(40, 16)
	assert_float(_game.camera.rig.yaw).is_equal_approx(PI / 2.0, 0.0001)
	_runner.simulate_key_pressed(KEY_Q)
	_runner.simulate_key_pressed(KEY_Q)
	await _runner.simulate_frames(60, 16)
	assert_float(_game.camera.rig.yaw).is_equal_approx(-PI / 2.0, 0.0001)


func test_right_drag_rotates_without_cancelling_the_tool() -> void:
	_game.tool.start_road()
	_runner.simulate_mouse_button_press(MOUSE_BUTTON_RIGHT)
	await _runner.await_input_processed()
	_runner.simulate_mouse_move(_center() + Vector2(120, 0))
	await _runner.await_input_processed()
	_runner.simulate_mouse_button_release(MOUSE_BUTTON_RIGHT)
	await _runner.await_input_processed()
	assert_float(_game.camera.rig.yaw).is_not_equal(0.0)
	assert_int(_game.tool.mode).is_equal(BuildTool.Mode.ROAD)


func test_short_right_click_cancels_the_tool() -> void:
	_game.tool.start_road()
	_runner.simulate_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	await _runner.await_input_processed()
	assert_int(_game.tool.mode).is_equal(BuildTool.Mode.NONE)


func test_space_pauses_and_number_keys_set_speed() -> void:
	_runner.simulate_key_pressed(KEY_SPACE)
	await _runner.await_input_processed()
	assert_bool(GameClock.clock.is_paused()).is_true()
	_runner.simulate_key_pressed(KEY_3)
	await _runner.await_input_processed()
	assert_int(GameClock.clock.speed_index).is_equal(2)


func test_f5_then_f9_restores_the_world() -> void:
	_game.tool.start_building(_game.simulation.data.building(&"house"))
	_runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	await _runner.await_input_processed()
	var saved := _game.game_state()
	_runner.simulate_key_pressed(KEY_F5)
	await _runner.await_input_processed()
	_game.simulation.execute(DemolishCommand.new(0, Rect2i(0, 0, 250, 250)))
	assert_int(_game.building_view.building_count()).is_equal(0)
	_runner.simulate_key_pressed(KEY_F9)
	await _runner.await_input_processed()
	assert_bool(_game.game_state() == saved).is_true()
	assert_int(_game.building_view.building_count()).is_equal(1)


func test_click_selects_and_f_centers_the_camera() -> void:
	var sim := _game.simulation
	var target := Vector2i(60, 60)
	sim.execute(PlaceBuildingCommand.new(0, &"house", target, 0))
	_game.tool.select(sim.world.island(0).building_at(target))
	await _runner.simulate_frames(2)
	assert_bool(_game.hud.selection_panel.shows_missing_road()).is_true()
	_runner.simulate_key_pressed(KEY_F)
	await _runner.simulate_frames(90, 16)
	var expected := GridSpace.rect_center(Rect2i(target, Vector2i(3, 3)), GameConfig.get_default().cell_size_m)
	assert_vector(_game.camera.rig.focus).is_equal_approx(expected, Vector3(0.1, 0.1, 0.1))
