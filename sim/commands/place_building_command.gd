class_name PlaceBuildingCommand
extends Command
## Constrói um prédio. Estrada na entrada não é exigida: sem ela o prédio fica com alerta.

var island_id: int
var def_id: StringName
var origin: Vector2i
var rotation: int


func _init(island: int, def: StringName, at: Vector2i, rot: int) -> void:
	island_id = island
	def_id = def
	origin = at
	rotation = rot


func execute(world: WorldState, catalog: BuildingCatalog) -> CommandResult:
	var grid := world.island(island_id)
	if grid == null:
		return CommandResult.refused(PlacementRules.OUT_OF_ISLAND)
	var def := catalog.find(def_id)
	var reason := PlacementRules.check_building(grid, def, origin, rotation)
	if reason != PlacementRules.OK:
		return CommandResult.refused(reason)
	var record := BuildingRecord.new(world.next_building_id, def_id, island_id, origin, rotation)
	world.next_building_id += 1
	world.buildings[record.id] = record
	grid.fill_building(Footprint.rect(origin, def.size, rotation), record.id)
	var result := CommandResult.new()
	result.island_id = island_id
	result.placed.append(record.id)
	return result
