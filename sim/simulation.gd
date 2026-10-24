class_name Simulation
extends RefCounted
## Dona do estado do mundo. Executa os comandos, roda os sistemas em ordem fixa a cada tick
## (seção 12) e anuncia o que mudou pelo EventBus.

const MAIN_ISLAND := 0

var world: WorldState:
	set(value):
		world = value
		_dirty = true
		if _harbors != null:
			_harbors.chart.finish()
		_harbors = null
var data: GameData
var config: GameConfig
## Trapaça de desenvolvimento: construir sem custo e sem desbloqueio (testes, benchmark).
var free_build: bool = false
## Só para o benchmark: construir sem olhar o terreno.
var ignore_terrain: bool = false

var _derived := DerivedState.new()
var _dirty: bool = true
## Carta náutica e portos do mundo atual (refeitos quando o mundo é trocado).
var _harbors: Harbors


func _init(game_config: GameConfig, game_data: GameData, state: WorldState = null) -> void:
	config = game_config
	data = game_data
	world = state if state != null else new_world()
	place_new_ships()


## Mundo novo: a ilha plana com o dinheiro e o navio inicial (com os materiais).
func new_world() -> WorldState:
	var fresh := WorldState.new()
	fresh.difficulty = config.default_difficulty
	fresh.money = config.starting_money_for(fresh.difficulty)
	fresh.islands.append(IslandGrid.new(config.main_island_size_cells))
	var economy := IslandEconomy.new()
	economy.profile_id = data.island_profiles[0].id
	fresh.economies.append(economy)
	fresh.add_starting_fleet(config, data)
	return fresh


func execute(command: Command) -> CommandResult:
	var context := CommandContext.new(world, data, config, free_build)
	context.ignore_terrain = ignore_terrain
	var result := command.execute(context)
	if not result.ok():
		return result
	# tudo o que mudou marca a simulação antes de avisar as vistas: elas consultam o estado
	# derivado, e marcar depois forçaria um segundo recálculo inteiro
	if not (result.removed.is_empty() and result.placed.is_empty() and result.changed.is_empty() and not result.roads_changed) \
			or result.trees_cleared.has_area():
		_dirty = true
	for building_id: int in result.removed:
		EventBus.building_removed.emit(building_id)
	for building_id: int in result.placed:
		EventBus.building_placed.emit(building_id)
	for building_id: int in result.changed:
		EventBus.building_state_changed.emit(building_id)
	if result.roads_changed:
		EventBus.roads_changed.emit(result.island_id)
	if result.trees_cleared.has_area():
		EventBus.trees_changed.emit(result.island_id, result.trees_cleared)
	if result.ships_changed:
		_dirty = true
		place_new_ships()
		EventBus.ships_changed.emit()
	if result.routes_changed:
		EventBus.routes_changed.emit()
	if result.colonized:
		RivalSystem.on_player_colony(world, config)
		EventBus.island_colonized.emit(result.island_id)
	if result.rivals_changed:
		EventBus.rivals_changed.emit()
	if result.missions_changed:
		EventBus.missions_changed.emit()
	if result.specialists_changed:
		_dirty = true
		EventBus.specialists_changed.emit()
	return result


## Um tick de simulação: força de trabalho → produção (e estaleiros) → logística (carroças) → necessidades →
## população e upgrades (e marcos, metas e objetivo) → economia → comércio, navios e combate → eventos e encomendas → oferta de especialistas → riscos → rivais →
## estatísticas (a amostra do histórico; o retrato atual é calculado sob pedido).
func tick(_tick_index: int) -> void:
	var dt := config.tick_interval()
	var derived := derived_state()
	WorkforceSystem.run(world, derived)
	ProductionSystem.run(config, derived, dt, world.events_state, world.risks_state)
	var built := ShipyardSystem.run(world, data, config, derived, dt)
	if not built.is_empty():
		_dirty = true
		place_new_ships()
		EventBus.ships_changed.emit()
		for ship_id: int in built:
			EventBus.ship_built.emit(ship_id)
	if config.instant_logistics:
		DirectTransferSystem.run(world, config, derived)
	else:
		LogisticsSystem.run(world, config, derived, dt)
	NeedsSystem.run(world, data, config, derived, dt)
	PopulationSystem.run(world, data, config, derived, dt)
	MilestoneSystem.run(world, config, derived)
	GoalSystem.run(world, data, config, derived)
	VictorySystem.run(world, data, config, derived)
	EconomySystem.run(world, derived, dt)
	if not world.ships.is_empty() or world.any_trading_post(data):
		ShipSystem.run(world, data, config, derived, harbors(), dt)
		CombatSystem.run(world, data, config, dt)
	EventSystem.run(world, data, config)
	MissionSystem.run(world, data, config)
	SpecialistSystem.run(world, data, config)
	if world.risks_state.enabled:
		_remove_lost(RiskSystem.run(world, data, config, derived))
	if world.rivals_state.enabled:
		RivalSystem.run(world, data, config, harbors(), dt)
	else:
		world.treaty_income_per_min = 0.0
	world.tick += 1
	StatisticsSystem.run(world, data, config, derived)


