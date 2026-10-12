class_name DemolishCommand
extends Command
## Demole todo prédio que encosta na área e toda estrada dentro dela.
## A devolução de materiais (50%) entra com a economia, na Fase 2.

var island_id: int
var area: Rect2i


func _init(island: int, region: Rect2i) -> void:
	island_id = island
	area = region


func execute(world: WorldState, catalog: BuildingCatalog) -> CommandResult:
	var grid := world.island(island_id)
	if grid == null:
		return CommandResult.refused(PlacementRules.OUT_OF_ISLAND)
	var clipped := area.intersection(Rect2i(Vector2i.ZERO, grid.size))
	var result := CommandResult.new()
	result.island_id = island_id
	for y: int in range(clipped.position.y, clipped.end.y):
		for x: int in range(clipped.position.x, clipped.end.x):
			var cell := Vector2i(x, y)
			var building_id := grid.building_at(cell)
			if building_id != 0 and not result.removed.has(building_id):
				result.removed.append(building_id)
			if grid.has_road(cell):
				grid.set_road(cell, IslandGrid.Road.NONE)
				result.roads_changed = true
	for building_id: int in result.removed:
		var record := world.building(building_id)
		var def := catalog.find(record.def_id)
		grid.fill_building(Footprint.rect(record.origin, def.size, record.rotation), 0)
		world.buildings.erase(building_id)
	if result.removed.is_empty() and not result.roads_changed:
		return CommandResult.refused(&"REASON_NOTHING_TO_DEMOLISH")
	return result
