extends GdUnitTestSuite
## Interface da Fase 3 com a partida de verdade: o jogo novo pede o entreposto, a carroça
## aparece na estrada, cortar a estrada com a ferramenta de demolir acende o alerta, e o painel
## do armazém melhora o prédio.

const GAME := "res://ui/screens/game_screen.tscn"

var _runner: GdUnitSceneRunner
var _game: GameScreen
var _sim: Simulation


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


## Entreposto no litoral norte, estrada na frente dele e casas de camponeses.
func _start_port() -> int:
	var post := _sim.execute(PlaceBuildingCommand.new(0, &"trading_post", Vector2i(100, 0), 2)).placed[0]
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(90, 6), Vector2i(160, 6))))
	_sim.free_build = true
	for i: int in 3:
		var house := _sim.execute(PlaceBuildingCommand.new(0, &"house", Vector2i(140 + i * 3, 3), 2)).placed[0]
		_sim.world.building(house).residents = 10.0
	_sim.free_build = false
	return post


func test_new_game_asks_for_the_trading_post_first() -> void:
	assert_str(_game.hud._hint.text).is_equal(tr("HINT_BUILD_TRADING_POST"))
	_game.tool.start_building(_sim.data.building(&"lumberjack"))
	_game.tool.hover(Vector2i(120, 20))
	assert_str(_game.tool.preview_reason()).is_equal(PlacementRules.NEEDS_TRADING_POST)
	_start_port()
	_game.tool.hover(Vector2i(121, 8))
	assert_str(_game.tool.preview_reason()).is_equal(PlacementRules.OK)


func test_cart_shows_on_the_road_while_delivering() -> void:
	_start_port()
	var lumberjack := _sim.execute(PlaceBuildingCommand.new(0, &"lumberjack", Vector2i(125, 7), 0)).placed[0]
	_sim.run_ticks(80)
	assert_bool(_sim.world.cart(lumberjack).is_away()).is_true()
	await _runner.simulate_frames(3)
	assert_int(_game.cart_view.visible_carts()).is_equal(1)
	_game.tool.select(lumberjack)
	await _runner.simulate_frames(10)
	assert_str(_game.hud.selection_panel.find_children("*", "Label", true, false).map(
			func(label: Label) -> String: return label.text).filter(
			func(text: String) -> bool: return text.begins_with(tr("PANEL_CART_OUT").split(" %")[0])).front()).is_not_empty()


func test_cutting_the_road_with_the_demolish_tool_raises_the_alert() -> void:
	_start_port()
	var lumberjack := _sim.execute(PlaceBuildingCommand.new(0, &"lumberjack", Vector2i(125, 7), 0)).placed[0]
	_sim.run_ticks(10)
	await _runner.simulate_frames(3)
	assert_str(_game.building_view.label_text(lumberjack)).is_empty()
	_game.tool.start_demolish()
	_game.tool.press(Vector2i(115, 6))
	_game.tool.release(Vector2i(115, 6))
	_sim.run_ticks(2)
	await _runner.simulate_frames(40, 16)
	assert_str(_game.building_view.label_text(lumberjack)).is_equal(tr("LABEL_NO_WAREHOUSE"))


func test_warehouse_panel_upgrades_the_building() -> void:
	_start_port()
	_sim.free_build = true
	var warehouse := _sim.execute(PlaceBuildingCommand.new(0, &"warehouse", Vector2i(130, 7), 0)).placed[0]
	_game.tool.select(warehouse)
	await _runner.simulate_frames(10)
	var upgrade: Button = _game.hud.selection_panel.find_child("Upgrade", true, false)
	assert_object(upgrade).is_not_null()
	upgrade.pressed.emit()
	assert_int(_sim.world.building(warehouse).level).is_equal(1)
	assert_int(_sim.derived_state().ramps[warehouse]).is_equal(4)
