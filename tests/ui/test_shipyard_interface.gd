extends GdUnitTestSuite
## Estaleiro na tela: a dica do menu, o painel com um botão por navio (custo e tempo na dica, motivo
## quando não dá), a encomenda em andamento com o cancelar, e o aviso do navio pronto. Tudo com ícone e
## tradução.

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


func test_shipyard_panel_orders_and_cancels() -> void:
	DemoVillage.build(_sim)
	_sim.free_build = true
	var grid := _sim.world.island(0)
	var site := SiteFinder.find(_sim, &"shipyard", 0, grid.size / 2)
	assert_bool(site.is_empty()).is_false()
	var origin: Vector2i = site[0]
	var rotation: int = site[1]
	var yard := _sim.execute(PlaceBuildingCommand.new(0, &"shipyard", origin, rotation)).placed[0]
	var def := _sim.data.building(&"shipyard")
	assert_bool(Icons.has("building_shipyard")).is_true()
	var tip: String = _game.hud.call(&"_tooltip", def)
	assert_object(_format.search(tip)).override_failure_message(tip).is_null()
	_game.tool.select(yard)
	await _runner.simulate_frames(3)
	var panel := _game.hud.selection_panel
	for ship_id: StringName in def.shipyard_ships:
		var button := panel.find_child("Order_" + ship_id, true, false) as Button
		assert_object(button).override_failure_message(String(ship_id)).is_not_null()
		assert_object(button.icon).override_failure_message(String(ship_id)).is_not_null()
	await _check("estaleiro sem encomenda")
	(panel.find_child("Order_merchant_ship", true, false) as Button).pressed.emit()
	await _runner.simulate_frames(3)
	assert_object(_sim.world.shipyard_state.order(yard)).is_not_null()
	var cancel := panel.find_child("CancelOrder", true, false) as Button
	assert_bool(cancel.is_visible_in_tree()).is_true()
	assert_bool((panel.find_child("Order_clipper", true, false) as Button).is_visible_in_tree()).is_false()
	await _check("estaleiro com encomenda")
	cancel.pressed.emit()
	await _runner.simulate_frames(3)
	assert_object(_sim.world.shipyard_state.order(yard)).is_null()


func test_ship_built_notice_has_icon_and_text() -> void:
	DemoVillage.build(_sim)
	var ship_id := 0
	for ship: Ship in _sim.world.player_ships():
		ship_id = ship.id
	assert_int(ship_id).is_not_equal(0)
	var feed := _game.hud.notifications
	feed.push(feed.watcher.ship_built(ship_id))
	await _check("aviso do navio pronto")
	for notice: NoticeWatcher.Notice in feed.shown():
		assert_bool(Icons.has(notice.icon)).override_failure_message(notice.icon).is_true()
