class_name DemolishCommand
extends Command
## Demole todo prédio que encosta na área e toda estrada dentro dela, devolvendo ao estoque
## a fração configurada dos materiais (50%, arredondado para baixo).

var island_id: int
var area: Rect2i


func _init(island: int, region: Rect2i) -> void:
	island_id = island
	area = region


func execute(context: CommandContext) -> CommandResult:
	var world := context.world
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
	var economy := world.economy(island_id)
	for building_id: int in result.removed:
		var record := world.building(building_id)
		var def := context.data.building(record.def_id)
		grid.fill_building(Footprint.rect(record.origin, def.size, record.rotation), 0)
		world.buildings.erase(building_id)
		world.carts.erase(building_id)
		# o especialista do prédio (Fase 11) volta para a lista, sem posto
		if world.specialists_state.release(building_id):
			result.specialists_changed = true
		if not context.free_build:
			for material: StringName in def.cost_materials:
				economy.add(material, floorf(def.cost_materials[material] * context.config.demolish_refund), _capacity(context, island_id))
	if result.removed.is_empty() and not result.roads_changed:
		return CommandResult.refused(&"REASON_NOTHING_TO_DEMOLISH")
	return result


## Estoque da ilha pelo maior entreposto que sobrou (sem entreposto, o padrão da configuração).
static func _capacity(context: CommandContext, island_id: int) -> float:
	var best := float(context.config.island_storage_capacity_t)
	var found := false
	for record: BuildingRecord in context.world.buildings.values():
		var def := context.data.building(record.def_id)
		if record.island_id == island_id and def.is_trading_post:
			var level_capacity := float(def.level(record.level).storage_capacity_t)
			best = level_capacity if not found else maxf(best, level_capacity)
			found = true
	return best
