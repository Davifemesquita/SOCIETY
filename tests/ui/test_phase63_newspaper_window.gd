extends GdUnitTestSuite
## O jornal na tela (Fase 63): no alto da janela das encomendas, a manchete com o texto, o efeito e o tempo até a
## próxima edição; os botões de propaganda com o preço, que compram uma vez e ficam desligados depois; a edição nova
## vira aviso que abre a janela. Tudo com ícone e tradução.

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


## Uma edição já publicada com a manchete dada (sem esperar o sorteio).
func _publish(headline_id: StringName) -> void:
	var state := _sim.world.events_state
	state.enabled = true
	state.edition_count = 1
	state.next_edition_tick = _sim.world.tick + _sim.config.ticks_of(_sim.config.newspaper_interval_s)
	state.headline = _sim.data.headline(headline_id)
	state.headline_id = headline_id
	state.propaganda_used = false


func _problems(root: Node) -> PackedStringArray:
	var problems := PackedStringArray()
	for node: Node in [root] + root.find_children("*", "Control", true, false):
		if not node is Control or not (node as Control).is_visible_in_tree():
			continue
		var control: Control = node
		if control is Button and (control as Button).icon == null:
			problems.append("botão sem ícone: %s" % root.get_path_to(control))
		var texts: PackedStringArray = [control.tooltip_text]
		if control is Label:
			texts.append((control as Label).text)
		elif control is Button:
			texts.append((control as Button).text)
		for text: String in texts:
			if text.is_empty():
				continue
			var shown := text
			if _key.search(text) != null:
				for locale: String in ["pt_BR", "en"]:
					TranslationServer.set_locale(locale)
					if TranslationServer.translate(text) == text:
						problems.append("chave sem tradução (%s): %s" % [locale, text])
				TranslationServer.set_locale("pt_BR")
				shown = TranslationServer.translate(text)
			if _format.search(shown) != null:
				problems.append("formato sem valor: \"%s\"" % shown)
	return problems


func test_the_window_shows_the_headline_and_buys_propaganda_once() -> void:
	_publish(&"price_rumor")
	_game.hud.toggle_missions()
	await _runner.simulate_frames(3)
	var window := _game.hud.mission_window
	var paper := window.find_child("Newspaper", true, false) as Control
	assert_object(paper).is_not_null()
	assert_str((paper.find_child("Headline", true, false) as Label).text).is_equal("HEADLINE_PRICE_RUMOR")
	assert_str((paper.find_child("Effect", true, false) as Label).text).contains("5")
	await _runner.simulate_frames(40)
	assert_str((paper.find_child("NextEdition", true, false) as Label).text).is_not_empty()
	var problems := _problems(window)
	assert_array(Array(problems)).override_failure_message("\n".join(problems)).is_empty()
	var buy := paper.find_child("Buy_progress", true, false) as Button
	assert_object(buy).is_not_null()
	assert_bool(buy.disabled).is_false()
	assert_str(buy.text).contains(Fmt.integer(_sim.config.newspaper_propaganda_cost))
	var money := _sim.world.money
	buy.pressed.emit()
	await _runner.simulate_frames(2)
	var state := _sim.world.events_state
	assert_str(String(state.headline_id)).is_equal("progress")
	assert_float(_sim.world.money).is_equal_approx(money - _sim.config.newspaper_propaganda_cost, 0.001)
	paper = window.find_child("Newspaper", true, false) as Control
	assert_str((paper.find_child("Headline", true, false) as Label).text).is_equal("HEADLINE_PROGRESS")
	for node: Node in paper.find_child("Propaganda", true, false).get_children():
		assert_bool((node as Button).disabled).is_true()
	problems = _problems(window)
	assert_array(Array(problems)).override_failure_message("\n".join(problems)).is_empty()


func test_before_the_first_edition_and_with_events_off() -> void:
	_game.hud.toggle_missions()
	await _runner.simulate_frames(3)
	var paper := _game.hud.mission_window.find_child("Newspaper", true, false) as Control
	assert_object(paper.find_child("Headline", true, false)).is_null()
	var state := _sim.world.events_state
	state.enabled = true
	state.next_edition_tick = _sim.world.tick + 100
	_game.hud.mission_window.rebuild()
	await _runner.simulate_frames(3)
	paper = _game.hud.mission_window.find_child("Newspaper", true, false) as Control
	assert_object(paper.find_child("Headline", true, false)).is_null()
	assert_object(paper.find_child("NextEdition", true, false)).is_not_null()
	var problems := _problems(_game.hud.mission_window)
	assert_array(Array(problems)).override_failure_message("\n".join(problems)).is_empty()


func test_a_new_edition_becomes_a_notice_that_opens_the_window() -> void:
	_publish(&"harbor_praise")
	EventBus.newspaper_published.emit(&"harbor_praise")
	await _runner.simulate_frames(2)
	var feed := _game.hud.notifications
	assert_int(feed.count_of("newspaper/edition")).is_equal(1)
	var notice := feed.watcher.newspaper_published(&"harbor_praise")
	assert_bool(notice.opens_missions).is_true()
	assert_int(notice.status).is_equal(UiPalette.Status.GOOD)
	assert_str(notice.text()).contains(tr("HEADLINE_HARBOR_PRAISE"))
	assert_str(NotificationFeed.category_of(notice.key)).is_equal("missions")
