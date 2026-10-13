class_name ShipRules
extends RefCounted
## Conferências dos comandos de navio. O motivo da recusa é chave de tradução.

const OK := &""
const NO_SHIP := &"REASON_NO_SHIP"
const NO_ROUTE := &"REASON_NO_ROUTE"
const BAD_ORDER := &"REASON_BAD_ORDER"
const NOT_IN_PORT := &"REASON_SHIP_NOT_IN_PORT"
const NOT_AT_TRADER := &"REASON_SHIP_NOT_AT_TRADER"
const NOT_TRADED := &"REASON_NOT_TRADED"


## Carga à mão: navio do jogador, parado (fora de rota) num porto de ilha ou no comerciante.
static func check_manual_trade(world: WorldState, data: GameData, ship: Ship, good: StringName) -> StringName:
	if ship == null or ship.owner != Ship.Owner.PLAYER:
		return NO_SHIP
	if data.good(good) == null:
		return BAD_ORDER
	if ship.state != Ship.State.IDLE or ship.route_id != 0 or ship.at == Ship.NOWHERE:
		return NOT_IN_PORT
	if ship.at >= 0 and not world.has_trading_post(ship.at, data):
		return NOT_IN_PORT
	return OK


## Sai da rota no meio do caminho: atracado ou na fila, larga o cais e para ali; navegando,
## para onde está (a próxima ordem decide).
static func leave_route(ship: Ship) -> void:
	if ship.state == Ship.State.SAILING:
		ship.at = Ship.NOWHERE
	ship.stop()


## Estoque por bem de cada ilha sem o DerivedState: o maior nível de entreposto dela.
static func capacities(world: WorldState, data: GameData, config: GameConfig) -> Dictionary[int, float]:
	var result: Dictionary[int, float] = {}
	for record: BuildingRecord in world.buildings.values():
		var def := data.building(record.def_id)
		if def.is_trading_post:
			var current: float = result.get(record.island_id, 0.0)
			result[record.island_id] = maxf(current, def.level(record.level).storage_capacity_t)
	for island_id: int in world.islands.size():
		if not result.has(island_id):
			result[island_id] = float(config.island_storage_capacity_t)
	return result
