class_name Simulation
extends RefCounted
## Dona do estado do mundo. Executa os comandos e anuncia o que mudou pelo EventBus.
## Roda em ticks do GameClock; na Fase 1 ainda não há sistemas por tick.

const MAIN_ISLAND := 0

var world: WorldState
var catalog: BuildingCatalog
var config: GameConfig


func _init(game_config: GameConfig, building_catalog: BuildingCatalog, state: WorldState = null) -> void:
	config = game_config
	catalog = building_catalog
	world = state if state != null else _new_world()


func _new_world() -> WorldState:
	var fresh := WorldState.new()
	fresh.islands.append(IslandGrid.new(config.main_island_size_cells))
	return fresh


func execute(command: Command) -> CommandResult:
	var result := command.execute(world, catalog)
	if not result.ok():
		return result
	for building_id: int in result.removed:
		EventBus.building_removed.emit(building_id)
	for building_id: int in result.placed:
		EventBus.building_placed.emit(building_id)
	if result.roads_changed:
		EventBus.roads_changed.emit(result.island_id)
	return result


func tick(_tick_index: int) -> void:
	pass


func def_of(record: BuildingRecord) -> BuildingDef:
	return catalog.find(record.def_id)


func has_road_access(building_id: int) -> bool:
	var record := world.building(building_id)
	if record == null:
		return false
	return RoadNetwork.has_access(world.island(record.island_id), record, def_of(record))
