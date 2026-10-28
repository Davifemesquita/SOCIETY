extends GdUnitTestSuite
## As expedições na tela (Fase 69): o navio parado num porto da companhia tem um botão por destino (o bloqueado
## desligado), mandar pelo botão tira o navio do mapa e põe a viagem na janela das encomendas com o tempo da volta; a
## volta vira aviso da frota. Tudo com ícone e tradução.

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


func test_send_a_ship_on_an_expedition() -> void:
	_sim.free_build = true
	assert_bool(_sim.execute(PlaceBuildingCommand.new(0, &"trading_post", Vector2i(60, 0), 2)).ok()).is_true()
	var bought := _sim.execute(BuyShipCommand.new(0))
	assert_bool(bought.ok()).is_true()
	_sim.free_build = false
	_sim.world.money = 100000.0
	var ship_id: int = bought.created_id
	var ship := _sim.world.ship(ship_id)
	ship.stop()
	ship.at = 0
	_game.tool.select_ship(ship_id)
	await _runner.simulate_frames(3)
	var panel := _game.hud.find_child("ShipPanel", true, false)
	if panel == null:
		for node: Node in _game.hud.find_children("*", "PanelContainer", true, false):
			if node is ShipPanel:
				panel = node
	assert_object(panel).is_not_null()
	var spice := panel.find_child("Expedition_spice_islands", true, false) as Button
	assert_object(spice).is_not_null()
	assert_bool(spice.disabled).is_false()
	assert_str(spice.tooltip_text).contains(Fmt.integer(_sim.data.expedition(&"spice_islands").cost_money))
	assert_bool((panel.find_child("Expedition_northern_seas", true, false) as Button).disabled).is_true()
	spice.pressed.emit()
	await _runner.simulate_frames(3)
	assert_object(_sim.world.ship(ship_id)).is_null()
	assert_int(_sim.world.expeditions_state.trips.size()).is_equal(1)
	_game.hud.toggle_missions()
	await _runner.simulate_frames(3)
	var row := _game.hud.mission_window.find_child("Trip_0", true, false)
	assert_object(row).is_not_null()
	# a volta vira aviso da frota que abre a janela
	var notice := _game.hud.notifications.watcher.expedition_returned(&"spice_islands", ExpeditionSystem.Outcome.LOST, &"")
	assert_int(notice.status).is_equal(UiPalette.Status.BAD)
	assert_str(NotificationFeed.category_of(notice.key)).is_equal("fleet")
	assert_str(notice.text()).contains(tr("EXPEDITION_SPICE_ISLANDS"))
	assert_str(ShipPanel.expedition_tip(_sim.data.expedition(&"savanna_coast"))).contains(tr("EXPEDITION_REWARD_ANIMAL"))
