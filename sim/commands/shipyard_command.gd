class_name ShipyardCommand
extends Command
## Encomenda ao estaleiro (um navio por vez): paga na hora a fração shipyard_cost_factor do preço do
## entreposto, conta no limite de navios do marco e espera o desbloqueio do navio. Cancelar devolve
## shipyard_cancel_refund das moedas pagas; o material não volta. A recusa diz o motivo (check), que
## o painel usa para desligar o botão.

const NOT_SHIPYARD := &"REASON_NOT_SHIPYARD"
const BUSY := &"REASON_SHIPYARD_BUSY"
const NO_ORDER := &"REASON_SHIPYARD_NO_ORDER"
const WRONG_SHIP := &"REASON_SHIPYARD_WRONG_SHIP"

var building_id: int
var ship_def_id: StringName
var cancel: bool = false


static func order(shipyard_id: int, def_id: StringName) -> ShipyardCommand:
	var command := ShipyardCommand.new()
	command.building_id = shipyard_id
	command.ship_def_id = def_id
	return command


static func cancel_order(shipyard_id: int) -> ShipyardCommand:
	var command := ShipyardCommand.new()
	command.building_id = shipyard_id
	command.cancel = true
	return command


## Por que o estaleiro não aceita a encomenda deste navio agora (ou OK).
static func check(world: WorldState, data: GameData, config: GameConfig, shipyard_id: int, def_id: StringName, free_build: bool = false) -> StringName:
	var record := world.building(shipyard_id)
	if record == null or not data.building(record.def_id).is_shipyard():
		return NOT_SHIPYARD
	if not data.building(record.def_id).shipyard_ships.has(def_id) or data.ship(def_id) == null:
		return WRONG_SHIP
	if world.shipyard_state.order(shipyard_id) != null:
		return BUSY
	if free_build:
		return PlacementRules.OK
	var def := data.ship(def_id)
	if world.milestones_reached < def.unlock_milestone:
		return PlacementRules.SHIP_LOCKED
	if world.player_ships().size() + world.shipyard_state.orders.size() >= MilestoneSystem.ship_limit(world, config):
		return PlacementRules.SHIP_LIMIT
	return PlacementRules.check_cost(world, world.economy(record.island_id), config, ShipyardSystem.cost_money(def, config),
			ShipyardSystem.cost_materials(def, config))


func execute(context: CommandContext) -> CommandResult:
	var world := context.world
	var state := world.shipyard_state
	if cancel:
		var item := state.order(building_id)
		if item == null:
			return CommandResult.refused(NO_ORDER)
		world.money += floorf(item.paid_money * context.config.shipyard_cancel_refund)
		state.orders.erase(building_id)
		return _changed()
	var reason := check(world, context.data, context.config, building_id, ship_def_id, context.free_build)
	if reason != PlacementRules.OK:
		return CommandResult.refused(reason)
	var def := context.data.ship(ship_def_id)
	var item := ShipyardState.Order.new()
	item.def_id = ship_def_id
	if not context.free_build:
		item.paid_money = ShipyardSystem.cost_money(def, context.config)
		world.money -= item.paid_money
		var materials := ShipyardSystem.cost_materials(def, context.config)
		var economy := world.economy(world.building(building_id).island_id)
		for material: StringName in materials:
			economy.take(material, materials[material])
	state.orders[building_id] = item
	return _changed()


func _changed() -> CommandResult:
	var result := CommandResult.new()
	result.changed.append(building_id)
	return result
