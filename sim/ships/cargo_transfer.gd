class_name CargoTransfer
extends RefCounted
## Carga e descarga de um navio numa parada (seção 6). Na ilha: descarregar põe no estoque (o que
## couber) e carregar tira dele; no posto do comerciante: descarregar vende e carregar compra (o
## que o dinheiro pagar). Primeiro tudo o que desce, depois o que sobe. A venda no posto entrega
## primeiro às encomendas aceitas do bem (Fase 11), que pagam o prêmio ao se cumprirem. plan() estima as
## toneladas (o tempo no cais sai delas); execute() faz de verdade, com o que houver na hora.


## Toneladas que a parada vai mover, para o tempo no cais.
static func plan(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState, ship: Ship,
		stop: TradeRoute.Stop) -> float:
	var copy := _shadow(ship)
	var money := world.money
	var stock: Dictionary[StringName, float] = {}
	return _apply(world, data, config, derived, copy, stop, stock, money, false)


## Faz a parada; devolve as toneladas movidas.
static func execute(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState, ship: Ship,
		stop: TradeRoute.Stop) -> float:
	var unused: Dictionary[StringName, float] = {}
	return _apply(world, data, config, derived, ship, stop, unused, world.money, true)


## Uma ordem só (carga manual no porto ou comércio no posto); tons > 0 sobe, < 0 desce.
static func single(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState, ship: Ship,
		target: int, good: StringName, tons: float) -> float:
	var stop := TradeRoute.Stop.new(target)
	stop.orders.append(TradeRoute.Order.new(good, tons > 0.0, ceili(absf(tons))))
	var unused: Dictionary[StringName, float] = {}
	return _apply(world, data, config, derived, ship, stop, unused, world.money, true, absf(tons))


## real = false trabalha numa cópia do navio e num estoque e num caixa de faz de conta.
static func _apply(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState, ship: Ship,
		stop: TradeRoute.Stop, shadow_stock: Dictionary[StringName, float], money: float, real: bool,
		exact_tons: float = -1.0) -> float:
	var def := data.ship(ship.def_id)
	var capacity := float(def.slot_capacity_t)
	var trader := data.trader()
	var at_trader := stop.target == Ship.TRADER_POST
	var economy := world.economy(stop.target) if not at_trader else null
	var storage: float = derived.capacity.get(stop.target, float(config.island_storage_capacity_t)) if not at_trader else 0.0
	var moved := 0.0
	var cash := money
	## encomendas: o que ainda cabe nelas por bem (de faz de conta no plano)
	var mission_room: Dictionary[StringName, float] = {}
	var delivered := false
	for pass_index: int in 2:
		var loading := pass_index == 1
		for order: TradeRoute.Order in stop.orders:
			if order.is_load != loading:
				continue
			var wanted := exact_tons if exact_tons >= 0.0 else float(order.tons)
			var tons := 0.0
			if at_trader:
				if trader == null:
					continue
				var unit := world.trader_price(data, config, order.good)
				if loading:
					if not trader.sells.has(order.good) or unit <= 0.0:
						continue
					tons = minf(minf(wanted, ship.room_for(order.good, capacity)), maxf(cash, 0.0) / unit)
					cash -= tons * unit
				else:
					if not trader.buys.has(order.good):
						continue
					tons = minf(wanted, ship.tons_of(order.good))
					cash += tons * unit
					var room: float = mission_room.get(order.good, MissionSystem.room_for(world, order.good))
					var for_missions := minf(tons, room)
					mission_room[order.good] = room - for_missions
					if real and for_missions > 0.000001:
						MissionSystem.deliver(world, order.good, for_missions)
						delivered = true
			else:
				var held: float = shadow_stock.get(order.good, economy.amount(order.good))
				if loading:
					tons = minf(minf(wanted, held), ship.room_for(order.good, capacity))
					shadow_stock[order.good] = held - tons
				else:
					tons = minf(minf(wanted, ship.tons_of(order.good)), maxf(storage - held, 0.0))
					shadow_stock[order.good] = held + tons
			if tons <= 0.000001:
				continue
			if loading:
				ship.load_good(order.good, tons, capacity)
				if real and not at_trader:
					economy.take(order.good, tons)
			else:
				ship.unload_good(order.good, tons)
				if real and not at_trader:
					economy.add(order.good, tons, storage)
			moved += tons
	if real:
		world.money = cash
		if delivered:
			MissionSystem.settle(world, data)
			EventBus.missions_changed.emit()
	return moved


static func _shadow(ship: Ship) -> Ship:
	var copy := Ship.new(ship.id, null, ship.owner)
	copy.def_id = ship.def_id
	copy.slot_goods = ship.slot_goods.duplicate()
	copy.slot_tons = ship.slot_tons.duplicate()
	return copy
