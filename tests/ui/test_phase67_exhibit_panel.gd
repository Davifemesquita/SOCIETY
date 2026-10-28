extends GdUnitTestSuite
## O zoológico na tela (Fase 67): o painel mostra as peças e a felicidade que elas dão, um botão por animal (o bloqueado
## desligado, o exposto marcado), e comprar pelo botão põe a peça e cobra. Tudo com ícone e tradução.

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


func test_the_panel_buys_and_shows_animals() -> void:
	_sim.free_build = true
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(40, 70), Vector2i(90, 70))))
	var result := _sim.execute(PlaceBuildingCommand.new(0, &"zoo", Vector2i(60, 64), 2))
	assert_bool(result.ok()).is_true()
	var zoo: int = result.placed[0]
	_sim.free_build = false
	_game.tool.select(zoo)
	await _runner.simulate_frames(3)
	var panel := _game.hud.selection_panel
	var problems := _problems(panel)
	assert_array(Array(problems)).override_failure_message("\n".join(problems)).is_empty()
	# só animais no zoológico; o leão pede um marco
	assert_object(panel.find_child("Exhibit_amphora", true, false)).is_null()
	assert_bool((panel.find_child("Exhibit_lion", true, false) as Button).disabled).is_true()
	var zebras := panel.find_child("Exhibit_zebras", true, false) as Button
	assert_bool(zebras.disabled).is_false()
	var money := _sim.world.money
	zebras.pressed.emit()
	await _runner.simulate_frames(3)
	assert_int(_sim.world.exhibits_state.placed[&"zebras"]).is_equal(zoo)
	assert_float(_sim.world.money).is_equal_approx(money - _sim.data.exhibit(&"zebras").price, 0.001)
	assert_bool(zebras.disabled).is_true()
	problems = _problems(panel)
	assert_array(Array(problems)).override_failure_message("\n".join(problems)).is_empty()
