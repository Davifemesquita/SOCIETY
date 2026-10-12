extends GdUnitTestSuite
## O autoload GameClock emite um ticked por tick e avisa a troca de velocidade no EventBus.

const GameClockScript := preload("res://core/game_clock.gd")


func test_step_emits_one_signal_per_tick_in_order() -> void:
	var game_clock: GameClockScript = auto_free(GameClockScript.new())
	var received: Array[int] = []
	game_clock.ticked.connect(func(tick_index: int) -> void: received.append(tick_index))
	assert_int(game_clock.step(0.6)).is_equal(3)
	assert_int(game_clock.step(0.4)).is_equal(2)
	assert_array(received).is_equal([1, 2, 3, 4, 5])


func test_speed_change_goes_through_event_bus() -> void:
	var game_clock: GameClockScript = auto_free(GameClockScript.new())
	var changes: Array[Array] = []
	var listener := func(speed_index: int, paused: bool) -> void: changes.append([speed_index, paused])
	EventBus.time_speed_changed.connect(listener)
	game_clock.set_speed(2)
	game_clock.toggle_pause()
	game_clock.set_speed(7)
	EventBus.time_speed_changed.disconnect(listener)
	assert_array(changes).is_equal([[2, false], [TickClock.PAUSED, true]])
