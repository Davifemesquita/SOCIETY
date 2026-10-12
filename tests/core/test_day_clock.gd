extends GdUnitTestSuite
## Relógio do dia (seção 9): começa às 7h, 1 dia = 24 minutos reais a 1x, só visual; a noite e a
## gente na rua saem da hora.

var _config: GameConfig


func before_test() -> void:
	_config = GameConfig.new()


func test_new_game_starts_at_seven_on_day_one() -> void:
	var clock := TickClock.new(_config)
	assert_float(clock.hour()).is_equal_approx(7.0, 0.0001)
	assert_int(clock.day_number()).is_equal(1)
	assert_str(DayClock.clock_text(clock.hour())).is_equal("07:00")


func test_one_real_minute_is_one_hour_at_1x_and_four_at_4x() -> void:
	var clock := TickClock.new(_config)
	for second: int in 60:
		clock.advance(1.0)
	assert_float(clock.hour()).is_equal_approx(8.0, 0.001)
	clock.set_speed(2)
	for second: int in 60:
		clock.advance(1.0)
	assert_float(clock.hour()).is_equal_approx(12.0, 0.001)


func test_pause_freezes_the_day() -> void:
	var clock := TickClock.new(_config)
	clock.set_speed(TickClock.PAUSED)
	clock.advance(30.0)
	assert_float(clock.hour()).is_equal_approx(7.0, 0.0001)


func test_hour_moves_smoothly_between_ticks() -> void:
	var clock := TickClock.new(_config)
	clock.advance(0.1)
	assert_int(clock.tick_count).is_equal(0)
	assert_float(clock.hour()).is_greater(7.0)


func test_midnight_turns_the_day() -> void:
	var clock := TickClock.new(_config)
	clock.tick_count = roundi(17.0 * 60.0 * _config.ticks_per_second)
	assert_float(clock.hour()).is_equal_approx(0.0, 0.001)
	assert_int(clock.day_number()).is_equal(2)


func test_extra_hours_survive_the_save_and_old_saves_load_without_them() -> void:
	var clock := TickClock.new(_config)
	clock.extra_hours = 3.0
	var copy := TickClock.new(_config)
	var saved: Dictionary = SaveSystem.unpack_floats(SaveSystem.pack_floats(clock.to_dict()))
	copy.load_dict(saved)
	assert_float(copy.hour()).is_equal_approx(10.0, 0.0001)
	copy.load_dict({"tick_count": 0, "speed_index": 0, "resume_speed_index": 0})
	assert_float(copy.extra_hours).is_equal(0.0)


func test_night_factor_is_zero_at_noon_one_at_midnight_and_rises_at_dusk() -> void:
	assert_float(DayClock.night_factor(_config, 12.0)).is_equal(0.0)
	assert_float(DayClock.night_factor(_config, 0.0)).is_equal(1.0)
	var before := DayClock.night_factor(_config, _config.sunset_hour - 0.3)
	var at := DayClock.night_factor(_config, _config.sunset_hour)
	var after := DayClock.night_factor(_config, _config.sunset_hour + 0.3)
	assert_bool(before < at and at < after).is_true()
	assert_float(DayClock.night_factor(_config, _config.sunrise_hour + _config.twilight_hours + 0.01)).is_equal(0.0)


func test_fewer_people_out_at_night_than_at_noon() -> void:
	assert_float(DayClock.activity(_config, 2.0)).is_less(DayClock.activity(_config, 12.0))
	assert_float(DayClock.activity(_config, 12.5)).is_equal_approx(
			lerpf(_config.pedestrian_activity_by_hour[12], _config.pedestrian_activity_by_hour[13], 0.5), 0.0001)


func test_config_rejects_a_broken_day() -> void:
	_config.pedestrian_activity_by_hour = PackedFloat32Array([1.0])
	_config.sunrise_hour = 20.0
	assert_int(_config.validate().size()).is_equal(2)
