class_name BuildRoadCommand
extends Command
## Constrói estrada de terra nas células dadas. Uma célula inválida recusa o trecho inteiro;
## célula que já é estrada é ignorada (e não é cobrada).

var island_id: int
var cells: Array[Vector2i]


func _init(island: int, path: Array[Vector2i]) -> void:
	island_id = island
	cells = path


func execute(context: CommandContext) -> CommandResult:
	var world := context.world
	var grid := world.island(island_id)
	if grid == null:
		return CommandResult.refused(PlacementRules.OUT_OF_ISLAND)
	if cells.is_empty():
		return CommandResult.refused(&"REASON_EMPTY_ROAD")
	var new_cells := 0
	for cell: Vector2i in cells:
		var reason := PlacementRules.check_road_cell(grid, cell)
		if reason != PlacementRules.OK:
			return CommandResult.refused(reason)
		if not grid.has_road(cell):
			new_cells += 1
	var cost := new_cells * context.config.road_cost_per_cell
	if not context.free_build:
		var empty: Dictionary[StringName, int] = {}
		var reason := PlacementRules.check_cost(world, world.economy(island_id), context.config, cost, empty)
		if reason != PlacementRules.OK:
			return CommandResult.refused(reason)
		world.money -= cost
	var result := CommandResult.new()
	result.island_id = island_id
	for cell: Vector2i in cells:
		if not grid.has_road(cell):
			grid.set_road(cell, IslandGrid.Road.DIRT)
			result.roads_changed = true
	return result
