extends GdUnitTestSuite
## Telas da Fase 7: menu principal, jogo novo, salvar e carregar por nome com miniatura, menu da
## partida (pausa e volta), Esc (cancela antes de abrir o menu), opções trocando tecla, idioma e
## modo de daltonismo, e a notificação que leva ao lugar.

const GAME := "res://ui/screens/game_screen.tscn"
const BOOT := "res://ui/screens/boot_screen.tscn"
const TEST_SAVES := "user://test_menu_saves"

var _saves_before: String


func before_test() -> void:
	GameScreen.use_sky3d = false
	GameScreen.flat_world = true
	GameScreen.load_slot_on_start = ""
	_saves_before = SaveSystem.save_dir
	SaveSystem.save_dir = TEST_SAVES


func after_test() -> void:
	GameScreen.use_sky3d = true
	GameScreen.flat_world = false
	GameScreen.archipelago_size = -1
	GameScreen.difficulty = -1
	GameScreen.world_seed = -1
	for slot: String in SaveSystem.list_slots():
		SaveSystem.delete_slot(slot)
	DirAccess.remove_absolute(TEST_SAVES)
	SaveSystem.save_dir = _saves_before
	Settings.reset_keys()


func _game() -> Array:
	var runner := scene_runner(GAME)
	var game: GameScreen = runner.scene()
	GameClock.set_speed(TickClock.PAUSED)
	await runner.simulate_frames(2)
	return [runner, game]


func test_main_menu_has_every_entry_and_continue_needs_a_save() -> void:
	var runner := scene_runner(BOOT)
	await runner.simulate_frames(2)
	var boot: Control = runner.scene()
	for key: String in ["BOOT_CONTINUE", "BOOT_NEW_GAME", "BOOT_SCENARIOS", "BOOT_LOAD_GAME", "BOOT_OPTIONS", "BOOT_ACHIEVEMENTS", "BOOT_CREDITS",
			"BOOT_QUIT"]:
		var button: Button = boot.find_child(key, true, false)
		assert_object(button).override_failure_message(key).is_not_null()
		assert_object(button.icon).is_not_null()
	var continue_button: Button = boot.find_child("BOOT_CONTINUE", true, false)
	assert_bool(continue_button.disabled).is_true()


func test_new_game_dialog_hands_over_seed_size_and_difficulty() -> void:
	var dialog: NewGameDialog = auto_free(NewGameDialog.new())
	var got := []
	dialog.start.connect(func(seed_value: int, size: int, difficulty: int) -> void: got.append_array([seed_value, size, difficulty]))
	dialog.seed_edit.text = "1840"
	dialog.size_option.select(2)
	dialog.difficulty_option.select(0)
	dialog.confirm()
	assert_array(got).is_equal([1840, 2, 0])
	dialog.roll()
	assert_bool(dialog.seed_edit.text.is_valid_int()).is_true()
	assert_int(dialog.size_option.item_count).is_equal(3)


func test_the_game_starts_with_the_chosen_difficulty() -> void:
	GameScreen.difficulty = 2
	var started: Array = await _game()
	var game: GameScreen = started[1]
	assert_int(game.simulation.world.difficulty).is_equal(2)
	assert_float(game.simulation.world.money).is_equal(25000.0)


func test_save_by_name_lists_it_with_thumbnail_and_loads_it_back() -> void:
	var started: Array = await _game()
	var runner: GdUnitSceneRunner = started[0]
	var game: GameScreen = started[1]
	var sim := game.simulation
	sim.free_build = true
	sim.execute(PlaceBuildingCommand.new(0, &"trading_post", Vector2i(100, 0), 2))
	var dialog := game.open_save_dialog()
	dialog.name_edit.text = "Minha Vila"
	dialog.confirm()
	await runner.simulate_frames(2)
	assert_bool(SaveSystem.has_slot("minha_vila")).is_true()
	assert_bool(game.modal_open()).is_false()
	assert_str(str(SaveSystem.read_info("minha_vila")["name"])).is_equal("Minha Vila")
	sim.execute(DemolishCommand.new(0, Rect2i(Vector2i(100, 0), Vector2i.ONE)))
	assert_bool(sim.world.has_trading_post(0, sim.data)).is_false()
	var load_dialog := game.open_load_dialog()
	assert_int(load_dialog.slots.item_count).is_equal(1)
	assert_str(load_dialog.selected_slot()).is_equal("minha_vila")
	load_dialog.confirm()
	await runner.simulate_frames(2)
	assert_bool(game.simulation.world.has_trading_post(0, game.simulation.data)).is_true()
	assert_bool(game.modal_open()).is_false()


