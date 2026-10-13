class_name TradeRoute
extends RefCounted
## Rota comercial (seção 6): uma sequência de paradas (ilhas, ou o posto do comerciante) e, em
## cada uma, as ordens de carga. Os navios da rota repetem o ciclo até ela mudar. Na ilha,
## descarregar põe no estoque e carregar tira dele; no comerciante, descarregar vende e carregar
## compra. Cada ordem é um teto: vai o que houver e o que couber.


class Order:
	var good: StringName
	## true = carregar (ou comprar); false = descarregar (ou vender).
	var is_load: bool = true
	var tons: int = 0

	func _init(order_good: StringName = &"", loading: bool = true, order_tons: int = 0) -> void:
		good = order_good
		is_load = loading
		tons = order_tons

	func to_dict() -> Dictionary:
		return {"good": good, "load": is_load, "tons": tons}


class Stop:
	## Índice da ilha, ou Ship.TRADER_POST.
	var target: int = 0
	var orders: Array[Order] = []

	func _init(stop_target: int = 0) -> void:
		target = stop_target

	func to_dict() -> Dictionary:
		var list: Array[Dictionary] = []
		for order: Order in orders:
			list.append(order.to_dict())
		return {"target": target, "orders": list}

	func duplicate() -> Stop:
		var copy := Stop.new(target)
		for order: Order in orders:
			copy.orders.append(Order.new(order.good, order.is_load, order.tons))
		return copy


var id: int
var stops: Array[Stop] = []


func _init(route_id: int) -> void:
	id = route_id


func stop(index: int) -> Stop:
	return stops[index] if index >= 0 and index < stops.size() else null


func to_dict() -> Dictionary:
	var list: Array[Dictionary] = []
	for item: Stop in stops:
		list.append(item.to_dict())
	return {"id": id, "stops": list}


## Lê uma rota do save; null se algo vier com tipo errado ou apontar para o que não existe.
static func from_dict(data: Dictionary, island_count: int, game_data: GameData) -> TradeRoute:
	var raw_id: Variant = data.get("id")
	var raw_stops: Variant = data.get("stops")
	if not (raw_id is int and raw_stops is Array):
		return null
	var route_id: int = raw_id
	if route_id <= 0:
		return null
	var route := TradeRoute.new(route_id)
	var stop_list: Array = raw_stops
	for raw_stop: Variant in stop_list:
		if not raw_stop is Dictionary:
			return null
		var stop_data: Dictionary = raw_stop
		var parsed := parse_stop(stop_data, island_count, game_data)
		if parsed == null:
			return null
		route.stops.append(parsed)
	return route


static func parse_stop(data: Dictionary, island_count: int, game_data: GameData) -> Stop:
	var raw_target: Variant = data.get("target")
	var raw_orders: Variant = data.get("orders")
	if not (raw_target is int and raw_orders is Array):
		return null
	var target: int = raw_target
	if not valid_target(target, island_count):
		return null
	var parsed := Stop.new(target)
	var order_list: Array = raw_orders
	for raw_order: Variant in order_list:
		if not raw_order is Dictionary:
			return null
		var order_data: Dictionary = raw_order
		var raw_good: Variant = order_data.get("good")
		var raw_load: Variant = order_data.get("load")
		var raw_tons: Variant = order_data.get("tons")
		if not (raw_good is StringName and raw_load is bool and raw_tons is int):
			return null
		var good: StringName = raw_good
		var loading: bool = raw_load
		var tons: int = raw_tons
		if game_data.good(good) == null or tons <= 0:
			return null
		parsed.orders.append(Order.new(good, loading, tons))
	return parsed


static func valid_target(target: int, island_count: int) -> bool:
	return target == Ship.TRADER_POST or (target >= 0 and target < island_count)
