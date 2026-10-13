class_name MoveShipCommand
extends Command
## Manda um navio do jogador para uma ilha ou para o posto do comerciante. Ordem à mão tira o
## navio da rota; ele iça velas e o caminho sai da carta náutica (em outra thread).

var ship_id: int
var destination: int


func _init(ship: int, target: int) -> void:
	ship_id = ship
	destination = target


func execute(context: CommandContext) -> CommandResult:
	var world := context.world
	var ship := world.ship(ship_id)
	if ship == null or ship.owner != Ship.Owner.PLAYER:
		return CommandResult.refused(ShipRules.NO_SHIP)
	if not TradeRoute.valid_target(destination, world.islands.size()):
		return CommandResult.refused(PlacementRules.OUT_OF_ISLAND)
	ship.route_id = 0
	ship.stop()
	ship.destination = destination
	ship.at = Ship.NOWHERE
	ship.state = Ship.State.SAILING
	# iça velas; o caminho é pedido pelo sistema dos navios no próximo tick
	ship.timer = context.config.ship_cast_off_seconds
	var result := CommandResult.new()
	result.ships_changed = true
	return result
