class_name TradeWithTraderCommand
extends Command
## Comércio ativo com o navio no posto do comerciante: tons > 0 compra (o que o caixa pagar e
## o porão levar), tons < 0 vende o que estiver a bordo. Só bens da lista dele.

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
	if reason == ShipRules.OK and ship.at != Ship.TRADER_POST:
		reason = ShipRules.NOT_AT_TRADER
	var trader := context.data.trader()
	if reason == ShipRules.OK and (trader == null or not (trader.sells if tons > 0.0 else trader.buys).has(good)):
		reason = ShipRules.NOT_TRADED
	if reason != ShipRules.OK:
		return CommandResult.refused(reason)
	CargoTransfer.single(world, context.data, context.config, DerivedState.new(), ship, Ship.TRADER_POST, good, tons)
	var result := CommandResult.new()
	result.ships_changed = true
	return result
