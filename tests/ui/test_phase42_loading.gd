extends GdUnitTestSuite
## Jogo novo em etapas (Fase 42): a partida usa o mundo que o menu gerou atrás da cortina, uma vez só; a cortina direta
## (testes) gera e troca; as dicas existem em pt_BR e em inglês.


func after_test() -> void:
	GameScreen.prepared_world = null
	GameScreen.flat_world = false
	GameScreen.world_seed = -1


func test_the_game_uses_the_prepared_world_once() -> void:
	var config := GameConfig.new()
	config.island_sizes_cells = PackedInt32Array([60, 40])
	config.tropical_island_sizes_cells = PackedInt32Array([30])
	var job := ArchipelagoJob.new(321, config, GameData.get_default())
	job.start(false)
	GameScreen.flat_world = false
	GameScreen.prepared_world = job.result()
	var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(game)
	assert_object(game.simulation.world).is_same(job.result())
	assert_object(GameScreen.prepared_world).is_null()
	game.queue_free()
	await await_idle_frame()


func test_the_direct_curtain_generates_and_swaps() -> void:
	var job := ArchipelagoJob.new(9, GameConfig.get_default(), GameData.get_default(), 0)
	var swapped := [false]
	SceneFader.instant = true
	await SceneFader.change_with_job(job, func() -> void: swapped[0] = job.is_done())
	SceneFader.instant = false
	assert_bool(swapped[0]).is_true()


func test_every_loading_tip_is_translated() -> void:
	for number: int in range(1, SceneFader.TIPS + 1):
		var key := "LOADING_TIP_%d" % number
		for locale: String in ["pt_BR", "en"]:
			TranslationServer.set_locale(locale)
			assert_str(tr(key)).override_failure_message("%s em %s" % [key, locale]).is_not_equal(key)
	TranslationServer.set_locale("pt_BR")
