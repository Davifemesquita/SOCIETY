class_name EditRouteCommand
extends Command
## Troca as paradas de uma rota inteira (destinos e ordens já conferidos). Os navios dela
## recomeçam pela primeira parada (seção 6: repetem o ciclo até a rota mudar).

var route_id: int
var stops: Array[TradeRoute.Stop] = []


func _init(route: int, new_stops: Array[TradeRoute.Stop]) -> void:
	route_id = route
	for stop: TradeRoute.Stop in new_stops:
		stops.append(stop.duplicate())


func execute(context: CommandContext) -> CommandResult:
	var world := context.world
	var route: TradeRoute = world.routes.get(route_id)
	if route == null:
		return CommandResult.refused(ShipRules.NO_ROUTE)
	for stop: TradeRoute.Stop in stops:
		if not TradeRoute.valid_target(stop.target, world.islands.size()):
			return CommandResult.refused(PlacementRules.OUT_OF_ISLAND)
		for order: TradeRoute.Order in stop.orders:
			if context.data.good(order.good) == null or order.tons <= 0:
				return CommandResult.refused(ShipRules.BAD_ORDER)
	route.stops = stops
	var result := CommandResult.new()
	result.routes_changed = true
	for ship: Ship in world.player_ships():
		if ship.route_id == route_id:
			ShipRules.leave_route(ship)
			ship.stop_index = 0
			result.ships_changed = true
	return result
