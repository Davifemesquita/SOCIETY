class_name BuildRoadCommand
extends Command
## Constrói estrada nas células dadas: de terra, ou de paralelepípedo (Fase 8), que também
## calça a terra que já existe. Uma célula inválida recusa o trecho inteiro; célula que já tem
## a estrada pedida é ignorada (e não é cobrada).

var island_id: int
var cells: Array[Vector2i]
var paved: bool


func _init(island: int, path: Array[Vector2i], paved_road: bool = false) -> void:
	island_id = island
	cells = path
	paved = paved_road


func execute(context: CommandContext) -> CommandResult:
	var world := context.world
	var grid := world.island(island_id)
	if grid == null:
		return CommandResult.refused(PlacementRules.OUT_OF_ISLAND)
	if cells.is_empty():
		return CommandResult.refused(&"REASON_EMPTY_ROAD")
	for cell: Vector2i in cells:
		var reason := PlacementRules.check_road_cell(grid, cell, context.config)
		if context.ignore_terrain and reason in [PlacementRules.ON_WATER, PlacementRules.TOO_STEEP]:
			reason = PlacementRules.OK
		if reason != PlacementRules.OK:
			return CommandResult.refused(reason)
	var changed := new_cells(grid, cells, paved)
	if not context.free_build and not context.config.instant_logistics and not world.has_trading_post(island_id, context.data):
		return CommandResult.refused(PlacementRules.NEEDS_TRADING_POST)
	if not context.free_build:
		if paved and world.population(context.config.paved_road_unlock_tier) < context.config.paved_road_unlock_residents:
			return CommandResult.refused(PlacementRules.LOCKED)
		var money := cost_money(context.config, changed, paved)
		var materials := cost_materials(context.config, changed, paved)
		var economy := world.economy(island_id)
		var reason := PlacementRules.check_cost(world, economy, context.config, money, materials)
		if reason != PlacementRules.OK:
			return CommandResult.refused(reason)
		world.money -= money
		for material: StringName in materials:
			economy.take(material, materials[material])
	var result := CommandResult.new()
	result.island_id = island_id
	var kind := IslandGrid.Road.PAVED if paved else IslandGrid.Road.DIRT
	for cell: Vector2i in cells:
		if _needs(grid, cell, paved):
			grid.set_road(cell, kind)
			result.roads_changed = true
	if grid.clear_trees(cells):
		var area := Rect2i(cells[0], Vector2i.ONE)
		for cell: Vector2i in cells:
			area = area.expand(cell).expand(cell + Vector2i.ONE)
		result.trees_cleared = area
	return result


## Células do traçado que mudam (as repetidas contam uma vez).
static func new_cells(grid: IslandGrid, path: Array[Vector2i], paved_road: bool) -> int:
	var seen: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in path:
		if grid.in_bounds(cell) and _needs(grid, cell, paved_road):
			seen[cell] = true
	return seen.size()


static func cost_money(config: GameConfig, count: int, paved_road: bool) -> int:
	return count * (config.paved_road_cost_per_cell if paved_road else config.road_cost_per_cell)


static func cost_materials(config: GameConfig, count: int, paved_road: bool) -> Dictionary[StringName, int]:
	var materials: Dictionary[StringName, int] = {}
	if paved_road and count > 0:
		materials[&"bricks"] = ceili(count * config.paved_road_bricks_per_cell - 0.000001)
	return materials


static func _needs(grid: IslandGrid, cell: Vector2i, paved_road: bool) -> bool:
	return not grid.is_paved(cell) if paved_road else not grid.has_road(cell)
