class_name DeleteRouteCommand
extends Command
## Apaga uma rota; os navios dela ficam sem rota, ancorados onde estiverem.

var route_id: int


func _init(route: int) -> void:
	route_id = route


func execute(context: CommandContext) -> CommandResult:
	var world := context.world
	if not world.routes.has(route_id):
		return CommandResult.refused(ShipRules.NO_ROUTE)
	world.routes.erase(route_id)
	var result := CommandResult.new()
	result.routes_changed = true
	for ship: Ship in world.player_ships():
		if ship.route_id == route_id:
			ShipRules.leave_route(ship)
			ship.route_id = 0
			result.ships_changed = true
	return result
