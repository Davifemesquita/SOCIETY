class_name ReplaceCommand
extends Command
## Substituir em área (Fase 49): todo prédio que encosta no retângulo, do mesmo tamanho do novo e de outro tipo, vira o
## novo no mesmo lugar e na mesma rotação. O velho devolve a fração de demolição; o novo é cobrado inteiro. Confere o
## terreno e o desbloqueio de cada um e o custo de todos juntos antes de mexer em qualquer coisa. O entreposto fica.

const NOTHING := &"REASON_NOTHING_TO_REPLACE"

var island_id: int
var area: Rect2i
var def_id: StringName


func _init(island: int, region: Rect2i, new_def: StringName) -> void:
	island_id = island
	area = region
	def_id = new_def


func execute(context: CommandContext) -> CommandResult:
	var world := context.world
	var grid := world.island(island_id)
	var def := context.data.building(def_id)
	if grid == null or def == null:
		return CommandResult.refused(PlacementRules.OUT_OF_ISLAND)
	var profile := context.data.profile(world.economy(island_id).profile_id)
	var chosen: Array[BuildingRecord] = []
	var clipped := area.intersection(Rect2i(Vector2i.ZERO, grid.size))
	for y: int in range(clipped.position.y, clipped.end.y):
		for x: int in range(clipped.position.x, clipped.end.x):
			var record := world.building(grid.building_at(Vector2i(x, y)))
			if record == null or chosen.has(record) or record.def_id == def_id:
				continue
			var old := context.data.building(record.def_id)
			if old.size != def.size or old.is_trading_post:
				continue
			if not context.ignore_terrain and PlacementRules.check_terrain(grid, profile, def, record.origin, record.rotation,
					context.config) != PlacementRules.OK:
				continue
			chosen.append(record)
	if chosen.is_empty():
		return CommandResult.refused(NOTHING)
	var economy := world.economy(island_id)
	if not context.free_build:
		var reason := PlacementRules.check_unlock(world, def)
		if reason == PlacementRules.OK:
			var materials: Dictionary[StringName, int] = {}
			for material: StringName in def.cost_materials:
				materials[material] = def.cost_materials[material] * chosen.size()
			reason = PlacementRules.check_cost(world, economy, context.config, def.cost_money * chosen.size(), materials)
		if reason != PlacementRules.OK:
			return CommandResult.refused(reason)
	var result := CommandResult.new()
	result.island_id = island_id
	for record: BuildingRecord in chosen:
		var old := context.data.building(record.def_id)
		var footprint := Footprint.rect(record.origin, old.size, record.rotation)
		world.buildings.erase(record.id)
		world.carts.erase(record.id)
		world.risks_state.forget(record.id)
		world.shipyard_state.forget(record.id)
		if world.specialists_state.release(record.id):
			result.specialists_changed = true
		result.removed.append(record.id)
		if not context.free_build:
			for material: StringName in old.cost_materials:
				economy.add(material, floorf(old.cost_materials[material] * context.config.demolish_refund),
						DemolishCommand._capacity(context, island_id))
			world.money -= def.cost_money
			for material: StringName in def.cost_materials:
				economy.take(material, def.cost_materials[material])
		var fresh := BuildingRecord.new(world.next_building_id, def_id, island_id, record.origin, record.rotation)
		world.next_building_id += 1
		if def.kind == BuildingDef.Kind.RESIDENCE:
			fresh.tier = context.data.tiers[0].id
			fresh.happiness = context.config.happiness_base
		world.buildings[fresh.id] = fresh
		if def.is_production():
			world.carts[fresh.id] = Cart.new(fresh.id)
		grid.fill_building(footprint, fresh.id)
		result.placed.append(fresh.id)
	return result
