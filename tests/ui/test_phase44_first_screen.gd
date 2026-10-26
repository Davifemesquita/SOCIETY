extends GdUnitTestSuite
## Primeira tela (Fase 44): a prévia do jogo novo usa exatamente as alturas que a partida gera para a semente, sai numa
## thread, é cancelada quando a semente muda sem deixar tarefa para trás; o fundo do menu não tem mais a grade; o fim da
## partida tem som; as chaves existem.

var _config: GameConfig


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([70, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])


func _fingerprints(world: WorldState) -> PackedInt64Array:
	var result := PackedInt64Array()
	for grid: IslandGrid in world.islands:
		result.append(grid.fingerprint)
	return result


func test_the_preview_draws_the_same_heights_the_game_generates() -> void:
	var data := GameData.get_default()
	var preview := ArchipelagoPreview.new(1840, 0, _config, data)
	preview.start(true)
	var waited := 0
	while not preview.poll():
		OS.delay_msec(5)
		waited += 1
		assert_int(waited).is_less(4000)
	var game := ArchipelagoGenerator.new_world(1840, _config, data, 0)
	assert_that(_fingerprints(preview.world())).is_equal(_fingerprints(game))
	var chart := SeaChart.new(game, _config)
	var image := preview.image()
	assert_object(image).is_not_null()
	assert_that(Vector2i(image.get_width(), image.get_height())).is_equal(chart.size * ArchipelagoPreview.SCALE)


func test_a_cancelled_preview_gives_nothing_and_leaves_no_task_behind() -> void:
	var preview := ArchipelagoPreview.new(77, 0, _config, GameData.get_default())
	preview.start(true)
	ArchipelagoPreview.adopt(preview)
	assert_bool(preview.is_cancelled()).is_true()
	var waited := 0
	while ArchipelagoPreview.orphan_count() > 0:
		ArchipelagoPreview.reap()
		OS.delay_msec(5)
		waited += 1
		assert_int(waited).is_less(4000)
	assert_object(preview.image()).is_null()


func test_the_new_game_dialog_redraws_the_chart_when_the_seed_changes() -> void:
	var dialog: NewGameDialog = auto_free(NewGameDialog.new())
	add_child(dialog)
	dialog.seed_edit.text = "4242"
	dialog.start_preview(false)
	dialog._process(0.0)
	assert_object(dialog.preview.texture).is_not_null()
	assert_str(dialog.preview_label.text).contains("4242")
	var first := dialog.current_preview()
	# outra semente: a prévia de agora é cancelada e a nova só começa depois do respiro
	dialog.seed_edit.text = "9"
	dialog._ask_preview()
	assert_bool(first.is_cancelled()).is_true()
	assert_object(dialog.current_preview()).is_null()
	dialog._process(NewGameDialog.PREVIEW_DELAY_S + 0.01)
	assert_object(dialog.current_preview()).is_not_null()
	assert_int(dialog.current_preview().seed_value).is_equal(9)
	remove_child(dialog)
	ArchipelagoPreview.reap()


func test_the_menu_background_has_no_grid_and_opens_fast() -> void:
	var source := (load("res://ui/screens/menu_background.gd") as GDScript).source_code
	assert_bool(source.contains("var step := 96.0")).is_false()
	var started := Time.get_ticks_msec()
	var menu := (load("res://ui/screens/boot_screen.tscn") as PackedScene).instantiate() as Control
	add_child(menu)
	var elapsed := Time.get_ticks_msec() - started
	print("Fase 44: menu principal aberto em %d ms" % elapsed)
	assert_int(elapsed).is_less(3000)
	menu.queue_free()
	await await_idle_frame()


func test_the_preview_of_a_full_archipelago_takes_a_few_seconds() -> void:
	var config := GameConfig.get_default()
	for case: Vector2i in [Vector2i(1, ArchipelagoPreview.SCALE), Vector2i(0, ArchipelagoMap.ENGRAVE_SCALE)]:
		var started := Time.get_ticks_msec()
		var preview := ArchipelagoPreview.new(1840, case.x, config, GameData.get_default(), case.y)
		preview.start(false)
		var elapsed := Time.get_ticks_msec() - started
		var image := preview.image()
		print("Fase 44: prévia do arquipélago %d na escala %d em %d ms (%dx%d)" % [case.x, case.y, elapsed,
				image.get_width(), image.get_height()])
		# a do diálogo (escala 1) sai em poucos segundos; a do fundo do menu roda na thread com o menu já na tela
		if case.y == ArchipelagoPreview.SCALE:
			assert_int(elapsed).is_less(8000)


func test_the_end_of_the_game_has_its_sound() -> void:
	var before_win: int = UiSfx.played.get(&"victory", 0)
	var before_loss: int = UiSfx.played.get(&"defeat", 0)
	UiSfx.end_of_game(true)
	UiSfx.end_of_game(false)
	assert_int(UiSfx.played[&"victory"]).is_equal(before_win + 1)
	assert_int(UiSfx.played[&"defeat"]).is_equal(before_loss + 1)


func test_the_preview_keys_exist_in_both_languages() -> void:
	for locale: String in ["pt_BR", "en"]:
		TranslationServer.set_locale(locale)
		for key: String in ["NEW_GAME_PREVIEW_TIP", "NEW_GAME_PREVIEW_WORKING", "NEW_GAME_PREVIEW_DONE"]:
			assert_str(tr(key)).override_failure_message("%s em %s" % [key, locale]).is_not_equal(key)
	TranslationServer.set_locale("pt_BR")