## Prédios perdidos no fogo saem do mundo como na demolição, sem devolver material.
func _remove_lost(lost: Array[int]) -> void:
	for building_id: int in lost:
		var record := world.building(building_id)
		var def := data.building(record.def_id)
		world.island(record.island_id).fill_building(Footprint.rect(record.origin, def.size, record.rotation), 0)
		world.buildings.erase(building_id)
		world.carts.erase(building_id)
		world.risks_state.forget(building_id)
		world.shipyard_state.forget(building_id)
		if world.specialists_state.release(building_id):
			EventBus.specialists_changed.emit()
		_dirty = true
		EventBus.building_removed.emit(building_id)
		EventBus.fire_ended.emit(building_id, true)
		EventBus.building_lost.emit(building_id, record.def_id, record.island_id)


## Roda n ticks de uma vez (testes e simulação sem tela).
func run_ticks(count: int) -> void:
	for i: int in count:
		tick(i)


func derived_state() -> DerivedState:
	if _dirty:
		_derived.rebuild(world, data, config)
		_dirty = false
	return _derived


## Carta náutica e portos (feitos na primeira vez que um navio precisa deles).
func harbors() -> Harbors:
	if _harbors == null:
		_harbors = Harbors.new(world, config)
	_harbors.refresh(world, data, derived_state())
	return _harbors


## Põe no mar os navios que ainda não têm lugar (o inicial e os recém-comprados).
func place_new_ships() -> void:
	for ship: Ship in world.ships.values():
		if not ship.is_placed():
			ShipSystem.place(ship, harbors())


func statistics(island_id: int = MAIN_ISLAND) -> Statistics:
	return Statistics.compute(world, data, derived_state(), island_id)


func def_of(record: BuildingRecord) -> BuildingDef:
	return data.building(record.def_id)


## Fábrica ociosa (Fase 28): produção que não está pausada, com a produtividade média abaixo de
## config.idle_productivity. Paga a manutenção inteira por pouco; pausada pagaria a fração de pausa.
func is_idle(record: BuildingRecord) -> bool:
	return def_of(record).is_production() and not record.paused and record.productivity < config.idle_productivity


## Quantas fábricas estão ociosas (x) e quanto custam de manutenção por minuto (y), no mundo todo.
func idle_upkeep() -> Vector2:
	var total := Vector2.ZERO
	for record: BuildingRecord in world.buildings.values():
		if is_idle(record):
			total += Vector2(1.0, def_of(record).upkeep_per_min
					* DerivedState.upkeep_factor(world.specialists_state.at(record.id)))
	return total


func has_road_access(building_id: int) -> bool:
	return derived_state().has_road(building_id)


## Motivo pelo qual o prédio não pode ser construído agora (desbloqueio e custo), ou &"".
func affordability(def: BuildingDef, island_id: int = MAIN_ISLAND) -> StringName:
	if free_build:
		return PlacementRules.OK
	var reason := PlacementRules.check_unlock(world, def)
	if reason == PlacementRules.OK:
		reason = PlacementRules.check_cost(world, world.economy(island_id), config, def.cost_money, def.cost_materials)
	return reason


## Toda a validação de um prédio num lugar, sem construir (prévia da ferramenta).
func placement_reason(def: BuildingDef, origin: Vector2i, rotation: int, island_id: int = MAIN_ISLAND) -> StringName:
	var grid := world.island(island_id)
	var reason := PlacementRules.check_building(grid, def, origin, rotation)
	if reason == PlacementRules.OK:
		reason = PlacementRules.check_terrain(grid, data.profile(world.economy(island_id).profile_id), def, origin, rotation, config)
	if reason == PlacementRules.OK and not free_build and not config.instant_logistics:
		reason = PlacementRules.check_trading_post(world, data, island_id, def)
	if reason == PlacementRules.OK and not free_build and PlacementRules.founds_colony(world, data, island_id, def):
		reason = PlacementRules.check_colony(world, data, config, island_id, def)
	elif reason == PlacementRules.OK and not (def.is_trading_post and not world.any_trading_post(data)):
		reason = affordability(def, island_id)
	return reason


## Motivo pelo qual o prédio não pode ir para o lugar dado (prévia de mover), ou &"".
func move_reason(building_id: int, origin: Vector2i, rotation: int) -> StringName:
	return MoveBuildingCommand.check(world, data, config, building_id, origin, rotation, ignore_terrain)


## Estoque por bem da ilha agora (o maior nível de entreposto dela).
func storage_capacity(island_id: int = MAIN_ISLAND) -> float:
	return derived_state().capacity.get(island_id, float(config.island_storage_capacity_t))
