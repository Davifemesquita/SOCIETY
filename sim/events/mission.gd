class_name Mission
extends RefCounted
## Uma encomenda do comerciante (Fase 11): oferecida, ela espera a resposta até expires_tick;
## aceita, expires_tick passa a ser o prazo da entrega. delivered conta as toneladas já entregues.

enum State { OFFERED, ACCEPTED }

var id: int = 0
var def_id: StringName
var state: State = State.OFFERED
var delivered: float = 0.0
var expires_tick: int = 0
## runtime: a definição (resolvida ao criar e ao carregar), fora do save.
var def: MissionDef


func remaining() -> float:
	return maxf(float(def.tons) - delivered, 0.0)


func ticks_left(tick: int) -> int:
	return maxi(expires_tick - tick, 0)


func to_dict() -> Dictionary:
	return {"id": id, "def": def_id, "state": state, "delivered": delivered, "expires": expires_tick}


static func from_dict(data: Dictionary, game_data: GameData) -> Mission:
	var raw_id: Variant = data.get("id")
	var raw_def: Variant = data.get("def")
	var raw_state: Variant = data.get("state")
	var raw_delivered: Variant = data.get("delivered")
	var raw_expires: Variant = data.get("expires")
	if not (raw_id is int and raw_def is StringName and raw_state is int and raw_delivered is float and raw_expires is int):
		return null
	var mission := Mission.new()
	mission.id = raw_id
	mission.def_id = raw_def
	var state_value: int = raw_state
	if state_value < State.OFFERED or state_value > State.ACCEPTED:
		return null
	mission.state = state_value as State
	mission.delivered = raw_delivered
	mission.expires_tick = raw_expires
	mission.def = game_data.mission(mission.def_id)
	if mission.def == null or mission.id <= 0 or mission.delivered < 0.0 or mission.delivered >= float(mission.def.tons):
		return null
	return mission
