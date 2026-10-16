class_name ShipyardState
extends RefCounted
## Encomendas dos estaleiros, no save: um navio por estaleiro, com o tipo, quanto já foi feito (0..1)
## e as moedas pagas (a devolução do cancelamento sai delas).


class Order:
	var def_id: StringName
	var progress: float = 0.0
	var paid_money: int = 0


## Estaleiro (id do prédio) → encomenda em andamento.
var orders: Dictionary[int, Order] = {}
## Navios entregues (estatística e testes).
var ships_built: int = 0


func order(shipyard_id: int) -> Order:
	return orders.get(shipyard_id)


## O estaleiro saiu do mundo: a encomenda some (sem devolução, como o material da obra).
func forget(shipyard_id: int) -> void:
	orders.erase(shipyard_id)


func to_dict() -> Dictionary:
	var ids: Array[int] = []
	ids.assign(orders.keys())
	ids.sort()
	var list: Array[Dictionary] = []
	for shipyard_id: int in ids:
		var item := orders[shipyard_id]
		list.append({"shipyard": shipyard_id, "ship": item.def_id, "progress": item.progress, "paid": item.paid_money})
	return {"orders": list, "ships_built": ships_built}


## Lê o estado de um save; null se algo vier com tipo errado, repetido, num prédio que não é estaleiro
## ou com um navio que aquele estaleiro não faz.
static func from_dict(data: Dictionary, world: WorldState, game_data: GameData) -> ShipyardState:
	var raw_orders: Variant = data.get("orders")
	var raw_built: Variant = data.get("ships_built")
	if not (raw_orders is Array and raw_built is int):
		return null
	var state := ShipyardState.new()
	state.ships_built = raw_built
	if state.ships_built < 0:
		return null
	var list: Array = raw_orders
	for raw: Variant in list:
		if not raw is Dictionary:
			return null
		var entry: Dictionary = raw
		var raw_shipyard: Variant = entry.get("shipyard")
		var raw_ship: Variant = entry.get("ship")
		var raw_progress: Variant = entry.get("progress")
		var raw_paid: Variant = entry.get("paid")
		if not (raw_shipyard is int and raw_ship is StringName and raw_progress is float and raw_paid is int):
			return null
		var shipyard_id: int = raw_shipyard
		var record := world.building(shipyard_id)
		if record == null or state.orders.has(shipyard_id) or not game_data.building(record.def_id).shipyard_ships.has(raw_ship):
			return null
		var item := Order.new()
		item.def_id = raw_ship
		item.progress = raw_progress
		item.paid_money = raw_paid
		if item.progress < 0.0 or item.progress >= 1.0 or item.paid_money < 0:
			return null
		state.orders[shipyard_id] = item
	return state
