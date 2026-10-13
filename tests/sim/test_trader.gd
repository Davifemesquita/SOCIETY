extends GdUnitTestSuite
## Comerciante neutro (Fase 6): preço base com variação de até ±10% sorteada por volta (a mesma
## semente dá o mesmo preço), o navio dele aparece com o primeiro entreposto e visita os portos
## vendendo e comprando pelos ajustes da ilha, e o jogador negocia no posto dele.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.two_islands()


func test_prices_vary_up_to_ten_percent_and_repeat_for_the_same_tour() -> void:
	var fish := _sim.data.good(&"fish")
	var seen: Dictionary[float, bool] = {}
	for tour: int in 40:
		var price := TraderState.price(1840, tour, fish, 0.1)
		assert_float(price).is_between(fish.base_price * 0.9, fish.base_price * 1.1)
		assert_float(TraderState.price(1840, tour, fish, 0.1)).is_equal(price)
		seen[price] = true
	assert_int(seen.size()).is_greater(30)


func test_trader_ship_appears_with_the_first_trading_post_at_its_post() -> void:
	SimFixture.run(_sim, 0.2)
	var trader := _sim.world.ship(_sim.world.trader.ship_id)
	assert_object(trader).is_not_null()
	assert_int(trader.owner).is_equal(Ship.Owner.TRADER)
	assert_int(trader.at).is_equal(Ship.TRADER_POST)
	assert_float(trader.position.distance_to(_sim.harbors().target_point(Ship.TRADER_POST, Ship.Owner.TRADER))).is_less(0.01)
	# ancorado ao lado da plataforma, não em cima dela nem no lugar dos navios do jogador
	assert_float(trader.position.distance_to(_sim.harbors().trader_post)).is_greater(10.0)
	assert_float(trader.position.distance_to(_sim.harbors().target_point(Ship.TRADER_POST))).is_greater(10.0)
	# sem upkeep: o navio dele não é do jogador
	assert_int(_sim.world.player_ships().size()).is_equal(0)


func test_passive_trade_sells_the_surplus_and_buys_up_to_the_target() -> void:
	var economy := _sim.world.economy(0)
	economy.stock[&"fish"] = 80.0
	economy.stock[&"planks"] = 5.0
	_sim.execute(SetTradeSettingCommand.new(0, &"fish", 50, -1))
	_sim.execute(SetTradeSettingCommand.new(0, &"planks", -1, 40))
	var trader_def := _sim.data.trader()
	var visits: Array[int] = []
	var deals: Array[float] = []
	EventBus.trader_visited.connect(func(island_id: int, earned: float, spent: float) -> void:
		visits.append(island_id)
		if island_id == 0:
			deals.append_array([earned, spent]))
	SimFixture.run_until(_sim, func() -> bool: return visits.has(0), trader_def.visit_interval_s + 600.0)
	assert_array(visits).contains([0])
	var tour := _sim.world.trader.tour
	var fish_price := TraderState.price(_sim.world.seed, tour, _sim.data.good(&"fish"), _sim.config.trader_price_variation)
	var plank_price := TraderState.price(_sim.world.seed, tour, _sim.data.good(&"planks"), _sim.config.trader_price_variation)
	# teto de 20 t por bem por visita: vende 20 dos 30 que passam de 50; compra 20 dos 35 que faltam
	assert_float(economy.amount(&"fish")).is_equal_approx(60.0, 0.0001)
	assert_float(economy.amount(&"planks")).is_equal_approx(25.0, 0.0001)
	assert_float(deals[0]).is_equal_approx(20.0 * fish_price, 0.01)
	assert_float(deals[1]).is_equal_approx(20.0 * plank_price, 0.01)


func test_player_trades_at_the_trader_post() -> void:
	var ship_id := SimFixture.ship(_sim, 0)
	var ship := _sim.world.ship(ship_id)
	SimFixture.run(_sim, 0.2)
	_sim.execute(MoveShipCommand.new(ship_id, Ship.TRADER_POST))
	SimFixture.run_until(_sim, func() -> bool: return ship.state == Ship.State.IDLE and ship.at == Ship.TRADER_POST, 900.0)
	assert_int(ship.at).is_equal(Ship.TRADER_POST)
	var money := _sim.world.money
	var price := TraderState.price(_sim.world.seed, _sim.world.trader.tour, _sim.data.good(&"planks"), _sim.config.trader_price_variation)
	assert_bool(_sim.execute(TradeWithTraderCommand.new(ship_id, &"planks", 30.0)).ok()).is_true()
	assert_float(ship.tons_of(&"planks")).is_equal(30.0)
	assert_float(money - _sim.world.money).is_equal_approx(30.0 * price, 0.01)
	assert_bool(_sim.execute(TradeWithTraderCommand.new(ship_id, &"planks", -10.0)).ok()).is_true()
	assert_float(ship.tons_of(&"planks")).is_equal(20.0)
	# ele não vende tijolo, e carga de ilha não vale no posto
	assert_str(_sim.execute(TradeWithTraderCommand.new(ship_id, &"bricks", 5.0)).reason).is_equal(ShipRules.NOT_TRADED)
	assert_str(_sim.execute(TransferCargoCommand.new(ship_id, &"planks", -5.0)).reason).is_equal(ShipRules.NOT_IN_PORT)


func test_buying_is_limited_by_the_money() -> void:
	var ship_id := SimFixture.ship(_sim, 0)
	var ship := _sim.world.ship(ship_id)
	ship.at = Ship.TRADER_POST
	_sim.world.money = 100.0
	_sim.execute(TradeWithTraderCommand.new(ship_id, &"planks", 50.0))
	assert_float(_sim.world.money).is_greater_equal(-0.0001)
	assert_float(_sim.world.money).is_less(1.0)
	assert_float(ship.tons_of(&"planks")).is_less(50.0)
