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
	if reason == PlacementRules.OK and not context.ignore_terrain:
		var profile := context.data.profile(world.economy(island_id).profile_id)
		reason = PlacementRules.check_terrain(grid, profile, def, origin, rotation, context.config)
	var first_trading_post := def != null and def.is_trading_post and not world.any_trading_post(context.data)
	var charge := not context.free_build and not first_trading_post
	var colony := charge and PlacementRules.founds_colony(world, context.data, island_id, def)
	var new_port := def != null and def.is_trading_post and not world.has_trading_post(island_id, context.data)
	if reason == PlacementRules.OK and not context.free_build and not context.config.instant_logistics:
		reason = PlacementRules.check_trading_post(world, context.data, island_id, def)
	if reason == PlacementRules.OK and colony:
		reason = PlacementRules.check_colony(world, context.data, context.config, island_id, def)
	if reason == PlacementRules.OK and charge and not colony:
		reason = PlacementRules.check_unlock(world, def)
	if reason == PlacementRules.OK and charge and not colony:
		reason = PlacementRules.check_cost(world, world.economy(island_id), context.config, def.cost_money, def.cost_materials)
	if reason != PlacementRules.OK:
		return CommandResult.refused(reason)
	if colony:
		# os materiais do entreposto saem do porão do navio ancorado
		var ship := PlacementRules.colony_ship(world, island_id, def.cost_materials)
		world.money -= def.cost_money
		for material: StringName in def.cost_materials:
			ship.unload_good(material, def.cost_materials[material])
	elif charge:
		_pay(world, world.economy(island_id), def)
	var record := BuildingRecord.new(world.next_building_id, def_id, island_id, origin, rotation)
	world.next_building_id += 1
	if def.kind == BuildingDef.Kind.RESIDENCE:
		record.tier = context.data.tiers[0].id
		record.happiness = context.config.happiness_base
	world.buildings[record.id] = record
	if def.is_production():
		world.carts[record.id] = Cart.new(record.id)
	var area := Footprint.rect(origin, def.size, rotation)
	grid.fill_building(area, record.id)
	var result := CommandResult.new()
	result.island_id = island_id
	result.placed.append(record.id)
	# a construção derruba as árvores do terreno
	var cells: Array[Vector2i] = []
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			cells.append(Vector2i(x, y))
	if grid.clear_trees(cells):
		result.trees_cleared = area
	if new_port:
		result.colonized = colony
		result.ships_changed = _unload_anchored(world, island_id, def)
	return result


## Porto novo: os navios do jogador ancorados na ilha, sem rota, descarregam tudo no estoque dela
## (o que couber no estoque do entreposto novo; o resto fica a bordo).
static func _unload_anchored(world: WorldState, island: int, def: BuildingDef) -> bool:
	var economy := world.economy(island)
	var capacity := float(def.level(0).storage_capacity_t)
	var unloaded := false
	for ship: Ship in world.player_ships():
		if ship.at != island or ship.state != Ship.State.IDLE or ship.route_id != 0:
			continue
		for good: StringName in ship.goods():
			var accepted := economy.add(good, ship.tons_of(good), capacity)
			ship.unload_good(good, accepted)
			unloaded = unloaded or accepted > 0.0
	return unloaded


static func _pay(world: WorldState, economy: IslandEconomy, def: BuildingDef) -> void:
	world.money -= def.cost_money
	for material: StringName in def.cost_materials:
		economy.take(material, def.cost_materials[material])
