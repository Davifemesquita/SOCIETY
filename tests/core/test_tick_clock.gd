extends GdUnitTestSuite
## Relógio de passo fixo: 5 ticks/s, velocidades, pausa e o teto por quadro.

var _config: GameConfig


func before_test() -> void:
	_config = GameConfig.new()


func test_one_second_at_1x_gives_five_ticks() -> void:
	var clock := TickClock.new(_config)
	assert_int(clock.advance(1.0)).is_equal(5)
	assert_float(clock.game_seconds()).is_equal_approx(1.0, 0.0001)


func test_speeds_multiply_ticks() -> void:
	var clock := TickClock.new(_config)
	clock.set_speed(1)
	assert_int(clock.advance(1.0)).is_equal(10)
	clock.set_speed(2)
	assert_int(clock.advance(1.0)).is_equal(20)


func test_remainder_carries_between_frames() -> void:
	var clock := TickClock.new(_config)
	assert_int(clock.advance(0.15)).is_equal(0)
	assert_int(clock.advance(0.15)).is_equal(1)
	assert_float(clock.interpolation_alpha()).is_equal_approx(0.5, 0.0001)


func test_sixty_fps_for_a_minute_matches_real_time() -> void:
	var clock := TickClock.new(_config)
	for i: int in 3600:
		clock.advance(1.0 / 60.0)
	assert_int(clock.tick_count).is_between(299, 300)


func test_paused_clock_does_not_tick() -> void:
	var clock := TickClock.new(_config)
	clock.set_speed(TickClock.PAUSED)
	assert_bool(clock.is_paused()).is_true()
	assert_int(clock.advance(10.0)).is_equal(0)
	assert_int(clock.tick_count).is_equal(0)


func test_toggle_pause_resumes_previous_speed() -> void:
	var clock := TickClock.new(_config)
	clock.set_speed(2)
	clock.toggle_pause()
	assert_bool(clock.is_paused()).is_true()
	clock.toggle_pause()
	assert_int(clock.speed_index).is_equal(2)


func test_invalid_speed_is_refused() -> void:
	var clock := TickClock.new(_config)
	assert_bool(clock.set_speed(3)).is_false()
	assert_bool(clock.set_speed(-2)).is_false()
	assert_int(clock.speed_index).is_equal(0)


func test_long_frame_is_capped_and_excess_dropped() -> void:
	var clock := TickClock.new(_config)
	clock.set_speed(2)
	assert_int(clock.advance(10.0)).is_equal(_config.max_ticks_per_frame)
	assert_int(clock.advance(0.0)).is_equal(0)
	assert_float(clock.interpolation_alpha()).is_equal(0.0)


func test_day_lasts_twenty_four_real_minutes_at_1x() -> void:
	var clock := TickClock.new(_config)
	clock.tick_count = 3600
	assert_float(clock.time_of_day()).is_equal_approx(0.5, 0.0001)
	assert_int(clock.day_number()).is_equal(1)
	clock.tick_count = 7200
	assert_float(clock.time_of_day()).is_equal_approx(0.0, 0.0001)
	assert_int(clock.day_number()).is_equal(2)


func test_dict_round_trip() -> void:
	var clock := TickClock.new(_config)
	clock.set_speed(1)
	clock.advance(3.0)
	clock.set_speed(TickClock.PAUSED)
	var copy := TickClock.new(_config)
	copy.load_dict(clock.to_dict())
	assert_int(copy.tick_count).is_equal(clock.tick_count)
	assert_bool(copy.is_paused()).is_true()
	copy.toggle_pause()
	assert_int(copy.speed_index).is_equal(1)


func test_load_dict_rejects_garbage() -> void:
	var clock := TickClock.new(_config)
	clock.load_dict({"tick_count": "x", "speed_index": 99, "resume_speed_index": -5})
	assert_int(clock.tick_count).is_equal(0)
	assert_int(clock.speed_index).is_equal(0)
