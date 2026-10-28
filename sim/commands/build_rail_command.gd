class_name BuildRailCommand
extends Command
## Ferrovia (Fase 70): põe trilho nas células dadas. Trilho vai em terra da ilha sem prédio, sem estrada e sem barranco
## (nem sobre o rio); uma célula inválida recusa o trecho inteiro; célula que já tem trilho é ignorada (e não é
## cobrada). Custa rail_cost_per_cell moedas e rail_planks_per_cell tábuas por célula nova.

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
	for cell: Vector2i in cells:
		var reason := check_cell(grid, cell, context.config)
		if context.ignore_terrain and reason in [PlacementRules.ON_WATER, PlacementRules.TOO_STEEP]:
			reason = PlacementRules.OK
		if reason != PlacementRules.OK:
			return CommandResult.refused(reason)
	var changed := new_cells(grid, cells)
	if not context.free_build:
		if not world.has_trading_post(island_id, context.data):
			return CommandResult.refused(PlacementRules.NEEDS_TRADING_POST)
		var money := changed * context.config.rail_cost_per_cell
		var materials := cost_materials(context.config, changed)
		var economy := world.economy(island_id)
		var reason := PlacementRules.check_cost(world, economy, context.config, money, materials)
		if reason != PlacementRules.OK:
			return CommandResult.refused(reason)
		world.money -= money
		for material: StringName in materials:
			economy.take(material, materials[material])
	var result := CommandResult.new()
	result.island_id = island_id
	for cell: Vector2i in cells:
		if not grid.has_rail(cell):
			grid.set_rail(cell, true)
			result.rails_changed = true
	if grid.clear_trees(cells):
		var area := Rect2i(cells[0], Vector2i.ONE)
		for cell: Vector2i in cells:
			area = area.expand(cell).expand(cell + Vector2i.ONE)
		result.trees_cleared = area
	return result


## Trilho só em terra da ilha, sem prédio nem estrada, fora do mar e do rio e sem barranco.
static func check_cell(grid: IslandGrid, cell: Vector2i, config: GameConfig) -> StringName:
	if not grid.in_bounds(cell):
		return PlacementRules.OUT_OF_ISLAND
	if grid.building_at(cell) != 0:
		return PlacementRules.OCCUPIED
	if grid.has_road(cell):
		return PlacementRules.ON_ROAD
	if grid.flat:
		return PlacementRules.OK
	if grid.ground_at(cell) != IslandGrid.Ground.LAND:
		return PlacementRules.ON_WATER
	if grid.area_relief(Rect2i(cell, Vector2i.ONE)) > config.max_road_relief_m + 0.0001:
		return PlacementRules.TOO_STEEP
	return PlacementRules.OK


## Células do traçado sem trilho ainda (as repetidas contam uma vez).
static func new_cells(grid: IslandGrid, path: Array[Vector2i]) -> int:
	var seen: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in path:
		if grid.in_bounds(cell) and not grid.has_rail(cell):
			seen[cell] = true
	return seen.size()


static func cost_materials(config: GameConfig, count: int) -> Dictionary[StringName, int]:
	var materials: Dictionary[StringName, int] = {}
	if count > 0 and config.rail_planks_per_cell > 0.0:
		materials[&"planks"] = ceili(count * config.rail_planks_per_cell - 0.000001)
	return materials
