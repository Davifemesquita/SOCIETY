class_name CreateRouteCommand
extends Command
## Cria uma rota vazia; as paradas entram pelo EditRouteCommand. O id vai em created_id.


func execute(context: CommandContext) -> CommandResult:
	var world := context.world
	var route := TradeRoute.new(world.next_route_id)
	world.next_route_id += 1
	world.routes[route.id] = route
	var result := CommandResult.new()
	result.routes_changed = true
	result.created_id = route.id
	return result
