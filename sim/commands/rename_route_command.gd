class_name RenameRouteCommand
extends Command
## Nome e grupo de uma rota (Fase 49): só para o jogador se achar; os navios não mudam nada. Cortados em MAX_LENGTH.

const MAX_LENGTH := 32

var route_id: int
var name: String
var group: String


func _init(route: int, route_name: String, route_group: String) -> void:
	route_id = route
	name = route_name.strip_edges().left(MAX_LENGTH)
	group = route_group.strip_edges().left(MAX_LENGTH)


func execute(context: CommandContext) -> CommandResult:
	var route: TradeRoute = context.world.routes.get(route_id)
	if route == null:
		return CommandResult.refused(ShipRules.NO_ROUTE)
	route.name = name
	route.group = group
	var result := CommandResult.new()
	result.routes_changed = true
	return result
