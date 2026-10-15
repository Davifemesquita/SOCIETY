class_name RivalSystem
extends RefCounted
## Companhias rivais (Fase 11). A cada events_check_ticks: cada rival funda a colônia da vez numa
## ilha livre (sem entreposto do jogador, sem dono; tropical só depois de rival_tropical_after_s),
## respeitando o teto dela e o teto de todas juntas; as vilas crescem até o teto da ilha; a relação
## volta aos poucos para a da personalidade; e a IA decide a postura (a agressiva declara guerra com
## a relação baixa, a não agressiva faz as pazes quando a relação melhora, o acordo cai com a relação
## negativa). Todo tick: a renda do acordo comercial entra no caixa. Os sorteios saem da semente.


static func run(world: WorldState, data: GameData, config: GameConfig, harbors: Harbors, dt: float) -> void:
	var state := world.rivals_state
	world.treaty_income_per_min = 0.0
	if not state.enabled:
		return
	for rival: RivalState in state.rivals:
		if rival.stance == RivalState.Stance.TRADE:
			world.treaty_income_per_min += rival.population() * config.rival_trade_income_per_resident
	world.money += world.treaty_income_per_min * dt / 60.0
	world.income_per_min += world.treaty_income_per_min
	if world.tick % config.events_check_ticks != 0:
		return
	var step_min := dt * config.events_check_ticks / 60.0
	for rival: RivalState in state.rivals:
		_grow(world, config, rival, step_min)
		_colonize(world, data, config, rival)
		_ensure_ship(world, data, harbors, rival)
		_drift(config, rival, step_min)
		_decide(world, config, rival)


static func _grow(world: WorldState, config: GameConfig, rival: RivalState, step_min: float) -> void:
	for island_id: int in rival.island_ids():
		var grid := world.island(island_id)
		var cap := float(grid.size.x * grid.size.y) * config.rival_residents_per_cell
		var count := rival.islands[island_id]
		rival.islands[island_id] = minf(count + rival.def.growth_per_min * maxf(1.0 - count / cap, 0.0) * step_min, cap)


static func _colonize(world: WorldState, data: GameData, config: GameConfig, rival: RivalState) -> void:
	if rival.next_colony_tick == 0:
		rival.next_colony_tick = world.tick + config.ticks_of(rival.def.first_colony_s)
		return
	if world.tick < rival.next_colony_tick or rival.islands.size() >= rival.def.max_islands:
		return
	rival.next_colony_tick = world.tick + config.ticks_of(rival.def.colony_interval_s)
	if world.rivals_state.claimed_count() >= island_cap(world, config):
		return
	var free := free_islands(world, data, config)
	if free.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.seed, &"rival", rival.def_id, rival.islands.size()])
	var island_id := free[rng.randi_range(0, free.size() - 1)]
	rival.islands[island_id] = config.rival_founding_population
	EventBus.rival_colonized.emit(rival.def_id, island_id)


## Teto de ilhas de todas as rivais juntas: uma fração das ilhas além da principal.
static func island_cap(world: WorldState, config: GameConfig) -> int:
	return floori((world.islands.size() - 1) * config.rival_island_share)


## Ilhas que uma rival pode tomar agora, em ordem de índice.
static func free_islands(world: WorldState, data: GameData, config: GameConfig) -> Array[int]:
	var list: Array[int] = []
	var tropical_ok := world.tick >= config.ticks_of(config.rival_tropical_after_s)
	for island_id: int in range(1, world.islands.size()):
		if world.has_trading_post(island_id, data) or world.rivals_state.owner_of(island_id) != null:
			continue
		if world.is_tropical(island_id, data) and not tropical_ok:
			continue
		list.append(island_id)
	return list


static func _ensure_ship(world: WorldState, data: GameData, harbors: Harbors, rival: RivalState) -> void:
	if rival.ship_id != 0 or rival.islands.is_empty():
		return
	var ship := Ship.new(world.next_ship_id, data.ship(rival.def.ship), Ship.Owner.RIVAL)
	world.next_ship_id += 1
	ship.at = rival.island_ids()[0]
	ship.position = harbors.target_point(ship.at, Ship.Owner.RIVAL)
	ship.previous_position = ship.position
	world.ships[ship.id] = ship
	rival.ship_id = ship.id
	EventBus.ships_changed.emit()


static func _drift(config: GameConfig, rival: RivalState, step_min: float) -> void:
	var target := rival.def.base_relation(config)
	if rival.stance == RivalState.Stance.TRADE:
		target = maxf(target, config.rival_trade_relation)
	rival.relation = move_toward(rival.relation, target, config.rival_relation_drift_per_min * step_min)


static func _decide(world: WorldState, config: GameConfig, rival: RivalState) -> void:
	if world.tick - rival.stance_tick < config.ticks_of(config.rival_stance_cooldown_s):
		return
	match rival.stance:
		RivalState.Stance.TRADE:
			if rival.relation < 0.0:
				set_stance(world, rival, RivalState.Stance.NEUTRAL)
		RivalState.Stance.NEUTRAL:
			if rival.def.personality == RivalDef.Personality.AGGRESSIVE and rival.relation <= config.rival_war_relation:
				set_stance(world, rival, RivalState.Stance.WAR)
		RivalState.Stance.WAR:
			if rival.def.personality != RivalDef.Personality.AGGRESSIVE and rival.relation >= config.rival_auto_peace_relation:
				set_stance(world, rival, RivalState.Stance.NEUTRAL)


static func set_stance(world: WorldState, rival: RivalState, stance: RivalState.Stance) -> void:
	if rival.stance == stance:
		return
	rival.stance = stance
	rival.stance_tick = world.tick
	EventBus.rival_stance_changed.emit(rival.def_id, stance)


## O jogador fundou uma colônia: as rivais que não gostam de vê-lo crescer ficam mais frias.
static func on_player_colony(world: WorldState, config: GameConfig) -> void:
	for rival: RivalState in world.rivals_state.rivals:
		if rival.def.personality != RivalDef.Personality.PEACEFUL:
			rival.relation = clampf(rival.relation - config.rival_colony_penalty, -100.0, 100.0)
