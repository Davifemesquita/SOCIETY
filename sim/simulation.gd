class_name Simulation
extends RefCounted
## Dona do estado do mundo. Executa os comandos, roda os sistemas em ordem fixa a cada tick
## (seção 12) e anuncia o que mudou pelo EventBus.

const MAIN_ISLAND := 0

var world: WorldState:
	set(value):
		world = value
		_dirty = true
var data: GameData
var config: GameConfig
## Trapaça de desenvolvimento: construir sem custo e sem desbloqueio (testes, benchmark).
var free_build: bool = false

var _derived := DerivedState.new()
var _dirty: bool = true


func _init(game_config: GameConfig, game_data: GameData, state: WorldState = null) -> void:
	config = game_config
	data = game_data
	world = state if state != null else new_world()


## Mundo novo: a ilha principal com o dinheiro e os materiais iniciais.
func new_world() -> WorldState:
	var fresh := WorldState.new()
	fresh.money = config.starting_money
	fresh.islands.append(IslandGrid.new(config.main_island_size_cells))
	var economy := IslandEconomy.new()
	economy.profile_id = data.island_profiles[0].id
	for material: StringName in config.starting_materials:
		economy.stock[material] = float(config.starting_materials[material])
	fresh.economies.append(economy)
	return fresh


func execute(command: Command) -> CommandResult:
	var result := command.execute(CommandContext.new(world, data, config, free_build))
	if not result.ok():
		return result
	if not (result.removed.is_empty() and result.placed.is_empty() and result.changed.is_empty() and not result.roads_changed):
		_dirty = true
	for building_id: int in result.removed:
		EventBus.building_removed.emit(building_id)
	for building_id: int in result.placed:
		EventBus.building_placed.emit(building_id)
	for building_id: int in result.changed:
		EventBus.building_state_changed.emit(building_id)
	if result.roads_changed:
		EventBus.roads_changed.emit(result.island_id)
	return result


## Um tick de simulação: força de trabalho → produção → logística → necessidades →
## população e upgrades → economia. As estatísticas são calculadas sob pedido.
func tick(_tick_index: int) -> void:
	var dt := config.tick_interval()
	var derived := derived_state()
	WorkforceSystem.run(world, derived)
	ProductionSystem.run(config, derived, dt)
	DirectTransferSystem.run(world, config, derived)
	NeedsSystem.run(world, data, config, derived, dt)
	PopulationSystem.run(world, data, config, derived, dt)
	EconomySystem.run(world, derived, dt)
	world.tick += 1


## Roda n ticks de uma vez (testes e simulação sem tela).
func run_ticks(count: int) -> void:
	for i: int in count:
		tick(i)


func derived_state() -> DerivedState:
	if _dirty:
		_derived.rebuild(world, data, config)
		_dirty = false
	return _derived


func statistics(island_id: int = MAIN_ISLAND) -> Statistics:
	return Statistics.compute(world, data, derived_state(), island_id)


func def_of(record: BuildingRecord) -> BuildingDef:
	return data.building(record.def_id)


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
		reason = PlacementRules.check_terrain(grid, data.profile(world.economy(island_id).profile_id), def, origin, rotation)
	if reason == PlacementRules.OK:
		reason = affordability(def, island_id)
	return reason
