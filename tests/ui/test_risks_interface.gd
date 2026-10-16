extends GdUnitTestSuite
## Riscos na tela (seção 8): a caixa do jogo novo, o quartel e o hospital no menu com a dica, a linha
## dos riscos no painel (em chamas, doente, protegido ou não), o painel do quartel, os avisos de fogo,
## perda e doença com ícone e o fogo desenhado no prédio. Tudo com ícone e tradução.

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


## A vila de demonstração com os riscos ligados e um quartel na rua dela.
func _village() -> Dictionary:
	DemoVillage.build(_sim)
	_sim.free_build = true
	_sim.world.risks_state.enabled = true
	var house := 0
	var factory := 0
	for building_id: int in _sim.world.building_ids():
		var record := _sim.world.building(building_id)
		if record.is_house() and house == 0:
			house = building_id
		elif _sim.def_of(record).is_production() and _sim.def_of(record).can_burn() and factory == 0:
			factory = building_id
	return {"house": house, "factory": factory}


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


func test_new_game_dialog_offers_risks_on_by_default() -> void:
	var dialog := NewGameDialog.new()
	Modal.open(_game._ui_layer, dialog)
	assert_bool(dialog.risks_check.button_pressed).is_true()
	await _check("jogo novo")
	_game._close_all_modals()


func test_fire_station_and_hospital_have_icon_name_and_tip() -> void:
	for def_id: StringName in [&"fire_station", &"hospital"]:
		var def := _sim.data.building(def_id)
		assert_bool(Icons.has("building_" + def_id)).override_failure_message(String(def_id)).is_true()
		for locale: String in ["pt_BR", "en"]:
			TranslationServer.set_locale(locale)
			assert_str(tr(def.name_key)).is_not_equal(def.name_key)
		TranslationServer.set_locale("pt_BR")
		var tip: String = _game.hud.call(&"_tooltip", def)
		assert_str(tip).contains(tr("TIP_PROTECTS_FIRE" if def.protects == BuildingDef.Hazard.FIRE else "TIP_PROTECTS_DISEASE").get_slice("%", 0))
		assert_object(_format.search(tip)).override_failure_message(tip).is_null()


func test_panel_shows_fire_disease_and_protection() -> void:
	var picked := _village()
	var house: int = picked["house"]
	var factory: int = picked["factory"]
	assert_int(house).is_not_equal(0)
	assert_int(factory).is_not_equal(0)
	var panel := _game.hud.selection_panel
	_game.tool.select(house)
	await _runner.simulate_frames(3)
	assert_bool(_panel_text(panel).contains(tr("HOUSE_FIRE_PROTECTION") % tr("RISK_UNCOVERED"))).is_true()
	await _check("casa sem bombeiros")
	RiskSystem.infect(_sim.world, house)
	_game.tool.select(0)
	_game.tool.select(house)
	await _runner.simulate_frames(3)
	assert_bool(_panel_text(panel).contains(tr("HOUSE_SICK"))).is_true()
	await _check("casa doente")
	_sim.world.risks_state.outbreaks.clear()
	RiskSystem.ignite(_sim.world, factory)
	_sim.run_ticks(1)
	_game.tool.select(0)
	_game.tool.select(factory)
	await _runner.simulate_frames(3)
	assert_bool(_panel_text(panel).contains(tr("STATE_ON_FIRE"))).is_true()
	await _check("fábrica em chamas")
	assert_int(_game.fire_view.burning_count()).is_equal(1)


func test_fire_station_panel_counts_what_it_protects() -> void:
	_village()
	var station := 0
	var grid := _sim.world.island(0)
	var def := _sim.data.building(&"fire_station")
	for y: int in range(0, grid.size.y - def.size.y):
		for x: int in range(0, grid.size.x - def.size.x):
			if _sim.placement_reason(def, Vector2i(x, y), 0) == PlacementRules.OK:
				var result := _sim.execute(PlaceBuildingCommand.new(0, &"fire_station", Vector2i(x, y), 0))
				if result.ok() and _sim.has_road_access(result.placed[0]):
					station = result.placed[0]
					break
				if result.ok():
					_sim.execute(DemolishCommand.new(0, Rect2i(Vector2i(x, y), Vector2i.ONE)))
		if station != 0:
			break
	assert_int(station).is_not_equal(0)
	_game.tool.select(station)
	await _runner.simulate_frames(3)
	var guarded: Array = _sim.derived_state().protected_by.get(station, [])
	assert_int(guarded.size()).is_greater(0)
	assert_bool(_panel_text(_game.hud.selection_panel).contains(tr("SERVICE_PROTECTS") % Fmt.integer(guarded.size()))).is_true()
	await _check("quartel")


func test_risk_notices_have_icons_and_text() -> void:
	var picked := _village()
	var house: int = picked["house"]
	var factory: int = picked["factory"]
	var feed := _game.hud.notifications
	feed.push(feed.watcher.fire_started(factory))
	feed.push(feed.watcher.outbreak(house))
	feed.push(feed.watcher.fire_out(house))
	feed.push(feed.watcher.building_lost(999, &"bakery", 0))
	await _check("avisos dos riscos")
	var notices := feed.shown()
	assert_int(notices.size()).is_greater_equal(3)
	for notice: NoticeWatcher.Notice in notices:
		assert_bool(Icons.has(notice.icon)).override_failure_message(notice.icon).is_true()
		assert_object(_format.search(notice.text())).override_failure_message(notice.text()).is_null()


func test_lost_building_leaves_the_screen_and_the_selection() -> void:
	var picked := _village()
	var factory: int = picked["factory"]
	_game.tool.select(factory)
	RiskSystem.ignite(_sim.world, factory)
	_sim.run_ticks(1)
	await _runner.simulate_frames(2)
	assert_int(_game.fire_view.burning_count()).is_equal(1)
	_sim.world.risks_state.fires[factory] = _sim.world.tick - _sim.config.ticks_of(_sim.config.fire_burnout_s) - 30
	_sim.run_ticks(_sim.config.risk_check_ticks)
	await _runner.simulate_frames(3)
	assert_object(_sim.world.building(factory)).is_null()
	assert_int(_game.fire_view.burning_count()).is_equal(0)
	assert_bool(_game.hud.selection_panel.visible).is_false()


func _panel_text(panel: Control) -> String:
	var parts: PackedStringArray = []
	for node: Node in panel.find_children("*", "Label", true, false):
		var label: Label = node
		if label.is_visible_in_tree():
			parts.append(label.text)
	return "\n".join(parts)
