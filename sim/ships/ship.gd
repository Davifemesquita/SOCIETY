class_name Ship
extends RefCounted
## Um navio no mundo (seção 6): registro da simulação, não nó. O porão tem compartimentos de
## um bem cada. Parado (IDLE) ele fica ancorado onde está (at); navegando segue os pontos da
## carta náutica; numa parada de rota espera vaga no porto (WAITING) e carrega no cais (DOCKED).

enum State { IDLE, SAILING, WAITING, DOCKED }
enum Owner { PLAYER, TRADER }

## Destino e lugar especiais: em mar aberto (nenhum) e o posto do comerciante.
const NOWHERE := -1
const TRADER_POST := -2

var id: int
var def_id: StringName
var owner: Owner = Owner.PLAYER
## Posição no plano XZ do mundo, em metros. NaN = ainda não posto no mar (o navio inicial e o
## recém-comprado: a simulação o põe no porto da ilha dele).
var position := Vector2(NAN, NAN)
## Rumo (ângulo no plano XZ; 0 = para +X).
var heading: float = 0.0
var state: State = State.IDLE
## Ilha (índice), TRADER_POST ou NOWHERE: para onde vai e onde está ancorado.
var destination: int = NOWHERE
var at: int = NOWHERE
## Pontos que faltam do caminho, em metros; waypoint é o próximo.
var waypoints := PackedVector2Array()
var waypoint: int = 0
## Píer ou entreposto em que está atracado (0 = nenhum).
var berth_id: int = 0
## Tick em que chegou à fila do porto (a fila é por ordem de chegada).
var queued_at: int = 0
## Segundos de carga ou de espera que faltam.
var timer: float = 0.0
## Rota que o navio repete (0 = nenhuma) e a parada da vez.
var route_id: int = 0
var stop_index: int = 0
var slot_goods: Array[StringName] = []
var slot_tons: Array[float] = []

# runtime: posição no tick anterior, para a vista interpolar
var previous_position := Vector2(NAN, NAN)
var previous_heading: float = 0.0


func _init(ship_id: int, def: ShipDef, ship_owner: Owner = Owner.PLAYER) -> void:
	id = ship_id
	owner = ship_owner
	if def != null:
		def_id = def.id
		for slot: int in def.cargo_slots:
			slot_goods.append(&"")
			slot_tons.append(0.0)


func is_placed() -> bool:
	return not is_nan(position.x)


func tons_of(good: StringName) -> float:
	var total := 0.0
	for slot: int in slot_goods.size():
		if slot_goods[slot] == good:
			total += slot_tons[slot]
	return total


func total_tons() -> float:
	var total := 0.0
	for tons: float in slot_tons:
		total += tons
	return total


## Bens a bordo, na ordem dos compartimentos (sem repetir).
func goods() -> Array[StringName]:
	var list: Array[StringName] = []
	for good: StringName in slot_goods:
		if good != &"" and not list.has(good):
			list.append(good)
	return list


## Quanto do bem ainda cabe: o resto dos compartimentos dele e os compartimentos vazios.
func room_for(good: StringName, slot_capacity: float) -> float:
	var room := 0.0
	for slot: int in slot_goods.size():
		if slot_goods[slot] == good:
			room += slot_capacity - slot_tons[slot]
		elif slot_goods[slot] == &"":
			room += slot_capacity
	return room


## Põe o bem a bordo: completa os compartimentos dele e depois ocupa os vazios. Devolve o que
## coube.
func load_good(good: StringName, tons: float, slot_capacity: float) -> float:
	var left := tons
	for pass_index: int in 2:
		for slot: int in slot_goods.size():
			if left <= 0.0:
				break
			var fits := slot_goods[slot] == good if pass_index == 0 else slot_goods[slot] == &""
			if not fits:
				continue
			var put := minf(left, slot_capacity - slot_tons[slot])
			if put <= 0.0:
				continue
			slot_goods[slot] = good
			slot_tons[slot] += put
			left -= put
	return tons - left


