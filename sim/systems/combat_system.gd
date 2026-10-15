class_name CombatSystem
extends RefCounted
## Combate naval (Fase 11), depois dos navios. Só entre o jogador e uma rival em guerra com ele: o
## comerciante é neutro e rivais não brigam entre si. Todo navio armado (ShipDef.cannons) recarrega e,
## pronto, atira no inimigo mais perto ao alcance (cannon_range_m), tirando salvo_damage do casco. Casco
## a zero afunda o navio com a carga. Parado num porto próprio, o casco se repara (ship_repair_per_s).
## Cada fragata que a rival perde a deixa mais perto da paz (rival_loss_relation).


static func run(world: WorldState, data: GameData, config: GameConfig, dt: float) -> void:
	var ids := world.ship_ids()
	for ship_id: int in ids:
		var ship := world.ships[ship_id]
		var def := data.ship(ship.def_id)
		if ship.hp < def.hull_points and in_home_port(world, data, ship):
			ship.hp = minf(ship.hp + config.ship_repair_per_s * dt, def.hull_points)
	if not world.rivals_state.at_war():
		return
	for ship_id: int in ids:
		var ship: Ship = world.ships.get(ship_id)
		if ship == null or ship.hp <= 0.0:
			continue
		var def := data.ship(ship.def_id)
		if def.cannons <= 0:
			continue
		ship.reload_left = maxf(ship.reload_left - dt, 0.0)
		if ship.reload_left > 0.0:
			continue
		var target := nearest_enemy(world, data, ship, def.cannon_range_m)
		if target == null:
			continue
		target.hp -= def.salvo_damage
		ship.reload_left = def.reload_s
		EventBus.ship_fired.emit(ship.id, target.id)
	for ship_id: int in ids:
		var ship: Ship = world.ships.get(ship_id)
		if ship != null and ship.hp <= 0.0:
			sink(world, config, ship)


## Os dois navios estão em lados opostos de uma guerra?
static func hostile(world: WorldState, a: Ship, b: Ship) -> bool:
	if a.owner == Ship.Owner.TRADER or b.owner == Ship.Owner.TRADER or a.owner == b.owner:
		return false
	var rival_ship := a if a.owner == Ship.Owner.RIVAL else b
	var rival := world.rivals_state.by_ship(rival_ship.id)
	return rival != null and rival.stance == RivalState.Stance.WAR


## O inimigo mais perto ao alcance (desempate pelo id), ou null.
static func nearest_enemy(world: WorldState, data: GameData, ship: Ship, range_m: float) -> Ship:
	var best: Ship = null
	var best_distance := range_m * range_m
	for other_id: int in world.ship_ids():
		var other := world.ships[other_id]
		if other == ship or other.hp <= 0.0 or not other.is_placed() or not hostile(world, ship, other):
			continue
		var distance := ship.position.distance_squared_to(other.position)
		if distance <= best_distance:
			best = other
			best_distance = distance
	return best


## Navio parado num porto do dono: o jogador numa ilha com entreposto; a rival numa ilha dela.
static func in_home_port(world: WorldState, data: GameData, ship: Ship) -> bool:
	if ship.state == Ship.State.SAILING or ship.at < 0:
		return false
	match ship.owner:
		Ship.Owner.PLAYER:
			return world.has_trading_post(ship.at, data)
		Ship.Owner.RIVAL:
			var rival := world.rivals_state.by_ship(ship.id)
			return rival != null and rival.islands.has(ship.at)
	return true


## Afunda: some do mundo com a carga. A rival perde o navio (e esfria a guerra se era fragata).
static func sink(world: WorldState, config: GameConfig, ship: Ship) -> void:
	var rival := world.rivals_state.by_ship(ship.id)
	if rival != null:
		if rival.ship_id == ship.id:
			rival.ship_id = 0
		if rival.warships.has(ship.id):
			rival.warships.erase(ship.id)
			rival.relation = minf(rival.relation + config.rival_loss_relation, 100.0)
	world.ships.erase(ship.id)
	EventBus.ship_sunk.emit(ship.id, ship.owner, ship.position)
	EventBus.ships_changed.emit()
