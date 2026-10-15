class_name EventsState
extends RefCounted
## Eventos e encomendas da partida (Fase 11), no save. Desligado (enabled = false) nada acontece:
## é o padrão de mundo novo da simulação (testes, ferramentas, o jogador-robô) e uma opção do jogo
## novo. Os sorteios saem da semente do mundo e de um contador, então a partida carregada segue
## igual à original.

var enabled: bool = false
var events: Array[WorldEvent] = []
## Tick do próximo evento (0 = ainda não marcado: marca na primeira conferência).
var next_event_tick: int = 0
## Eventos já começados (é o número do sorteio do próximo).
var event_count: int = 0
var missions: Array[Mission] = []
var next_mission_id: int = 1
## Tick da próxima encomenda oferecida (0 = ainda não marcado).
var next_offer_tick: int = 0
## Encomendas cumpridas no prazo (estatística e testes).
var missions_done: int = 0


func mission(mission_id: int) -> Mission:
	for item: Mission in missions:
		if item.id == mission_id:
			return item
	return null


## Encomendas aceitas de um bem, na ordem em que foram aceitas (a entrega enche a primeira antes).
func accepted_for(good: StringName) -> Array[Mission]:
	var list: Array[Mission] = []
	for item: Mission in missions:
		if item.state == Mission.State.ACCEPTED and item.def.good == good:
			list.append(item)
	return list


func to_dict() -> Dictionary:
	var event_list: Array[Dictionary] = []
	for event: WorldEvent in events:
		event_list.append(event.to_dict())
	var mission_list: Array[Dictionary] = []
	for item: Mission in missions:
		mission_list.append(item.to_dict())
	return {"enabled": enabled, "events": event_list, "next_event_tick": next_event_tick, "event_count": event_count,
			"missions": mission_list, "next_mission_id": next_mission_id, "next_offer_tick": next_offer_tick,
			"missions_done": missions_done}


static func from_dict(data: Dictionary, game_data: GameData, island_count: int) -> EventsState:
	var raw_enabled: Variant = data.get("enabled")
	var raw_events: Variant = data.get("events")
	var raw_next_event: Variant = data.get("next_event_tick")
	var raw_count: Variant = data.get("event_count")
	var raw_missions: Variant = data.get("missions")
	var raw_next_id: Variant = data.get("next_mission_id")
	var raw_next_offer: Variant = data.get("next_offer_tick")
	var raw_done: Variant = data.get("missions_done")
	if not (raw_enabled is bool and raw_events is Array and raw_next_event is int and raw_count is int and raw_missions is Array \
			and raw_next_id is int and raw_next_offer is int and raw_done is int):
		return null
	var state := EventsState.new()
	state.enabled = raw_enabled
	state.next_event_tick = raw_next_event
	state.event_count = raw_count
	state.next_mission_id = raw_next_id
	state.next_offer_tick = raw_next_offer
	state.missions_done = raw_done
	if state.event_count < 0 or state.missions_done < 0 or state.next_mission_id < 1:
		return null
	var event_list: Array = raw_events
	for raw: Variant in event_list:
		if not raw is Dictionary:
			return null
		var event_data: Dictionary = raw
		var event := WorldEvent.from_dict(event_data, game_data, island_count)
		if event == null:
			return null
		state.events.append(event)
	var mission_list: Array = raw_missions
	for raw: Variant in mission_list:
		if not raw is Dictionary:
			return null
		var mission_data: Dictionary = raw
		var item := Mission.from_dict(mission_data, game_data)
		if item == null or item.id >= state.next_mission_id or state.mission(item.id) != null:
			return null
		state.missions.append(item)
	return state
