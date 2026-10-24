extends GdUnitTestSuite
## Fase 30 na tela: a cortina da troca de tela (escurece, troca, clareia e solta a entrada; direta nos testes), os
## contadores da barra que terminam no valor exato, a notificação que sai das contas na hora e some depois, e as
## moedas sobre o entreposto quando o comerciante paga, com o teto de efeitos.

const GAME := "res://ui/screens/game_screen.tscn"


func after_test() -> void:
	SceneFader.instant = false
	OS.set_environment("SOCIETY_SEM_TRANSICAO", "1")


## Liga as animações neste teste (o tools/godot.sh testes as desliga para a suíte).
func _animate() -> void:
	OS.set_environment("SOCIETY_SEM_TRANSICAO", "0")
	SceneFader.instant = false


func test_the_fader_is_direct_in_tests_and_animated_otherwise() -> void:
	# na suíte, direta: a troca acontece na hora
	assert_bool(SceneFader.is_instant()).is_true()
	var swaps := [0]
	SceneFader.change_with(func() -> void: swaps[0] += 1)
	assert_int(swaps[0]).is_equal(1)
	# animada: escurece antes de trocar, come a entrada enquanto isso e clareia no fim
	if DisplayServer.get_name() == "headless":
		return
	_animate()
	var dark_when_swapped := [-1.0]
	SceneFader.change_with(func() -> void:
		swaps[0] += 1
		dark_when_swapped[0] = SceneFader.curtain_alpha(), "LOADING_NEW_WORLD")
	assert_bool(SceneFader.busy).is_true()
	assert_bool(SceneFader.blocks_input()).is_true()
	await SceneFader.finished
	assert_int(swaps[0]).is_equal(2)
	assert_float(dark_when_swapped[0]).is_equal_approx(1.0, 0.001)
	assert_float(SceneFader.curtain_alpha()).is_equal_approx(0.0, 0.001)
	assert_bool(SceneFader.busy).is_false()
	assert_bool(SceneFader.blocks_input()).is_false()


func test_the_bar_counts_up_to_the_exact_value_and_notices_leave_the_count_at_once() -> void:
	GameScreen.use_sky3d = false
	GameScreen.flat_world = true
	GameScreen.load_slot_on_start = ""
	GameScreen.reset_new_game()
	var runner := scene_runner(GAME)
	var game: GameScreen = runner.scene()
	GameClock.set_speed(TickClock.PAUSED)
	await runner.simulate_frames(2)
	if DisplayServer.get_name() == "headless":
		return
	_animate()
	var hud := game.hud
	game.simulation.world.money += 12345.0
	hud._refresh()
	# no meio da contagem o texto ainda não chegou; no fim, é o valor exato
	var target := tr("HUD_MONEY") % [Fmt.integer(game.simulation.world.money),
			Fmt.signed(game.simulation.world.income_per_min - game.simulation.world.upkeep_per_min)]
	assert_str(hud._money_label.text).is_not_equal(target)
	await runner.simulate_frames(40, 20)
	assert_str(hud._money_label.text).is_equal(target)
	# a notificação: some de shown() na hora e o botão só depois do esmaecer
	var feed := hud.notifications
	var notice := NoticeWatcher.Notice.new("teste/1", "good_planks", "NOTICE_CLICK_TIP")
	feed.push(notice)
	assert_int(feed.shown().size()).is_equal(1)
	var button := feed.get_child(0)
	feed._remove("teste/1")
	assert_int(feed.shown().size()).is_equal(0)
	assert_bool(is_instance_valid(button)).is_true()
	await runner.simulate_frames(30, 20)
	assert_bool(is_instance_valid(button)).is_false()
	GameScreen.use_sky3d = true
	GameScreen.flat_world = false


func test_coins_pop_over_the_trading_post_only_when_the_trader_pays() -> void:
	var sim := SimFixture.simulation(Vector2i(60, 40))
	sim.free_build = true
	SimFixture.place(sim, &"trading_post", Vector2i(10, 0), 2)
	var view: MoneyFxView = auto_free(MoneyFxView.new())
	add_child(view)
	view.setup(sim)
	EventBus.trader_visited.emit(SimFixture.ISLAND, 0.0, 300.0)
	assert_int(view.active_count()).is_equal(0)
	EventBus.trader_visited.emit(SimFixture.ISLAND, 1240.0, 0.0)
	assert_int(view.active_count()).is_equal(1)
	assert_str((view.get_node(^"Gain0/Amount") as Label3D).text).is_equal("+" + Fmt.integer(1240.0))
	# no máximo MAX_EFFECTS ao mesmo tempo: o que passa disso não aparece
	for i: int in MoneyFxView.MAX_EFFECTS + 2:
		view.play(Vector3.ZERO, 10.0)
	assert_int(view.active_count()).is_equal(MoneyFxView.MAX_EFFECTS)
	assert_bool(view.play(Vector3.ZERO, 10.0)).is_false()
	# ilha sem entreposto: nada
	assert_bool(view.trading_post_point(99).is_finite()).is_false()
	EventBus.trader_visited.disconnect(view._on_trader_visited)
