class_name TraderVisits
extends RefCounted
## O navio do comerciante neutro (comércio passivo, seção 6). Espera no posto dele, em mar
## aberto, visit_interval_s; então sorteia os preços da volta e passa por cada ilha com
## entreposto, na ordem dos índices. Em cada uma fica dwell_s ancorado (sem ocupar vaga do
## jogador) e negocia pelos ajustes da ilha: vende ao jogador o que falta até "comprar até" e
## compra o que passa de "vender acima de", até max_tons_per_visit por bem. Depois volta ao posto.
## Ele só aparece quando existe o primeiro entreposto.


## Cria o navio do comerciante no posto, se ainda não existe e já há entreposto.
static func ensure_ship(world: WorldState, data: GameData, harbors: Harbors) -> void:
	var trader := data.trader()
	if trader == null or world.trader.ship_id != 0 or not world.any_trading_post(data):
		return
	var ship := Ship.new(world.next_ship_id, data.ship(trader.ship), Ship.Owner.TRADER)
	world.next_ship_id += 1
	ship.at = Ship.TRADER_POST
	ship.position = harbors.target_point(Ship.TRADER_POST, Ship.Owner.TRADER)
	ship.previous_position = ship.position
	world.ships[ship.id] = ship
	world.trader.ship_id = ship.id
	world.trader.wait_left = trader.visit_interval_s


## Parado: no posto, conta a espera e começa a volta; numa ilha (save antigo), segue a volta.
static func idle(world: WorldState, data: GameData, harbors: Harbors, ship: Ship, dt: float) -> void:
	var trader := data.trader()
	var state := world.trader
	# fora do posto (numa ilha, ou parado no mar sem caminho), segue a volta
	if ship.at != Ship.TRADER_POST:
		_go_on(world, harbors, ship)
		return
	state.wait_left -= dt
	if state.wait_left > 0.0:
		return
	state.tour += 1
	state.visits.clear()
	for island_id: int in world.islands.size():
		if world.has_trading_post(island_id, data):
			state.visits.append(island_id)
	state.next_visit = 0
	_go_on(world, harbors, ship)
	if ship.state == Ship.State.IDLE:
		state.wait_left = trader.visit_interval_s


## Chegou: no posto, espera a próxima volta; numa ilha, fica ancorado o tempo da visita.
static func arrived(world: WorldState, data: GameData, ship: Ship) -> void:
	var trader := data.trader()
	if ship.at == Ship.TRADER_POST:
		ship.stop()
		world.trader.wait_left = trader.visit_interval_s
		return
	ship.state = Ship.State.DOCKED
	ship.berth_id = 0
	ship.timer = trader.dwell_s


## Fim da visita: negocia e segue para a próxima ilha (ou volta ao posto).
static func leave(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState, harbors: Harbors, ship: Ship) -> void:
	if ship.at >= 0 and world.has_trading_post(ship.at, data):
		trade_passive(world, data, config, derived, ship.at)
	ship.stop()
	_go_on(world, harbors, ship)


## Próxima ilha da volta que ainda tem entreposto; acabou a lista, volta ao posto.
static func _go_on(world: WorldState, harbors: Harbors, ship: Ship) -> void:
	var state := world.trader
	while state.next_visit < state.visits.size():
		var island_id := state.visits[state.next_visit]
		state.next_visit += 1
		if not harbors.berths(island_id).is_empty():
			ShipSystem.depart(harbors, ship, island_id)
			return
	if ship.at != Ship.TRADER_POST:
		ShipSystem.depart(harbors, ship, Ship.TRADER_POST)


## Comércio passivo numa ilha pelos ajustes dela. Devolve [vendido pelo jogador, comprado pelo
## jogador] em moedas.
static func trade_passive(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState, island_id: int) -> Array[float]:
	var trader := data.trader()
	var economy := world.economy(island_id)
	var storage: float = derived.capacity.get(island_id, float(config.island_storage_capacity_t))
	var earned := 0.0
	var spent := 0.0
	for good: StringName in trader.buys:
		if not economy.sell_above.has(good):
			continue
		var tons := minf(economy.amount(good) - economy.sell_above[good], trader.max_tons_per_visit)
		if tons <= 0.000001:
			continue
		var unit := world.trader_price(data, config, good)
		economy.take(good, tons)
		earned += tons * unit
	world.money += earned
	for good: StringName in trader.sells:
		if not economy.buy_up_to.has(good):
			continue
		var unit := world.trader_price(data, config, good)
		var tons := minf(minf(economy.buy_up_to[good] - economy.amount(good), float(trader.max_tons_per_visit)),
				storage - economy.amount(good))
		tons = minf(tons, maxf(world.money, 0.0) / unit)
		if tons <= 0.000001:
			continue
		economy.add(good, tons, storage)
		world.money -= tons * unit
		spent += tons * unit
	if earned > 0.0 or spent > 0.0:
		EventBus.trader_visited.emit(island_id, earned, spent)
	return [earned, spent]
