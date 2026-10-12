extends GdUnitTestSuite
## Interface da Fase 4 com a partida de verdade (céu simples; o Sky3D na partida está em
## test_sky_in_game.gd): relógio do dia, F7, multidão e janelas na vila, e a hora depois de
## salvar e carregar.

const GAME := "res://ui/screens/game_screen.tscn"
const TEST_SAVE_DIR := "user://test_saves_phase4"

var _runner: GdUnitSceneRunner
var _game: GameScreen
var _sim: Simulation
var _previous_save_dir: String


func before_test() -> void:
	GameScreen.use_sky3d = false
	_previous_save_dir = SaveSystem.save_dir
	SaveSystem.save_dir = TEST_SAVE_DIR
	GameScreen.load_slot_on_start = ""
	_runner = scene_runner(GAME)
	_game = _runner.scene()
	_sim = _game.simulation
	GameClock.set_speed(TickClock.PAUSED)
	await _runner.simulate_frames(2)


func after_test() -> void:
	GameScreen.use_sky3d = true
	GameClock.clock.extra_hours = 0.0
	SaveSystem.save_dir = _previous_save_dir
	if DirAccess.dir_exists_absolute(TEST_SAVE_DIR):
		for file_name: String in DirAccess.get_files_at(TEST_SAVE_DIR):
			DirAccess.remove_absolute(TEST_SAVE_DIR.path_join(file_name))
		DirAccess.remove_absolute(TEST_SAVE_DIR)


## Vila de demonstração com 10 minutos de economia (moradores nas casas).
func _village() -> void:
	DemoVillage.build(_sim)
	_sim.run_ticks(roundi(600.0 / _sim.config.tick_interval()))
	GameClock.clock.tick_count = _sim.world.tick


func test_new_game_starts_on_day_one_at_seven() -> void:
	assert_str(_game.hud._clock_label.text).is_equal(tr("HUD_CLOCK") % [1, 7, 0])


func test_f7_moves_the_day_but_not_the_economy() -> void:
	var tick := _sim.world.tick
	var hour := GameClock.clock.hour()
	_runner.simulate_key_pressed(KEY_F7)
	await _runner.simulate_frames(2)
	assert_float(GameClock.clock.hour()).is_equal_approx(fposmod(hour + 3.0, 24.0), 0.01)
	assert_int(_sim.world.tick).is_equal(tick)
	assert_str(_game.hud._clock_label.text).is_equal(tr("HUD_CLOCK") % [1, 10, 0])


func test_the_sky_and_the_night_light_follow_the_game_clock() -> void:
	GameClock.clock.extra_hours = 16.0
	await _runner.simulate_frames(2)
	assert_float(_game.sky.shown_hour()).is_equal_approx(GameClock.clock.hour(), 0.01)
	assert_float(_game.night_light).is_equal_approx(DayClock.night_factor(_sim.config, GameClock.clock.hour()), 0.01)
	assert_float(_game.night_light).is_equal(1.0)


func test_the_village_streets_fill_with_pedestrians() -> void:
	_village()
	var crowd := _game.pedestrian_view.crowd
	# o jogo está pausado (a multidão para junto): alguns segundos de rua na mão
	for step: int in 60:
		crowd.update(0.1, 10.0)
	await _runner.simulate_frames(2)
	var residents := 0.0
	for house_id: int in _sim.derived_state().houses:
		residents += _sim.world.building(house_id).residents
	assert_int(crowd.agent_count()).is_equal(floori(residents / _sim.config.residents_per_pedestrian))
	assert_int(crowd.visible_count()).is_greater(crowd.agent_count() / 2)
	assert_int(_game.pedestrian_view.instance_count()).is_greater_equal(crowd.agent_count())


func test_windows_cover_the_village_and_light_up_at_night() -> void:
	_village()
	await _runner.simulate_frames(2)
	assert_int(_game.window_view.window_count()).is_greater(150)
	_game.window_view.refresh_lit()
	var houses: Array[int] = _sim.derived_state().houses
	assert_bool(_game.window_view.is_building_lit(houses[0])).is_true()


func test_saving_and_loading_keep_the_hour_and_rebuild_the_crowd() -> void:
	_village()
	GameClock.clock.extra_hours = 5.0
	var hour := GameClock.clock.hour()
	_game.quicksave()
	GameClock.clock.extra_hours = 0.0
	_game.quickload()
	# a fração de tick ainda não rodada não vai no save
	assert_float(GameClock.clock.hour()).is_equal_approx(hour, 0.01)
	var crowd := _game.pedestrian_view.crowd
	assert_int(crowd.agent_count()).is_equal(0)
	crowd.update(2.5, hour)
	assert_int(crowd.agent_count()).is_greater(0)
