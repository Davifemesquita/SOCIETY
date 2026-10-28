extends GdUnitTestSuite
## A prefeitura na tela (Fase 66): no menu, na aba dos serviços, com ícone; o painel dela mostra a política e o alcance,
## um botão por política (marcado o da escolhida, desligado o bloqueado) e o de tirar; escolher pelo botão muda a
## política. Tudo com ícone e tradução.

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


func test_the_panel_chooses_a_policy() -> void:
	_sim.free_build = true
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(40, 70), Vector2i(90, 70))))
	var result := _sim.execute(PlaceBuildingCommand.new(0, &"town_hall", Vector2i(60, 66), 2))
	assert_bool(result.ok()).is_true()
	var hall: int = result.placed[0]
	_sim.free_build = false
	_game.tool.select(hall)
	await _runner.simulate_frames(3)
	var panel := _game.hud.selection_panel
	assert_bool(panel.visible).is_true()
	var problems := _problems(panel)
	assert_array(Array(problems)).override_failure_message("\n".join(problems)).is_empty()
	var holidays := panel.find_child("Policy_holidays", true, false) as Button
	assert_object(holidays).is_not_null()
	assert_bool(holidays.button_pressed).is_false()
	# a coletoria pede um marco
	assert_bool((panel.find_child("Policy_tax_office", true, false) as Button).disabled).is_true()
	holidays.pressed.emit()
	await _runner.simulate_frames(3)
	assert_str(String(_sim.world.building(hall).policy)).is_equal("holidays")
	assert_bool(holidays.button_pressed).is_true()
	problems = _problems(panel)
	assert_array(Array(problems)).override_failure_message("\n".join(problems)).is_empty()
	(panel.find_child("PolicyClear", true, false) as Button).pressed.emit()
	await _runner.simulate_frames(2)
	assert_str(String(_sim.world.building(hall).policy)).is_equal("")


func test_the_town_hall_is_in_the_services_tab() -> void:
	var groups: Array[Array] = _game.hud._categories()
	var services: Array = groups[_sim.data.tiers.size() + 1]
	assert_bool(services.any(func(def: BuildingDef) -> bool: return def.id == &"town_hall")).is_true()
	assert_object(Icons.building(&"town_hall")).is_not_null()
	assert_str(SelectionPanel.policy_effect(_sim.data.policy(&"fire_watch"))).contains("60")
