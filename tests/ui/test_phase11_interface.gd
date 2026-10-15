extends GdUnitTestSuite
## Eventos e encomendas na tela (Fase 11): o botão da barra com a contagem, a janela com a oferta
## (aceitar e recusar) e a aceita (entregue e prazo), os selos dos eventos com a dica, as
## notificações que abrem a janela e a caixa do jogo novo. Tudo com ícone e tradução.

const GAME := "res://ui/screens/game_screen.tscn"

var _runner: GdUnitSceneRunner
var _game: GameScreen
var _sim: Simulation
var _key := RegEx.create_from_string("^[A-Z][A-Z0-9]*_[A-Z0-9_]+$")
var _format := RegEx.create_from_string("%[0-9.]*[sdf]")


func before_test() -> void:
	GameScreen.use_sky3d = false
	GameScreen.flat_world = true
	GameScreen.load_slot_on_start = ""
	_runner = scene_runner(GAME)
	_game = _runner.scene()
	_sim = _game.simulation
	GameClock.set_speed(TickClock.PAUSED)
	await _runner.simulate_frames(2)


func after_test() -> void:
	GameScreen.use_sky3d = true
	GameScreen.flat_world = false


## Uma encomenda oferecida e outra aceita, e dois eventos em andamento (sem esperar o sorteio).
func _fill() -> void:
	var state := _sim.world.events_state
	state.enabled = true
	for index: int in 2:
		var item := Mission.new()
		item.id = state.next_mission_id
		state.next_mission_id += 1
		item.def = _sim.data.missions[index]
		item.def_id = item.def.id
		item.expires_tick = _sim.world.tick + _sim.config.ticks_of(300.0)
		if index == 1:
			item.state = Mission.State.ACCEPTED
			item.delivered = 7.0
		state.missions.append(item)
	for def_id: StringName in [&"fair", &"good_harvest"]:
		var event := WorldEvent.new()
		event.def = _sim.data.event(def_id)
		event.def_id = def_id
		event.island_id = 0 if event.def.is_local() else -1
		event.good = &"bricks" if def_id == &"fair" else &""
		event.started_tick = _sim.world.tick
		event.ends_tick = _sim.world.tick + _sim.config.ticks_of(120.0)
		state.events.append(event)


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


func test_mission_window_lists_offers_accepted_orders_and_events() -> void:
	_fill()
	var hud := _game.hud
	hud._refresh()
	var button := hud.find_child("MissionsButton", true, false) as Button
	assert_str(button.text).contains("2")
	# os selos dos eventos na barra, com o título e o tempo na dica
	var chips := hud.find_child("Events", true, false) as HBoxContainer
	assert_int(chips.get_child_count()).is_equal(2)
	var fair_chip := chips.get_child(0) as Control
	assert_str(fair_chip.tooltip_text).contains(tr("EVENT_FAIR"))
	assert_str(fair_chip.tooltip_text).contains(tr("GOOD_BRICKS"))
	await _check("barra")
	hud.toggle_missions()
	await _check("encomendas")
	var window := hud.mission_window
	assert_bool(window.visible).is_true()
	var offer := window.find_child("Mission_1", true, false)
	assert_object(offer).is_not_null()
	assert_object(offer.find_child("Accept", true, false)).is_not_null()
	var accepted := window.find_child("Mission_2", true, false)
	assert_object(accepted.find_child("Accept", true, false)).is_null()
	(offer.find_child("Accept", true, false) as Button).pressed.emit()
	await _runner.simulate_frames(2)
	assert_int(_sim.world.events_state.mission(1).state).is_equal(Mission.State.ACCEPTED)
	await _check("encomendas aceitas")
	# Esc fecha a janela de cima
	assert_bool(hud.close_top_window()).is_true()
	assert_bool(window.visible).is_false()


func test_declining_removes_the_offer() -> void:
	_fill()
	_game.hud.mission_window.open()
	await _runner.simulate_frames(2)
	var offer := _game.hud.mission_window.find_child("Mission_1", true, false)
	(offer.find_child("Decline", true, false) as Button).pressed.emit()
	await _runner.simulate_frames(2)
	assert_object(_sim.world.events_state.mission(1)).is_null()
	assert_object(_game.hud.mission_window.find_child("Mission_1", true, false)).is_null()


func test_empty_and_disabled_states_have_text() -> void:
	_game.hud.mission_window.open()
	await _check("desligado")
	_sim.world.events_state.enabled = true
	_game.hud.mission_window.rebuild()
	await _check("vazio")


