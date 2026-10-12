class_name PlaceBuildingCommand
extends Command
## Constrói um prédio: confere lugar, terreno, desbloqueio e custo, e cobra.
## Estrada na entrada não é exigida: sem ela o prédio fica com alerta.

var island_id: int
var def_id: StringName
var origin: Vector2i
var rotation: int


func _init(island: int, def: StringName, at: Vector2i, rot: int) -> void:
	island_id = island
	def_id = def
	origin = at
	rotation = rot


func execute(context: CommandContext) -> CommandResult:
	var world := context.world
	var grid := world.island(island_id)
	if grid == null:
		return CommandResult.refused(PlacementRules.OUT_OF_ISLAND)
	var def := context.data.building(def_id)
	var reason := PlacementRules.check_building(grid, def, origin, rotation)
	if reason == PlacementRules.OK:
		var profile := context.data.profile(world.economy(island_id).profile_id)
		reason = PlacementRules.check_terrain(grid, profile, def, origin, rotation)
	var first_trading_post := def != null and def.is_trading_post and not world.any_trading_post(context.data)
	var charge := not context.free_build and not first_trading_post
	if reason == PlacementRules.OK and not context.free_build and not context.config.instant_logistics:
		reason = PlacementRules.check_trading_post(world, context.data, island_id, def)
	if reason == PlacementRules.OK and charge:
		reason = PlacementRules.check_unlock(world, def)
	if reason == PlacementRules.OK and charge:
		reason = PlacementRules.check_cost(world, world.economy(island_id), context.config, def.cost_money, def.cost_materials)
	if reason != PlacementRules.OK:
		return CommandResult.refused(reason)
	if charge:
		_pay(world, world.economy(island_id), def)
	var record := BuildingRecord.new(world.next_building_id, def_id, island_id, origin, rotation)
	world.next_building_id += 1
	if def.kind == BuildingDef.Kind.RESIDENCE:
		record.tier = context.data.tiers[0].id
		record.happiness = context.config.happiness_base
	world.buildings[record.id] = record
	if def.is_production():
		world.carts[record.id] = Cart.new(record.id)
	grid.fill_building(Footprint.rect(origin, def.size, rotation), record.id)
	var result := CommandResult.new()
	result.island_id = island_id
	result.placed.append(record.id)
	return result


static func _pay(world: WorldState, economy: IslandEconomy, def: BuildingDef) -> void:
	world.money -= def.cost_money
	for material: StringName in def.cost_materials:
		economy.take(material, def.cost_materials[material])
