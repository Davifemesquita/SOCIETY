class_name BuyShipCommand
extends Command
## Compra um navio no entreposto de uma ilha: o caixa e o estoque da ilha pagam, e o marco de
## população precisa liberar mais um navio. Ele aparece ancorado no porto da ilha.

var island_id: int
var ship_def_id: StringName


func _init(island: int, def: StringName = &"merchant_ship") -> void:
	island_id = island
	ship_def_id = def


func execute(context: CommandContext) -> CommandResult:
	var world := context.world
	var def := context.data.ship(ship_def_id)
	if world.island(island_id) == null:
		return CommandResult.refused(PlacementRules.OUT_OF_ISLAND)
	if not context.free_build:
		var reason := PlacementRules.check_ship_purchase(world, context.data, context.config, island_id, def)
		if reason != PlacementRules.OK:
			return CommandResult.refused(reason)
		world.money -= def.cost_money
		for material: StringName in def.cost_materials:
			world.economy(island_id).take(material, def.cost_materials[material])
	elif def == null:
		return CommandResult.refused(PlacementRules.UNKNOWN_BUILDING)
	var ship := Ship.new(world.next_ship_id, def)
	world.next_ship_id += 1
	ship.at = island_id
	world.ships[ship.id] = ship
	var result := CommandResult.new()
	result.island_id = island_id
	result.ships_changed = true
	result.created_id = ship.id
	return result
