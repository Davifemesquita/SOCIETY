extends GdUnitTestSuite
## Fase 12 na tela: o objetivo e o prazo no jogo novo, os cenários (um por linha, com jogar), as
## conquistas (ganhas e não), o objetivo no painel das metas, a tela de fim de partida e o aviso de
## conquista. Tudo com ícone e tradução.

const GAME := "res://ui/screens/game_screen.tscn"
const ACHIEVEMENTS_PATH := "user://test_phase12_achievements.cfg"

var _runner: GdUnitSceneRunner
var _game: GameScreen
var _sim: Simulation
var _key := RegEx.create_from_string("^[A-Z][A-Z0-9]*_[A-Z0-9_]+$")
var _format := RegEx.create_from_string("%[0-9.]*[sdf]")
var _store_before: Achievements


func before_test() -> void:
	_store_before = Achievements.shared()
	var store := Achievements.new()
	store.path = ACHIEVEMENTS_PATH
	Achievements.use(store)
	GameScreen.use_sky3d = false
	GameScreen.flat_world = true
	GameScreen.load_slot_on_start = ""
	GameScreen.reset_new_game()
	_runner = scene_runner(GAME)
	_game = _runner.scene()
	_sim = _game.simulation
	GameClock.set_speed(TickClock.PAUSED)
	await _runner.simulate_frames(2)


func after_test() -> void:
	GameScreen.use_sky3d = true
	GameScreen.flat_world = false
	GameScreen.reset_new_game()
	GameScreen.world_seed = -1
	GameScreen.archipelago_size = -1
	GameScreen.difficulty = -1
	GameScreen.events_enabled = true
	GameScreen.rivals_enabled = true
	GameScreen.risks_enabled = true
	Achievements.use(_store_before)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ACHIEVEMENTS_PATH))


func _problems(root: Node, where: String) -> PackedStringArray:
	var problems := PackedStringArray()
	for node: Node in [root] + root.find_children("*", "Control", true, false):
		if not node is Control:
			continue
		var control: Control = node
		if not control.is_visible_in_tree():
			continue
		var path := "%s:%s" % [where, root.get_path_to(control)]
		if control is Button and not (control is OptionButton or control is CheckBox or control is CheckButton):
			var button: Button = control
			if button.icon == null:
				problems.append("botão sem ícone: %s" % path)
		var texts: PackedStringArray = [control.tooltip_text]
		if control is Label:
			var label: Label = control
			texts.append(label.text)
		elif control is Button:
			var with_text: Button = control
			texts.append(with_text.text)
		for text: String in texts:
			if text.is_empty():
				continue
			var shown := text
			if _key.search(text) != null:
				for locale: String in ["pt_BR", "en"]:
					TranslationServer.set_locale(locale)
					if TranslationServer.translate(text) == text:
						problems.append("chave sem tradução (%s): %s em %s" % [locale, text, path])
				TranslationServer.set_locale("pt_BR")
				shown = TranslationServer.translate(text)
			if _format.search(shown) != null:
				problems.append("formato sem valor: \"%s\" em %s" % [shown, path])
	return problems


func _check(where: String) -> void:
	await _runner.simulate_frames(3)
	var problems := _problems(_game.hud.get_parent(), where)
	assert_array(Array(problems)).override_failure_message("\n".join(problems)).is_empty()


func test_new_game_dialog_offers_objective_and_deadline() -> void:
	var dialog := NewGameDialog.new()
	Modal.open(_game._ui_layer, dialog)
	var config := GameConfig.get_default()
	assert_int(dialog.objective_option.item_count).is_equal(config.victory_kinds.size() + 1)
	assert_int(dialog.deadline_option.item_count).is_equal(config.deadline_choices_min.size())
	assert_bool(dialog.deadline_option.disabled).is_true()
	await _check("jogo novo, partida livre")
	dialog.objective_option.select(1)
	dialog.objective_option.item_selected.emit(1)
	dialog.deadline_option.select(2)
	assert_bool(dialog.deadline_option.disabled).is_false()
	dialog.apply_objective()
	assert_int(GameScreen.victory_kind).is_equal(config.victory_kinds[0])
	assert_int(GameScreen.victory_amount).is_equal(config.victory_amounts[0])
	assert_float(GameScreen.victory_deadline_min).is_equal(config.deadline_choices_min[2])
	dialog.objective_option.select(0)
	dialog.apply_objective()
	assert_int(GameScreen.victory_kind).is_equal(-1)
	_game._close_all_modals()


