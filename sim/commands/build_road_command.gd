class_name BuildRoadCommand
extends Command
## Constrói estrada de terra nas células dadas. Uma célula inválida recusa o trecho inteiro;
## célula que já é estrada é ignorada.

var island_id: int
var cells: Array[Vector2i]


func _init(island: int, path: Array[Vector2i]) -> void:
	island_id = island
	cells = path


func execute(world: WorldState, _catalog: BuildingCatalog) -> CommandResult:
	var grid := world.island(island_id)
	if grid == null:
		return CommandResult.refused(PlacementRules.OUT_OF_ISLAND)
	if cells.is_empty():
		return CommandResult.refused(&"REASON_EMPTY_ROAD")
	for cell: Vector2i in cells:
		var reason := PlacementRules.check_road_cell(grid, cell)
		if reason != PlacementRules.OK:
			return CommandResult.refused(reason)
	var result := CommandResult.new()
	result.island_id = island_id
	for cell: Vector2i in cells:
		if not grid.has_road(cell):
			grid.set_road(cell, IslandGrid.Road.DIRT)
			result.roads_changed = true
	return result
