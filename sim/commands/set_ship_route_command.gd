class_name SetShipRouteCommand
extends Command
## Põe um navio do jogador numa rota (0 tira). Ele recomeça pela primeira parada; fora de rota
## fica ancorado onde estiver (ou segue até o destino, se já navegava).

var ship_id: int
var route_id: int


func _init(ship: int, route: int) -> void:
	ship_id = ship
	route_id = route


func execute(context: CommandContext) -> CommandResult:
	var world := context.world
	var ship := world.ship(ship_id)
	if ship == null or ship.owner != Ship.Owner.PLAYER:
		return CommandResult.refused(ShipRules.NO_SHIP)
	if route_id != 0 and not world.routes.has(route_id):
		return CommandResult.refused(ShipRules.NO_ROUTE)
	ShipRules.leave_route(ship)
	ship.route_id = route_id
	ship.stop_index = 0
	var result := CommandResult.new()
	result.ships_changed = true
	return result
