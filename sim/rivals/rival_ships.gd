class_name RivalShips
extends RefCounted
## O navio mercante de cada rival (Fase 11): vai e volta entre as ilhas dela e o posto do
## comerciante, parando rival_ship_dwell_s em cada ponta. Não ocupa vaga de porto (ancora no
## ancoradouro da ilha, como quem coloniza) e não mexe na economia do jogador.


static func idle(world: WorldState, config: GameConfig, harbors: Harbors, ship: Ship, dt: float) -> void:
	var rival := world.rivals_state.by_ship(ship.id)
	if rival == null or rival.islands.is_empty():
		return
	ship.timer -= dt
	if ship.timer > ShipSystem.TIMER_EPSILON:
		return
	var target := Ship.TRADER_POST
	if ship.at == Ship.TRADER_POST or ship.at == Ship.NOWHERE:
		var ids := rival.island_ids()
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([world.seed, &"rival_ship", ship.id, world.tick])
		target = ids[rng.randi_range(0, ids.size() - 1)]
	ShipSystem.depart(harbors, ship, target)
	if ship.state == Ship.State.IDLE:
		ship.timer = config.rival_ship_dwell_s


static func arrived(config: GameConfig, ship: Ship) -> void:
	ship.stop()
	ship.timer = config.rival_ship_dwell_s
