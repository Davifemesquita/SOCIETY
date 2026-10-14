extends GdUnitTestSuite
## Critério da Fase 7 (seção 16): "jogo 30 minutos sem ver texto de depuração nem botão sem
## ícone". A vila de demonstração roda 30 minutos de jogo; depois a interface inteira é aberta
## (barra, menu de construção com cada categoria e camada, painéis de cada tipo de prédio, navio,
## estatísticas em cada aba, rotas, comércio, notificações, menu da partida, opções em cada aba,
## salvar, carregar, jogo novo e créditos) e em cada tela visível se confere: todo botão tem ícone,
## todo texto que é chave tem tradução nas duas línguas, nenhum formato (%s, %d) ficou sem valor e
## não há texto 3D de depuração no mundo.

const GAME := "res://ui/screens/game_screen.tscn"
const TEST_SAVES := "user://test_phase7_saves"

var _runner: GdUnitSceneRunner
var _game: GameScreen
var _sim: Simulation
var _key := RegEx.create_from_string("^[A-Z][A-Z0-9]*_[A-Z0-9_]+$")
var _format := RegEx.create_from_string("%[0-9.]*[sdf]")
var _saves_before: String


func before_test() -> void:
	GameScreen.use_sky3d = false
	GameScreen.flat_world = true
	GameScreen.load_slot_on_start = ""
	_saves_before = SaveSystem.save_dir
	SaveSystem.save_dir = TEST_SAVES
	_runner = scene_runner(GAME)
	_game = _runner.scene()
	_sim = _game.simulation
	GameClock.set_speed(TickClock.PAUSED)
	await _runner.simulate_frames(2)


func after_test() -> void:
	GameScreen.use_sky3d = true
	GameScreen.flat_world = false
	for slot: String in SaveSystem.list_slots():
		SaveSystem.delete_slot(slot)
	DirAccess.remove_absolute(TEST_SAVES)
	SaveSystem.save_dir = _saves_before


## Tudo o que está errado na interface visível sob root.
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
				problems.append("botão sem ícone: %s (%s)" % [path, tr(button.text)])
		var texts: PackedStringArray = [control.tooltip_text]
		if control is Label:
			var label: Label = control
			texts.append(label.text)
		elif control is Button:
			var with_text: Button = control
			texts.append(with_text.text)
		if control is OptionButton:
			var option: OptionButton = control
			for item: int in option.item_count:
				texts.append(option.get_item_text(item))
		if control is ItemList:
			var list: ItemList = control
			for item: int in list.item_count:
				texts.append(list.get_item_text(item))
		for text: String in texts:
			problems.append_array(_text_problems(text, path))
	return problems


func _text_problems(text: String, path: String) -> PackedStringArray:
	var problems := PackedStringArray()
	if text.is_empty():
		return problems
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
	await _runner.simulate_frames(2)
	var problems := _problems(_game.hud.get_parent(), where)
	assert_array(Array(problems)).override_failure_message("\n".join(problems)).is_empty()


func _start_village() -> Dictionary:
	var ids := DemoVillage.build(_sim)
	_sim.free_build = false
	return ids


func test_thirty_minutes_of_play_without_debug_text_or_iconless_buttons() -> void:
	var ids := _start_village()
	var started := Time.get_ticks_msec()
	_sim.run_ticks(_sim.config.ticks_per_second * 60 * 30)
	GameClock.clock.tick_count = _sim.world.tick
	print("30 min de jogo em %d ms" % (Time.get_ticks_msec() - started))
	assert_int(_sim.world.history.size()).is_equal(30)
	await _check("barra")
	# nada de texto 3D de depuração no mundo: os motivos dos prédios são ícones
	assert_array(_game.find_children("*", "Label3D", true, false)).is_empty()
	for index: int in _game.hud._categories().size():
		_game.hud._select_category(index)
		await _check("categoria %d" % index)
	for layer: MapOverlays.Layer in MapOverlays.ICONS:
		_game.hud.set_overlay(layer)
		await _check("camada %d" % layer)
		assert_bool(_game.overlay.has_custom()).is_true()
	_game.hud.set_overlay(MapOverlays.Layer.NONE)
	for key: String in ["port", "fishery", "market", "sawmill", "warehouse"]:
		var building_id: int = ids[key]
		_game.tool.select(building_id)
		await _check("painel " + key)
	var houses: Array[int] = ids["houses"]
	_game.tool.select(houses[0])
	await _check("painel casa")
	var wheat: Array = ids["wheat"]
	var farm: int = wheat[0]
	_game.tool.select(farm)
	await _check("painel fazenda")
	_game.tool.select(0)
	var ship: Ship = _sim.world.player_ships()[0]
	_game.tool.select_ship(ship.id)
	await _check("painel navio")
	_game.tool.select_ship(0)
	_game.hud.toggle_statistics()
	for tab: int in 3:
		_game.hud.statistics_window._tabs.current_tab = tab
		await _check("estatísticas %d" % tab)
	_game.hud.statistics_window.visible = false
	_game.hud.toggle_routes()
	_game.hud.route_window.create_route()
	_game.hud.route_window.add_stop_to_route()
	await _check("rotas")
	_game.hud.route_window.visible = false
	_game.hud.trade_window.open(0)
	await _check("comércio")
	_game.hud.trade_window.visible = false


func test_notifications_menus_and_dialogs_have_icons_and_translations() -> void:
	_start_village()
	_sim.run_ticks(_sim.config.ticks_per_second * 60 * 5)
	var feed := _game.hud.notifications
	feed.push(feed.watcher.milestone(1))
	feed.push(feed.watcher.shortage(0, &"fish"))
	await _check("notificações")
	assert_int(feed.shown().size()).is_greater_equal(2)
	_game.open_menu()
	await _check("menu da partida")
	var options := OptionsDialog.new()
	Modal.open(_game._ui_layer, options)
	for tab: int in options.tabs.get_tab_count():
		options.tabs.current_tab = tab
		await _check("opções %d" % tab)
	options.close()
	_game.save_game("teste", "Teste")
	_game.open_save_dialog()
	await _check("salvar")
	_game._close_all_modals()
	_game.open_load_dialog()
	await _check("carregar")
	_game._close_all_modals()
	Modal.open(_game._ui_layer, NewGameDialog.new())
	await _check("jogo novo")
	_game._close_all_modals()
	Modal.open(_game._ui_layer, CreditsDialog.new())
	await _check("créditos")
	_game._close_all_modals()


func test_the_interface_also_works_in_english() -> void:
	_start_village()
	Settings.set_locale("en")
	Settings.apply()
	await _runner.simulate_frames(3)
	assert_str(_game.hud._category_buttons[0].text).is_equal("Residences")
	_game.hud.toggle_statistics()
	await _check("statistics")
	Settings.set_locale("pt_BR")
	Settings.apply()
	await _runner.simulate_frames(2)
	assert_str(_game.hud._category_buttons[0].text).is_equal("Residências")
