class_name WorldEvent
extends RefCounted
## Um evento em andamento (Fase 11): qual, onde (ilha, ou -1 no arquipélago todo), o bem (na
## feira) e até que tick vale.

var def_id: StringName
var island_id: int = -1
var good: StringName
var started_tick: int = 0
var ends_tick: int = 0
## runtime: a definição (resolvida ao criar e ao carregar), fora do save.
var def: EventDef


func ticks_left(tick: int) -> int:
	return maxi(ends_tick - tick, 0)


func to_dict() -> Dictionary:
	return {"def": def_id, "island": island_id, "good": good, "started": started_tick, "ends": ends_tick}


static func from_dict(data: Dictionary, game_data: GameData, island_count: int) -> WorldEvent:
	var raw_def: Variant = data.get("def")
	var raw_island: Variant = data.get("island")
	var raw_good: Variant = data.get("good")
	var raw_started: Variant = data.get("started")
	var raw_ends: Variant = data.get("ends")
	if not (raw_def is StringName and raw_island is int and raw_good is StringName and raw_started is int and raw_ends is int):
		return null
	var event := WorldEvent.new()
	event.def_id = raw_def
	event.island_id = raw_island
	event.good = raw_good
	event.started_tick = raw_started
	event.ends_tick = raw_ends
	event.def = game_data.event(event.def_id)
	if event.def == null or event.ends_tick < event.started_tick:
		return null
	if event.def.is_local() != (event.island_id >= 0) or event.island_id >= island_count:
		return null
	if event.def.effect == EventDef.Effect.TRADER_PRICE and game_data.good(event.good) == null:
		return null
	return event
