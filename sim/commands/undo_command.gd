class_name UndoCommand
extends Command
## Desfaz uma ação do UndoHistory (Fase 49): tira os prédios que ela criou, devolve os que ela tirou (o mesmo registro,
## com moradores e carroça), volta as estradas, o trilho (Fase 72), as árvores e as plantas do retângulo dela e devolve o dinheiro e o
## estoque. No mesmo tick, os valores exatos; depois, a diferença. Recusado (sem mexer em nada) fora da janela ou se o
## lugar mudou desde então (outro prédio no lote, estrada refeita).

var entry: UndoHistory.Entry


func _init(action: UndoHistory.Entry) -> void:
	entry = action


func execute(context: CommandContext) -> CommandResult:
	var world := context.world
	var grid := world.island(entry.island_id)
	if grid == null or entry.world != world:
		return CommandResult.refused(UndoHistory.NOTHING)
	if world.tick - entry.tick > roundi(context.config.undo_window_s * context.config.ticks_per_second):
		return CommandResult.refused(UndoHistory.EXPIRED)
	# confere tudo antes de mexer
	var freed: Dictionary[int, bool] = {}
	for building_id: int in entry.placed:
		if world.building(building_id) == null:
			return CommandResult.refused(UndoHistory.CHANGED)
		freed[building_id] = true
	for record: BuildingRecord in entry.removed:
		var footprint := Footprint.rect(record.origin, context.data.building(record.def_id).size, record.rotation)
		for y: int in range(footprint.position.y, footprint.end.y):
			for x: int in range(footprint.position.x, footprint.end.x):
				var holder := grid.building_at(Vector2i(x, y))
				if holder != 0 and not freed.has(holder):
					return CommandResult.refused(UndoHistory.CHANGED)
	if UndoHistory.region(grid.roads, grid.size.x, entry.area) != entry.roads_after:
		return CommandResult.refused(UndoHistory.CHANGED)
	if UndoHistory.region(grid.rails, grid.size.x, entry.area) != entry.rails_after:
		return CommandResult.refused(UndoHistory.CHANGED)
	var result := CommandResult.new()
	result.island_id = entry.island_id
	for building_id: int in entry.placed:
		var record := world.building(building_id)
		var def := context.data.building(record.def_id)
		grid.fill_building(Footprint.rect(record.origin, def.size, record.rotation), 0)
		world.buildings.erase(building_id)
		world.carts.erase(building_id)
		world.risks_state.forget(building_id)
		world.shipyard_state.forget(building_id)
		if world.specialists_state.release(building_id):
			result.specialists_changed = true
		world.exhibits_state.release(building_id)
		result.removed.append(building_id)
	for record: BuildingRecord in entry.removed:
		var def := context.data.building(record.def_id)
		world.buildings[record.id] = record
		if entry.removed_carts.has(record.id):
			world.carts[record.id] = entry.removed_carts[record.id]
		elif def.is_production():
			world.carts[record.id] = Cart.new(record.id)
		grid.fill_building(Footprint.rect(record.origin, def.size, record.rotation), record.id)
		result.placed.append(record.id)
	if entry.roads_before != entry.roads_after:
		var roads := grid.roads
		UndoHistory.paste(roads, grid.size.x, entry.area, entry.roads_before)
		grid.roads = roads
		result.roads_changed = true
	if entry.rails_before != entry.rails_after:
		var rails := grid.rails
		UndoHistory.paste(rails, grid.size.x, entry.area, entry.rails_before)
		grid.rails = rails
		result.rails_changed = true
	if entry.trees_before != entry.trees_after or entry.cleared_before != entry.cleared_after:
		var trees := grid.trees
		var cleared := grid.cleared_trees
		UndoHistory.paste(trees, grid.size.x, entry.area, entry.trees_before)
		UndoHistory.paste(cleared, grid.size.x, entry.area, entry.cleared_before)
		grid.trees = trees
		grid.cleared_trees = cleared
		result.trees_cleared = entry.area
	_refund(world, world.economy(entry.island_id))
	if world.next_building_id == entry.next_id_after:
		world.next_building_id = entry.next_id_before
	if world.plans.keys() == entry.plans_after.keys() and entry.plans_before.keys() != entry.plans_after.keys():
		world.plans = entry.plans_before.duplicate()
		if world.next_plan_id == entry.next_plan_after:
			world.next_plan_id = entry.next_plan_before
		result.plans_changed = true
	return result


## O dinheiro e o estoque: no mesmo tick, os valores de antes (idêntico); depois, só a diferença que a ação fez (o que a
## produção mudou nesse meio tempo fica), sem estoque negativo.
func _refund(world: WorldState, economy: IslandEconomy) -> void:
	if world.tick == entry.tick:
		world.money = entry.money_before
		economy.stock = entry.stock_before.duplicate()
		return
	world.money += entry.money_before - entry.money_after
	var goods: Dictionary[StringName, bool] = {}
	for good: StringName in entry.stock_before:
		goods[good] = true
	for good: StringName in entry.stock_after:
		goods[good] = true
	for good: StringName in goods:
		var delta: float = entry.stock_before.get(good, 0.0) - entry.stock_after.get(good, 0.0)
		if delta != 0.0:
			economy.stock[good] = maxf(0.0, economy.amount(good) + delta)
