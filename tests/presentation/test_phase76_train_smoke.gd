extends GdUnitTestSuite
## Fumaça do trem (Fase 76): a locomotiva solta fumaça pela chaminé, forte andando e fraca esperando nas pontas, nada
## com o trem parado (poço pausado) ou o jogo pausado; a baforada fica solta no mundo, deita no vento e segue o nível
## gráfico (sem partículas no nível que não tem). Só apresentação.

const STREET := 20

var _sim: Simulation
var _view: TrainView
var _ids: Array[int] = []


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true
	SimFixture.road(_sim, Vector2i(0, STREET), Vector2i(119, STREET))
	var grid := _sim.world.island(SimFixture.ISLAND)
	grid.oil_spots = PackedInt32Array([grid.index(Vector2i(11, STREET + 2))])
	_ids = [SimFixture.place(_sim, &"oil_well", Vector2i(10, STREET + 1), 0),
			SimFixture.place(_sim, &"oil_power_station", Vector2i(30, STREET + 1), 0)]
	# o mesmo trilho da Fase 71
	var path: Array[Vector2i] = []
	for x: int in range(10, 35):
		path.append(Vector2i(x, STREET + 6))
	for y: int in range(STREET + 4, STREET + 6):
		path.append(Vector2i(11, y))
	assert_bool(_sim.execute(BuildRailCommand.new(SimFixture.ISLAND, path)).ok()).is_true()
	_view = auto_free(TrainView.new())
	add_child(_view)
	_view.setup(_sim, _sim.config)


func test_the_chimney_puffs_harder_on_the_move() -> void:
	var smoke := _view.smoke_of(0)
	assert_object(smoke).is_not_null()
	assert_bool(smoke.local_coords).is_false()
	assert_vector(smoke.position).is_equal(TrainView.chimney_top())
	# filha da locomotiva: anda com ela
	assert_bool((smoke.get_parent() as Node3D).transform.is_equal_approx(_view.loco_transform(0))).is_true()
	# a boca da chaminé fica em cima da caldeira, na frente da locomotiva
	var box := TrainView.loco_mesh().get_aabb()
	assert_float(TrainView.chimney_top().y).is_greater(box.end.y - 0.05)
	assert_float(TrainView.chimney_top().z).is_less(0.0)
	# esperando no poço: pouca fumaça
	_view.advance(TrainView.DWELL_S * 0.5)
	assert_bool(smoke.emitting).is_true()
	assert_float(smoke.amount_ratio).is_equal_approx(TrainView.PUFFS_WAITING, 0.001)
	# andando: a fumaça cheia
	_view.advance(TrainView.DWELL_S)
	assert_bool(smoke.emitting).is_true()
	assert_float(smoke.amount_ratio).is_equal_approx(TrainView.PUFFS_MOVING, 0.001)
	# o jogo pausado não solta fumaça
	_view.advance(0.0)
	assert_bool(smoke.emitting).is_false()


func test_no_smoke_with_the_train_stopped() -> void:
	_sim.world.building(_ids[0]).paused = true
	_view.advance(1.0)
	assert_bool(_view.smoke_of(0).emitting).is_false()
	_sim.world.building(_ids[0]).paused = false
	_view.advance(1.0)
	assert_bool(_view.smoke_of(0).emitting).is_true()


func test_moving_matches_the_shuttle() -> void:
	var length := 30.0
	var train_m := TrainView.LOCO_M + TrainView.GAP_M + TrainView.WAGON_M
	var run_s := (length - train_m) / TrainView.SPEED_M_S
	assert_bool(TrainView.moving_at(length, TrainView.DWELL_S * 0.5)).is_false()
	assert_bool(TrainView.moving_at(length, TrainView.DWELL_S + run_s * 0.5)).is_true()
	assert_bool(TrainView.moving_at(length, TrainView.DWELL_S * 1.5 + run_s)).is_false()
	assert_bool(TrainView.moving_at(length, TrainView.DWELL_S * 2.0 + run_s * 1.5)).is_true()
	# caminho mais curto que o trem: nunca anda
	assert_bool(TrainView.moving_at(4.0, 7.0)).is_false()


func test_the_smoke_leans_with_the_wind() -> void:
	_view.advance(1.0)
	assert_vector(_view.smoke_push()).is_equal(SmokeView.drift(Vector2.RIGHT, 0.0))
	var weather: WeatherView = auto_free(WeatherView.new())
	weather.sample.wind = 0.8
	weather.sample.wind_direction = Vector2(0.0, 1.0)
	_view.weather = weather
	_view.advance(1.0)
	var push := _view.smoke_push()
	assert_vector(push).is_equal_approx(SmokeView.drift(Vector2(0.0, 1.0), 0.8), Vector3.ONE * 0.001)
	assert_float(push.z).is_greater(0.0)
	assert_float(push.y).is_greater(0.0)


func test_the_graphics_level_sets_the_puffs() -> void:
	var presets := _sim.config.graphics_presets
	var richest: GraphicsPresetDef = presets[presets.size() - 1]
	_view.set_quality(richest)
	assert_int(_view.train_count()).is_equal(1)
	assert_int(_view.smoke_of(0).amount).is_equal(roundi(TrainView.PUFFS * richest.particles_ratio))
	assert_float(_view.smoke_of(0).visibility_range_end).is_equal_approx(
			TrainView.SMOKE_UNTIL_M * richest.visibility_scale, 0.001)
	var none := GraphicsPresetDef.new()
	none.particles_ratio = 0.0
	_view.set_quality(none)
	assert_object(_view.smoke_of(0)).is_null()
	# sem fumaça, o trem anda do mesmo jeito
	_view.advance(TrainView.DWELL_S * 2.0)
	assert_int(_view.train_count()).is_equal(1)
