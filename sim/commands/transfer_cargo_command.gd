class_name TransferCargoCommand
extends Command
## Carga à mão com o navio ancorado no porto de uma ilha: tons > 0 sobe do estoque para o
## porão, tons < 0 desce. Vai o que houver e o que couber.

var ship_id: int
var good: StringName
var tons: float


func _init(ship: int, good_id: StringName, amount: float) -> void:
	ship_id = ship
	good = good_id
	tons = amount


func execute(context: CommandContext) -> CommandResult:
	var world := context.world
	var ship := world.ship(ship_id)
	var reason := ShipRules.check_manual_trade(world, context.data, ship, good)
	if reason == ShipRules.OK and ship.at == Ship.TRADER_POST:
		reason = ShipRules.NOT_IN_PORT
	if reason != ShipRules.OK:
		return CommandResult.refused(reason)
	var derived := DerivedState.new()
	derived.capacity = ShipRules.capacities(world, context.data, context.config)
	CargoTransfer.single(world, context.data, context.config, derived, ship, ship.at, good, tons)
	var result := CommandResult.new()
	result.island_id = ship.at
	result.ships_changed = true
	return result
