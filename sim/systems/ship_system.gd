class_name ShipSystem
extends RefCounted
## Navios (seção 6), o último sistema do tick antes das estatísticas. Navio com rota sai para a
## próxima parada válida (ilha com entreposto, ou o posto do comerciante) pela carta náutica; na
## ilha espera no ancoradouro uma vaga livre (entreposto ou píer, um navio por vaga, fila por ordem
## de chegada), encosta no cais, fica lá o tempo das toneladas movidas e só então a carga passa de
## um lado para o outro. Depois segue para a parada seguinte e repete o ciclo. Navio sem rota fica
## ancorado onde chegou. O navio do comerciante faz a volta dele pelos entrepostos (TraderVisits).
## Ao zarpar, o navio iça velas por ship_cast_off_seconds enquanto o caminho no mar é calculado em
## outra thread (SeaChart.request); ao fim dele recolhe o caminho e sai. Os navios das rivais (Fase 11)
## vão e voltam entre as ilhas delas e o comerciante (RivalShips).

## Folga dos cronômetros (cais, içar velas) contra o erro de somar 0,2 s em ponto flutuante.
const TIMER_EPSILON := 0.000001


static func run(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState, harbors: Harbors, dt: float) -> void:
	harbors.refresh(world, data, derived)
	TraderVisits.ensure_ship(world, data, harbors)
	var waiting: Array[Ship] = []
	for ship_id: int in world.ship_ids():
		var ship := world.ships[ship_id]
		if not ship.is_placed():
			place(ship, harbors)
		ship.previous_position = ship.position
		ship.previous_heading = ship.heading
		match ship.state:
			Ship.State.IDLE:
				if ship.owner == Ship.Owner.TRADER:
					TraderVisits.idle(world, data, harbors, ship, dt)
				elif ship.owner == Ship.Owner.RIVAL:
					RivalShips.idle(world, config, harbors, ship, dt)
				elif ship.route_id != 0:
					next_leg(world, harbors, ship)
			Ship.State.SAILING:
				if ship.waypoints.is_empty():
					_cast_off(world, harbors, ship, dt)
				else:
					_sail(world, data, config, derived, harbors, ship, dt)
			Ship.State.DOCKED:
				_docked(world, data, config, derived, harbors, ship, dt)
		if ship.state == Ship.State.WAITING:
			waiting.append(ship)
	_serve_queue(world, data, config, derived, harbors, waiting)


## Navio ainda fora do mar (o inicial, o recém-comprado): no ancoradouro da ilha dele.
static func place(ship: Ship, harbors: Harbors) -> void:
	ship.position = harbors.target_point(ship.at, ship.owner) if ship.at != Ship.NOWHERE else harbors.trader_post
	ship.previous_position = ship.position


## Sai para a próxima parada válida da rota (a partir da da vez). Sem nenhuma, fica parado.
static func next_leg(world: WorldState, harbors: Harbors, ship: Ship) -> void:
	var route: TradeRoute = world.routes.get(ship.route_id)
	if route == null:
		ship.route_id = 0
		ship.stop()
		return
	for attempt: int in route.stops.size():
		var index := (ship.stop_index + attempt) % route.stops.size()
		var target := route.stops[index].target
		if target == Ship.TRADER_POST or not harbors.berths(target).is_empty():
			ship.stop_index = index
			depart(harbors, ship, target)
			return


## Põe o navio a içar velas para o destino; o caminho começa a ser calculado em outra thread.
static func depart(harbors: Harbors, ship: Ship, target: int) -> void:
	ship.waypoints = PackedVector2Array()
	ship.waypoint = 0
	ship.destination = target
	ship.at = Ship.NOWHERE
	ship.berth_id = 0
	ship.timer = harbors.cast_off_seconds()
	ship.state = Ship.State.SAILING
	harbors.chart.request(ship.position, harbors.target_point(target, ship.owner))


## Içando velas: ao fim do tempo, recolhe o caminho (pronto ou esperando a thread) e sai. Sem
## caminho por mar fica parado onde está; na rota, a próxima tentativa já vai para a parada
## seguinte.
static func _cast_off(world: WorldState, harbors: Harbors, ship: Ship, dt: float) -> void:
	var goal := harbors.target_point(ship.destination, ship.owner)
	# depois de carregar um save o pedido se perdeu com a carta antiga: pede de novo (não repete)
	harbors.chart.request(ship.position, goal)
	ship.timer -= dt
	# folga do ponto flutuante: 1 s em passos de 0,2 sobra 5e-17 e atrasaria um tick
	if ship.timer > TIMER_EPSILON:
		return
	var path := harbors.chart.route(ship.position, goal)
	if not path.is_empty():
		ship.waypoints = path
		ship.waypoint = 0
		ship.timer = 0.0
		return
	ship.stop()
	var route: TradeRoute = world.routes.get(ship.route_id)
	if ship.owner == Ship.Owner.PLAYER and route != null and not route.stops.is_empty():
		ship.stop_index = (ship.stop_index + 1) % route.stops.size()