func test_notices_open_the_window_and_have_icons() -> void:
	_fill()
	var feed := _game.hud.notifications
	feed.push(feed.watcher.event_started(&"fair_wind", -1))
	feed.push(feed.watcher.event_started(&"good_harvest", 0))
	feed.push(feed.watcher.mission_offered(1))
	feed.push(feed.watcher.mission_completed(&"planks", 720))
	feed.push(feed.watcher.mission_expired(&"fish"))
	await _check("notificações")
	var notices := feed.shown()
	assert_int(notices.size()).is_equal(5)
	for notice: NoticeWatcher.Notice in notices:
		assert_bool(Icons.has(notice.icon)).override_failure_message(notice.icon).is_true()
	for notice: NoticeWatcher.Notice in notices:
		if notice.key == "mission/offer":
			_game.go_to(notice)
	assert_bool(_game.hud.mission_window.visible).is_true()


func test_every_event_has_an_icon_title_and_description() -> void:
	for def: EventDef in _sim.data.events:
		assert_bool(Icons.has(MissionWindow.event_icon(def.id))).override_failure_message(String(def.id)).is_true()
		for locale: String in ["pt_BR", "en"]:
			TranslationServer.set_locale(locale)
			assert_str(tr(def.title_key())).is_not_equal(def.title_key())
			assert_str(tr(def.description_key())).is_not_equal(def.description_key())
		TranslationServer.set_locale("pt_BR")
		var event := WorldEvent.new()
		event.def = def
		event.def_id = def.id
		event.good = &"bricks"
		var text := MissionWindow.event_description(event, _sim.data)
		assert_object(_format.search(text)).override_failure_message(text).is_null()


func test_new_game_dialog_offers_events_on_by_default() -> void:
	var dialog := NewGameDialog.new()
	Modal.open(_game._ui_layer, dialog)
	assert_bool(dialog.events_check.button_pressed).is_true()
	await _check("jogo novo")
	_game._close_all_modals()


func test_diplomacy_window_shows_the_rivals_and_their_gestures() -> void:
	var hud := _game.hud
	hud._refresh()
	assert_bool((hud.find_child("RivalsButton", true, false) as Button).visible).is_false()
	_sim.world.rivals_state.start(_sim.data, _sim.config)
	_sim.world.money = 100000.0
	hud._refresh()
	assert_bool((hud.find_child("RivalsButton", true, false) as Button).visible).is_true()
	hud.toggle_rivals()
	await _check("rivais")
	var window := hud.diplomacy_window
	for def: RivalDef in _sim.data.rivals:
		assert_object(window.find_child("Rival_" + String(def.id), true, false)).is_not_null()
	var row := window.find_child("Rival_hanseatic", true, false)
	var gift := row.find_child("Action_%d" % DiplomacyCommand.Action.GIFT, true, false) as Button
	assert_bool(gift.disabled).is_false()
	gift.pressed.emit()
	await _runner.simulate_frames(2)
	row = window.find_child("Rival_hanseatic", true, false)
	# depois do presente, o próximo espera: o botão desliga com o motivo na dica
	gift = row.find_child("Action_%d" % DiplomacyCommand.Action.GIFT, true, false) as Button
	assert_bool(gift.disabled).is_true()
	assert_str(gift.tooltip_text).contains(tr(DiplomacyCommand.TOO_SOON))
	var war := row.find_child("Action_%d" % DiplomacyCommand.Action.DECLARE_WAR, true, false) as Button
	war.pressed.emit()
	await _runner.simulate_frames(2)
	assert_int(_sim.world.rivals_state.by_id(&"hanseatic").stance).is_equal(RivalState.Stance.WAR)
	row = window.find_child("Rival_hanseatic", true, false)
	assert_object(row.find_child("Action_%d" % DiplomacyCommand.Action.PROPOSE_PEACE, true, false)).is_not_null()
	await _check("rivais em guerra")
	var feed := _game.hud.notifications
	feed.push(feed.watcher.rival_stance(&"ironside", RivalState.Stance.WAR))
	feed.push(feed.watcher.rival_colonized(&"verdant", 0))
	await _check("avisos das rivais")
	assert_bool(hud.close_top_window()).is_true()


func test_new_game_dialog_offers_rivals_on_by_default() -> void:
	var dialog := NewGameDialog.new()
	Modal.open(_game._ui_layer, dialog)
	assert_bool(dialog.rivals_check.button_pressed).is_true()
	_game._close_all_modals()
