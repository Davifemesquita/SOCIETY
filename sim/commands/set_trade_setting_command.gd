class_name SetTradeSettingCommand
extends Command
## Ajuste do comércio passivo de uma ilha para um bem: vender acima de sell_above e comprar até
## buy_up_to toneladas; -1 desliga cada um.

var island_id: int
var good: StringName
var sell_above: int
var buy_up_to: int


func _init(island: int, good_id: StringName, sell: int, buy: int) -> void:
	island_id = island
	good = good_id
	sell_above = sell
	buy_up_to = buy


func execute(context: CommandContext) -> CommandResult:
	var economy := context.world.economy(island_id)
	if economy == null:
		return CommandResult.refused(PlacementRules.OUT_OF_ISLAND)
	if context.data.good(good) == null:
		return CommandResult.refused(ShipRules.BAD_ORDER)
	if sell_above >= 0:
		economy.sell_above[good] = sell_above
	else:
		economy.sell_above.erase(good)
	if buy_up_to >= 0:
		economy.buy_up_to[good] = buy_up_to
	else:
		economy.buy_up_to.erase(good)
	var result := CommandResult.new()
	result.island_id = island_id
	return result
