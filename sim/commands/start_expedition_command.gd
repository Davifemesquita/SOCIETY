class_name StartExpeditionCommand
extends Command
## Expedição (Fase 69): manda o navio dado (da companhia, parado num porto, fora de rota) para o destino, pagando o custo
## dele. O navio sai do mapa até a volta (ExpeditionSystem).

const NO_SHIP := &"REASON_EXPEDITION_NO_SHIP"
const LOCKED := &"REASON_EXPEDITION_LOCKED"

var ship_id: int
var expedition_id: StringName


func _init(ship: int, expedition: StringName) -> void:
	ship_id = ship
	expedition_id = expedition


func execute(context: CommandContext) -> CommandResult:
	var world := context.world
	var reason := check(world, context.data, ship_id, expedition_id, context.free_build)
	if reason != &"":
		return CommandResult.refused(reason)
	var def := context.data.expedition(expedition_id)
	var ship: Ship = world.ships[ship_id]
	if not context.free_build:
		world.money -= def.cost_money
	var trip := ExpeditionsState.Trip.new()
	trip.number = world.expeditions_state.count
	trip.def_id = def.id
	trip.def = def
	trip.home = ship.at
	trip.ends_tick = world.tick + context.config.ticks_of(def.duration_s)
	ship.stop()
	trip.ship = ship
	world.expeditions_state.count += 1
	world.expeditions_state.trips.append(trip)
	world.ships.erase(ship_id)
	var result := CommandResult.new()
	result.ships_changed = true
	return result


## O motivo da recusa (vazio se dá): o navio tem de ser da companhia, estar parado num porto e fora de rota.
static func check(world: WorldState, data: GameData, ship: int, expedition: StringName, free_build: bool = false) -> StringName:
	var record: Ship = world.ships.get(ship)
	if record == null or record.owner != Ship.Owner.PLAYER or record.route_id != 0 or record.at == Ship.NOWHERE \
			or record.at == Ship.TRADER_POST or record.state not in [Ship.State.IDLE, Ship.State.DOCKED]:
		return NO_SHIP
	var def := data.expedition(expedition)
	if def == null or (def.after_milestone > world.milestones_reached and not free_build):
		return LOCKED
	if world.money < def.cost_money and not free_build:
		return PlacementRules.NO_MONEY
	return &""