## Tira o bem do porão (do último compartimento para o primeiro). Devolve o que saiu.
func unload_good(good: StringName, tons: float) -> float:
	var left := tons
	for slot: int in range(slot_goods.size() - 1, -1, -1):
		if left <= 0.0:
			break
		if slot_goods[slot] != good:
			continue
		var taken := minf(left, slot_tons[slot])
		slot_tons[slot] -= taken
		left -= taken
		if slot_tons[slot] <= 0.000001:
			slot_tons[slot] = 0.0
			slot_goods[slot] = &""
	return tons - left


## Para no lugar onde está, sem rota em andamento.
func stop() -> void:
	state = State.IDLE
	waypoints = PackedVector2Array()
	waypoint = 0
	berth_id = 0
	timer = 0.0


func to_dict() -> Dictionary:
	return {"id": id, "def": def_id, "owner": owner, "position": position, "heading": heading, "state": state,
			"destination": destination, "at": at, "waypoints": waypoints, "waypoint": waypoint, "berth": berth_id,
			"queued_at": queued_at, "timer": timer, "route": route_id, "stop": stop_index,
			"slot_goods": slot_goods.duplicate(), "slot_tons": slot_tons.duplicate()}


## Lê um navio do save; null se algum campo vier com tipo errado ou fora do lugar.
static func from_dict(data: Dictionary, game_data: GameData) -> Ship:
	var raw_id: Variant = data.get("id")
	var raw_def: Variant = data.get("def")
	var raw_owner: Variant = data.get("owner")
	var raw_position: Variant = data.get("position")
	var raw_heading: Variant = data.get("heading")
	var raw_state: Variant = data.get("state")
	var raw_destination: Variant = data.get("destination")
	var raw_at: Variant = data.get("at")
	var raw_waypoints: Variant = data.get("waypoints")
	var raw_waypoint: Variant = data.get("waypoint")
	var raw_berth: Variant = data.get("berth")
	var raw_queued: Variant = data.get("queued_at")
	var raw_timer: Variant = data.get("timer")
	var raw_route: Variant = data.get("route")
	var raw_stop: Variant = data.get("stop")
	var raw_goods: Variant = data.get("slot_goods")
	var raw_tons: Variant = data.get("slot_tons")
	if not (raw_id is int and raw_def is StringName and raw_owner is int and raw_position is Vector2 and raw_heading is float \
			and raw_state is int and raw_destination is int and raw_at is int and raw_waypoints is PackedVector2Array \
			and raw_waypoint is int and raw_berth is int and raw_queued is int and raw_timer is float and raw_route is int \
			and raw_stop is int and raw_goods is Array and raw_tons is Array):
		return null
	var def_name: StringName = raw_def
	var def := game_data.ship(def_name)
	var ship_id: int = raw_id
	var owner_value: int = raw_owner
	var state_value: int = raw_state
	if def == null or ship_id <= 0 or owner_value < Owner.PLAYER or owner_value > Owner.TRADER \
			or state_value < State.IDLE or state_value > State.DOCKED:
		return null
	var ship := Ship.new(ship_id, def, owner_value)
	ship.position = raw_position
	ship.previous_position = ship.position
	ship.heading = raw_heading
	ship.previous_heading = ship.heading
	ship.state = state_value
	ship.destination = raw_destination
	ship.at = raw_at
	ship.waypoints = raw_waypoints
	ship.waypoint = raw_waypoint
	ship.berth_id = raw_berth
	ship.queued_at = raw_queued
	ship.timer = raw_timer
	ship.route_id = raw_route
	ship.stop_index = raw_stop
	var goods_list: Array = raw_goods
	var tons_list: Array = raw_tons
	if goods_list.size() != def.cargo_slots or tons_list.size() != def.cargo_slots:
		return null
	for slot: int in def.cargo_slots:
		var good: Variant = goods_list[slot]
		var tons: Variant = tons_list[slot]
		if not (good is StringName and tons is float):
			return null
		var good_id: StringName = good
		var tons_value: float = tons
		if tons_value < 0.0 or tons_value > def.slot_capacity_t + 0.000001 or (good_id != &"" and game_data.good(good_id) == null):
			return null
		ship.slot_goods[slot] = good_id
		ship.slot_tons[slot] = tons_value
	if ship.waypoint < 0 or ship.waypoint > ship.waypoints.size():
		return null
	return ship
