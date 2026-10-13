extends GdUnitTestSuite
## Interface da Fase 6 com a partida de verdade (ilha plana): o navio inicial aparece no mar e o
## clique nele abre o painel; "navegar para" e o clique numa ilha mandam o navio; a janela de
## rotas cria a rota, as paradas, as ordens e põe o navio nela; o painel do entreposto compra navio
## e abre o comércio com o comerciante.

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


func _screen_of(ship: Ship) -> Vector2:
	_game.camera.rig.center_on(Vector3(ship.position.x, 0.0, ship.position.y))
	_game.camera.rig.focus = Vector3(ship.position.x, 0.0, ship.position.y)
	_game.camera.apply()
	return _game.camera.camera.unproject_position(Vector3(ship.position.x, ShipView.HULL_HEIGHT_M, ship.position.y))


func _labels(panel: Control) -> String:
	return " | ".join(panel.find_children("*", "Label", true, false).map(func(label: Label) -> String: return label.text))


func test_clicking_the_starting_ship_selects_it_and_shows_its_hold() -> void:
	var ship := _sim.world.player_ships()[0]
	# o mouse longe da borda: senão a câmera anda sozinha (pan pela borda da tela)
	_runner.simulate_mouse_move(Vector2(960, 540))
	await _runner.simulate_frames(2)
	assert_int(_game.ship_view.ship_count()).is_equal(1)
	var spot := _screen_of(ship)
	await _runner.simulate_frames(2)
	spot = _game.camera.camera.unproject_position(_game.ship_view.ship_node(ship.id).position + Vector3(0.0, ShipView.HULL_HEIGHT_M, 0.0))
	_runner.simulate_mouse_move(spot)
	_runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	await _runner.simulate_frames(3)
	assert_int(_game.tool.selected_ship).is_equal(ship.id)
	assert_int(_game.tool.selected_id).is_equal(0)
	assert_bool(_game.hud.ship_panel.visible).is_true()
	assert_bool(_game.hud.selection_panel.visible).is_false()
	await _runner.simulate_frames(20)
	assert_str(_labels(_game.hud.ship_panel)).contains(tr(_sim.data.good(&"planks").name_key))


func test_sail_to_sends_the_ship_to_the_clicked_island() -> void:
	var ship := _sim.world.player_ships()[0]
	_game.tool.select_ship(ship.id)
	_game.hud.ship_panel.find_child("SailTo", true, false).emit_signal(&"pressed")
	assert_int(_game.tool.mode).is_equal(BuildTool.Mode.SAIL_TO)
	# o posto do comerciante, pela tela
	var post := _sim.harbors().trader_post
	_game.camera.rig.focus = Vector3(post.x, 0.0, post.y)
	_game.camera.apply()
	await _runner.simulate_frames(2)
	var spot := _game.camera.camera.unproject_position(Vector3(post.x, 2.0, post.y))
	assert_bool(_game.ship_picker.click(spot)).is_true()
	assert_int(_game.tool.mode).is_equal(BuildTool.Mode.NONE)
	assert_int(ship.destination).is_equal(Ship.TRADER_POST)
	assert_int(ship.state).is_equal(Ship.State.SAILING)


func test_route_window_builds_a_route_and_puts_the_ship_on_it() -> void:
	_sim.execute(PlaceBuildingCommand.new(0, &"trading_post", Vector2i(100, 0), 2))
	var window := _game.hud.route_window
	_game.hud.find_child("Routes", true, false).emit_signal(&"pressed")
	assert_bool(window.visible).is_true()
	window.find_child("NewRoute", true, false).emit_signal(&"pressed")
	assert_int(_sim.world.routes.size()).is_equal(1)
	var route: TradeRoute = _sim.world.routes.values()[0]
	window.find_child("AddStop", true, false).emit_signal(&"pressed")
	window.find_child("AddStop", true, false).emit_signal(&"pressed")
	await _runner.simulate_frames(2)
	assert_int(route.stops.size()).is_equal(2)
	window.find_child("Stop0", true, false).find_child("AddOrder", true, false).emit_signal(&"pressed")
	await _runner.simulate_frames(2)
	assert_int(route.stops[0].orders.size()).is_equal(1)
	var target: OptionButton = window.find_child("Stop1", true, false).find_child("Target", true, false)
	target.select(target.item_count - 1)
	target.item_selected.emit(target.item_count - 1)
	assert_int(route.stops[1].target).is_equal(Ship.TRADER_POST)
	var ship := _sim.world.player_ships()[0]
	var boxes := window.find_children("*", "CheckBox", true, false)
	assert_int(boxes.size()).is_equal(1)
	var box: CheckBox = boxes[0]
	box.button_pressed = true
	assert_int(ship.route_id).is_equal(route.id)
	await _runner.simulate_frames(2)
	window.map.queue_redraw()
	await _runner.simulate_frames(2)


func test_trading_post_panel_buys_a_ship_and_opens_the_trade_window() -> void:
	var post := _sim.execute(PlaceBuildingCommand.new(0, &"trading_post", Vector2i(100, 0), 2)).placed[0]
	_sim.world.milestones_reached = 1
	_sim.world.economy(0).stock[&"planks"] = 50.0
	_game.tool.select(post)
	await _runner.simulate_frames(2)
	var panel := _game.hud.selection_panel
	panel.find_child("BuyShip", true, false).emit_signal(&"pressed")
	assert_int(_sim.world.player_ships().size()).is_equal(2)
	# o navio comprado fica selecionado
	assert_int(_game.tool.selected_ship).is_equal(_sim.world.player_ships()[1].id)
	_game.tool.select(post)
	await _runner.simulate_frames(2)
	panel.find_child("Trade", true, false).emit_signal(&"pressed")
	var trade := _game.hud.trade_window
	assert_bool(trade.visible).is_true()
	await _runner.simulate_frames(2)
	var fish: Control = trade.find_child("Sell_fish", true, false)
	var check: CheckBox = fish.get_child(0)
	check.button_pressed = true
	assert_bool(_sim.world.economy(0).sell_above.has(&"fish")).is_true()
	var amount: SpinBox = fish.get_child(1)
	amount.value = 35
	assert_int(_sim.world.economy(0).sell_above[&"fish"]).is_equal(35)
