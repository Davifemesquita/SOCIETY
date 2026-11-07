class_name ExpeditionsState
extends RefCounted
## Expedições em andamento (Fase 69), no save: cada uma com o navio (fora do mapa enquanto viaja), o porto de onde ele
## saiu, o tick da volta e o número dela (o do sorteio da volta). count é quantas já saíram.


class Trip:
	var number: int = 0
	var def_id: StringName
	var ship: Ship
	var home: int = 0
	var ends_tick: int = 0
	## runtime: a definição (resolvida ao sair e ao carregar), fora do save.
	var def: ExpeditionDef

	func to_dict() -> Dictionary:
		return {"number": number, "def": def_id, "ship": ship.to_dict(), "home": home, "ends": ends_tick}


var trips: Array[Trip] = []
var count: int = 0


## A viagem do navio (null se ele não está em expedição).
func trip_of(ship_id: int) -> Trip:
	for trip: Trip in trips:
		if trip.ship.id == ship_id:
			return trip
	return null


func to_dict() -> Dictionary:
	var list: Array[Dictionary] = []
	for trip: Trip in trips:
		list.append(trip.to_dict())
	return {"trips": list, "count": count}


static func from_dict(data: Dictionary, game_data: GameData, island_count: int) -> ExpeditionsState:
	var raw_trips: Variant = data.get("trips")
	var raw_count: Variant = data.get("count")
	if not (raw_trips is Array and raw_count is int):
		return null
	var state := ExpeditionsState.new()
	state.count = raw_count
	var list: Array = raw_trips
	for raw: Variant in list:
		if not raw is Dictionary:
			return null
		var entry: Dictionary = raw
		var raw_number: Variant = entry.get("number")
		var raw_def: Variant = entry.get("def")
		var raw_ship: Variant = entry.get("ship")
		var raw_home: Variant = entry.get("home")
		var raw_ends: Variant = entry.get("ends")
		if not (raw_number is int and raw_def is StringName and raw_ship is Dictionary and raw_home is int and raw_ends is int):
			return null
		var trip := Trip.new()
		trip.number = raw_number
		trip.def_id = raw_def
		trip.def = game_data.expedition(trip.def_id)
		var ship_data: Dictionary = raw_ship
		trip.ship = Ship.from_dict(ship_data, game_data)
		trip.home = raw_home
		trip.ends_tick = raw_ends
		if trip.def == null or trip.ship == null or trip.home < 0 or trip.home >= island_count or trip.number >= state.count:
			return null
		state.trips.append(trip)
	return state
