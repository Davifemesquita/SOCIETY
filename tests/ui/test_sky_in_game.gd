extends GdUnitTestSuite
## A partida com o Sky3D de verdade (lento no xvfb, por isso um teste só): o céu mostra a hora
## do GameClock e escurece à noite.

const GAME := "res://ui/screens/game_screen.tscn"


func test_sky3d_follows_the_game_clock() -> void:
	GameScreen.use_sky3d = true
	GameScreen.load_slot_on_start = ""
	var runner := scene_runner(GAME)
	var game: GameScreen = runner.scene()
	GameClock.set_speed(TickClock.PAUSED)
	await runner.simulate_frames(2)
	assert_bool(game.sky.uses_sky3d()).is_true()
	assert_float(game.sky.shown_hour()).is_equal_approx(GameClock.clock.hour(), 0.01)
	GameClock.clock.extra_hours = 15.0
	await runner.simulate_frames(2)
	assert_float(game.sky.shown_hour()).is_equal_approx(22.0, 0.01)
	assert_float(game.sky.sun().global_basis.z.y).is_less(0.0)
	GameClock.clock.extra_hours = 0.0