## Anda até speed × dt pelo caminho; chega quando passa do último ponto.
static func _sail(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState, harbors: Harbors, ship: Ship, dt: float) -> void:
	if _advance(ship, ship.waypoints, data.ship(ship.def_id).speed_m_s * EventEffects.ship_speed(world.events_state) * dt):
		_arrive(world, data, config, derived, ship)


## Move o navio pelos pontos a partir de ship.waypoint. true quando chegou ao último.
static func _advance(ship: Ship, points: PackedVector2Array, step: float) -> bool:
	var left := step
	while ship.waypoint < points.size():
		var offset := points[ship.waypoint] - ship.position
		var distance := offset.length()
		if distance > 0.0001:
			ship.heading = atan2(offset.y, offset.x)
		if distance > left:
			ship.position += offset / distance * left
			return false
		ship.position = points[ship.waypoint]
		left -= distance
		ship.waypoint += 1
	return true


static func _arrive(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState, ship: Ship) -> void:
	ship.at = ship.destination
	ship.waypoints = PackedVector2Array()
	ship.waypoint = 0
	if ship.owner == Ship.Owner.TRADER:
		TraderVisits.arrived(world, data, ship)
		return
	if ship.owner == Ship.Owner.RIVAL:
		RivalShips.arrived(config, ship)
		return
	var route: TradeRoute = world.routes.get(ship.route_id)
	if route == null or route.stop(ship.stop_index) == null:
		ship.stop()
		return
	if ship.at == Ship.TRADER_POST:
		# o posto do comerciante não tem fila: negocia direto
		ship.state = Ship.State.DOCKED
		ship.timer = CargoTransfer.plan(world, data, config, derived, ship, route.stop(ship.stop_index)) * config.ship_seconds_per_ton
		return
	ship.state = Ship.State.WAITING
	ship.queued_at = world.tick


## No cais: encosta (se ainda não encostou), conta o tempo e faz a parada; depois segue viagem.
static func _docked(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState, harbors: Harbors, ship: Ship, dt: float) -> void:
	if ship.berth_id != 0:
		if not harbors.berths(ship.at).has(ship.berth_id):
			# o cais foi demolido ou perdeu a estrada: volta para a fila
			ship.berth_id = 0
			ship.state = Ship.State.WAITING
			ship.queued_at = world.tick
			return
		var berth := PackedVector2Array([harbors.berth_point(ship.berth_id)])
		if not ship.position.is_equal_approx(berth[0]):
			ship.waypoint = 0
			_advance(ship, berth, data.ship(ship.def_id).speed_m_s * EventEffects.ship_speed(world.events_state) * dt)
			return
	if ship.owner == Ship.Owner.TRADER:
		ship.timer -= dt
		if ship.timer <= TIMER_EPSILON:
			TraderVisits.leave(world, data, config, derived, harbors, ship)
		return
	ship.timer -= dt
	if ship.timer > TIMER_EPSILON:
		return
	var route: TradeRoute = world.routes.get(ship.route_id)
	if route != null and route.stop(ship.stop_index) != null:
		CargoTransfer.execute(world, data, config, derived, ship, route.stop(ship.stop_index))
		ship.stop_index = (ship.stop_index + 1) % route.stops.size()
	ship.stop()
	if route != null:
		next_leg(world, harbors, ship)


## Fila do porto: quem chegou antes (e, no empate, o navio de menor id) pega a primeira vaga livre.
## Ilha que perdeu o entreposto é pulada.
static func _serve_queue(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState, harbors: Harbors, waiting: Array[Ship]) -> void:
	if waiting.is_empty():
		return
	waiting.sort_custom(func(a: Ship, b: Ship) -> bool:
		return a.queued_at < b.queued_at or (a.queued_at == b.queued_at and a.id < b.id))
	var taken: Dictionary[int, bool] = {}
	for ship: Ship in world.ships.values():
		if ship.state == Ship.State.DOCKED and ship.berth_id != 0:
			taken[ship.berth_id] = true
	for ship: Ship in waiting:
		var berths := harbors.berths(ship.at)
		var route: TradeRoute = world.routes.get(ship.route_id)
		if berths.is_empty() or route == null or route.stop(ship.stop_index) == null:
			if route != null and not route.stops.is_empty():
				ship.stop_index = (ship.stop_index + 1) % route.stops.size()
			ship.stop()
			continue
		for berth_id: int in berths:
			if taken.has(berth_id):
				continue
			taken[berth_id] = true
			ship.berth_id = berth_id
			ship.state = Ship.State.DOCKED
			ship.timer = CargoTransfer.plan(world, data, config, derived, ship, route.stop(ship.stop_index)) * config.ship_seconds_per_ton
			break