func test_scenario_dialog_lists_every_scenario_and_sets_up_the_game() -> void:
	Achievements.shared().unlock(&"won_poor_colony")
	var dialog := ScenarioDialog.new()
	Modal.open(_game._ui_layer, dialog)
	for def: ScenarioDef in _sim.data.scenarios:
		var row := dialog.find_child("Scenario_" + def.id, true, false)
		assert_object(row).override_failure_message(String(def.id)).is_not_null()
		assert_object(row.find_child("Play", true, false)).is_not_null()
	assert_object(dialog.find_child("Scenario_poor_colony", true, false).find_child("Won", true, false)).is_not_null()
	assert_object(dialog.find_child("Scenario_island_race", true, false).find_child("Won", true, false)).is_null()
	await _check("cenários")
	var picked: Array[StringName] = []
	dialog.start.connect(func(id: StringName) -> void: picked.append(id))
	(dialog.find_child("Scenario_island_race", true, false).find_child("Play", true, false) as Button).pressed.emit()
	assert_array(picked).is_equal([&"island_race"])
	GameScreen.apply_scenario(_sim.data.scenario(&"island_race"))
	assert_int(GameScreen.world_seed).is_equal(_sim.data.scenario(&"island_race").seed)
	assert_str(GameScreen.scenario_id).is_equal("island_race")
	assert_int(GameScreen.victory_kind).is_equal(GoalDef.Kind.COLONIZED_ISLANDS)
	_game._close_all_modals()


func test_achievements_dialog_shows_earned_and_locked() -> void:
	Achievements.shared().unlock(&"tycoon")
	var dialog := AchievementsDialog.new()
	Modal.open(_game._ui_layer, dialog)
	for def: AchievementDef in _sim.data.achievements:
		assert_object(dialog.find_child("Achievement_" + def.id, true, false)).override_failure_message(String(def.id)).is_not_null()
		assert_bool(Icons.has(def.icon)).override_failure_message(def.icon).is_true()
	var count := dialog.find_child("Count", true, false) as Label
	assert_str(count.text).contains("1")
	await _check("conquistas")
	_game._close_all_modals()


func test_goal_panel_shows_the_objective_and_the_end_screen_opens() -> void:
	VictorySystem.start(_sim.world, _sim.config, GoalDef.Kind.MONEY, &"", 100000, 120.0)
	var panel := _game.hud.find_child("Objective", true, false) as Label
	_game.hud.goal_panel.refresh()
	assert_bool(panel.visible).is_true()
	assert_str(panel.text).contains(Fmt.integer(100000))
	await _check("objetivo no painel")
	_sim.world.money = 200000.0
	_sim.run_ticks(_sim.config.goal_check_ticks)
	await _runner.simulate_frames(3)
	assert_int(_sim.world.victory_state.outcome).is_equal(VictoryState.Outcome.WON)
	var dialog := _game._ui_layer.find_child("Victory", true, false) as VictoryDialog
	assert_object(dialog).is_not_null()
	assert_str((dialog.find_child("Title", true, false) as Label).text).is_equal("VICTORY_WON")
	await _check("vitória")
	(dialog.find_child("Continue", true, false) as Button).pressed.emit()
	await _runner.simulate_frames(2)
	assert_bool(_game.modal_open()).is_false()


func test_achievement_notice_has_icon_and_text() -> void:
	var feed := _game.hud.notifications
	feed.push(feed.watcher.achievement(_sim.data.achievements[0]))
	await _check("aviso de conquista")
	for notice: NoticeWatcher.Notice in feed.shown():
		assert_bool(Icons.has(notice.icon)).override_failure_message(notice.icon).is_true()