func test_escape_cancels_first_and_then_opens_the_menu_that_pauses() -> void:
	var started: Array = await _game()
	var runner: GdUnitSceneRunner = started[0]
	var game: GameScreen = started[1]
	GameClock.set_speed(1)
	game.tool.start_road()
	runner.simulate_key_pressed(KEY_ESCAPE)
	await runner.await_input_processed()
	assert_int(game.tool.mode).is_equal(BuildTool.Mode.NONE)
	assert_bool(game.modal_open()).is_false()
	runner.simulate_key_pressed(KEY_ESCAPE)
	await runner.await_input_processed()
	assert_bool(game.modal_open()).is_true()
	assert_bool(GameClock.clock.is_paused()).is_true()
	runner.simulate_key_pressed(KEY_ESCAPE)
	await runner.await_input_processed()
	await runner.simulate_frames(1)
	assert_bool(game.modal_open()).is_false()
	assert_int(GameClock.clock.speed_index).is_equal(1)
	GameClock.set_speed(TickClock.PAUSED)


func test_options_rebind_a_key_by_pressing_it() -> void:
	var options: OptionsDialog = auto_free(OptionsDialog.new())
	add_child(options)
	options._wait_key(&"build_road")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_G
	event.pressed = true
	options._input(event)
	assert_array(Array(Settings.keys_of(&"build_road"))).is_equal([KEY_G])
	assert_bool(InputMap.action_has_event(&"build_road", event)).is_true()
	var button: Button = options.find_child("Key_build_road", true, false)
	assert_str(button.text).is_equal(InputActions.key_name(KEY_G))
	assert_object(button.icon).is_not_null()
	remove_child(options)


func test_colorblind_option_repaints_the_house_needs() -> void:
	var started: Array = await _game()
	var runner: GdUnitSceneRunner = started[0]
	var game: GameScreen = started[1]
	var sim := game.simulation
	sim.free_build = true
	var house := sim.execute(PlaceBuildingCommand.new(0, &"house", Vector2i(100, 100), 0)).placed[0]
	game.tool.select(house)
	await runner.simulate_frames(2)
	var marker: TextureRect = game.hud.selection_panel.find_child("Status", true, false)
	var before := marker.modulate
	Settings.colorblind = not Settings.colorblind
	Settings.apply()
	await runner.simulate_frames(10)
	assert_bool(marker.modulate == before).is_false()
	Settings.colorblind = not Settings.colorblind
	Settings.apply()


func test_clicking_a_notice_selects_the_building_and_moves_the_camera() -> void:
	var started: Array = await _game()
	var runner: GdUnitSceneRunner = started[0]
	var game: GameScreen = started[1]
	var sim := game.simulation
	sim.free_build = true
	var post: int = sim.execute(PlaceBuildingCommand.new(0, &"trading_post", Vector2i(100, 0), 2)).placed[0]
	# o mouse no meio: no canto, a câmera anda sozinha pela borda
	runner.simulate_mouse_move(Vector2(960, 540))
	game.camera.rig.center_on(Vector3(20, 0, 400))
	var feed := game.hud.notifications
	feed.push(feed.watcher.shortage(0, &"fish"))
	await runner.simulate_frames(2)
	var button: Button = feed.get_child(0)
	assert_object(button.icon).is_not_null()
	button.pressed.emit()
	await runner.simulate_frames(30)
	assert_int(game.tool.selected_id).is_equal(post)
	var record := sim.world.building(post)
	var center := sim.world.island(0).rect_world(Footprint.rect(record.origin, sim.def_of(record).size, record.rotation))
	assert_float(Vector2(game.camera.rig.focus.x, game.camera.rig.focus.z).distance_to(Vector2(center.x, center.z))).is_less(5.0)
	assert_int(feed.shown().size()).is_equal(0)
