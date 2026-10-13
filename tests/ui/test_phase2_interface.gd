extends GdUnitTestSuite
## Interface da Fase 2 com a partida de verdade: menu por categoria com bloqueio, painel de
## produção (pausar), painel da casa (bloquear upgrade), estatísticas no Tab, destaque do
## raio de serviço e dinheiro na barra superior.

const GAME := "res://ui/screens/game_screen.tscn"

var _runner: GdUnitSceneRunner
var _game: GameScreen


func before_test() -> void:
	GameScreen.use_sky3d = false
	GameScreen.flat_world = true
	GameScreen.load_slot_on_start = ""
	_runner = scene_runner(GAME)
	_game = _runner.scene()
	GameClock.set_speed(TickClock.PAUSED)
	await _runner.simulate_frames(2)


func after_test() -> void:
	GameScreen.use_sky3d = true
	GameScreen.flat_world = false


func _buttons_with_text(root: Node, text: String) -> Array[Button]:
	var found: Array[Button] = []
	for node: Node in root.find_children("*", "Button", true, false):
		var button: Button = node
		if button.text == text and button.is_visible_in_tree():
			found.append(button)
	return found


func test_locked_buildings_are_disabled_until_population() -> void:
	_game.hud._select_category(1)
	await _runner.simulate_frames(2)
	var weavery := _buttons_with_text(_game.hud, "BUILDING_WEAVERY")
	var lumberjack := _buttons_with_text(_game.hud, "BUILDING_LUMBERJACK")
	assert_int(weavery.size()).is_equal(1)
	assert_bool(weavery[0].disabled).is_true()
	assert_bool(lumberjack[0].disabled).is_false()
	assert_str(weavery[0].tooltip_text).contains(tr("BUILDING_WEAVERY"))


func test_production_panel_pauses_the_building() -> void:
	var sim := _game.simulation
	sim.free_build = true
	var sawmill := sim.execute(PlaceBuildingCommand.new(0, &"sawmill", Vector2i(100, 100), 0)).placed[0]
	_game.tool.select(sawmill)
	await _runner.simulate_frames(2)
	var pause := _buttons_with_text(_game.hud.selection_panel, tr("PANEL_PAUSE"))
	assert_int(pause.size()).is_equal(1)
	pause[0].pressed.emit()
	assert_bool(sim.world.building(sawmill).paused).is_true()


func test_house_panel_blocks_upgrade() -> void:
	var sim := _game.simulation
	sim.free_build = true
	var house := sim.execute(PlaceBuildingCommand.new(0, &"house", Vector2i(100, 100), 0)).placed[0]
	_game.tool.select(house)
	await _runner.simulate_frames(2)
	var boxes := _game.hud.selection_panel.find_children("*", "CheckBox", true, false)
	assert_int(boxes.size()).is_equal(1)
	var block: CheckBox = boxes[0]
	block.button_pressed = true
	assert_bool(sim.world.building(house).upgrade_blocked).is_true()


func test_tab_opens_statistics_with_the_stock() -> void:
	_runner.simulate_key_pressed(KEY_TAB)
	await _runner.simulate_frames(40, 16)
	assert_bool(_game.hud.statistics_window.visible).is_true()
	var planks := _game.hud.statistics_window.find_children("*", "Label", true, false).filter(
			func(label: Label) -> bool: return label.text == tr("GOOD_PLANKS"))
	assert_int(planks.size()).is_equal(1)
	_runner.simulate_key_pressed(KEY_TAB)
	await _runner.await_input_processed()
	assert_bool(_game.hud.statistics_window.visible).is_false()


func test_placing_a_market_highlights_its_reach() -> void:
	var sim := _game.simulation
	sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(90, 99), Vector2i(130, 99))))
	_game.tool.start_building(sim.data.building(&"market"))
	_game.tool.hover(Vector2i(110, 101))
	await _runner.simulate_frames(2)
	assert_bool(_game.overlay.has_custom()).is_true()
	_game.tool.cancel()
	await _runner.simulate_frames(2)
	assert_bool(_game.overlay.has_custom()).is_false()


func test_top_bar_shows_money() -> void:
	await _runner.simulate_frames(40, 16)
	var labels := _game.hud.find_children("*", "Label", true, false).filter(
			func(label: Label) -> bool: return label.text.begins_with(tr("HUD_MONEY").split(" ")[0]))
	assert_int(labels.size()).is_equal(1)
	var money: Label = labels[0]
	assert_str(money.text).contains("50.000")
