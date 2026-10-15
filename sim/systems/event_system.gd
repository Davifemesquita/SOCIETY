class_name EventSystem
extends RefCounted
## Eventos da partida (Fase 11): a cada events_check_ticks, encerra os que venceram e, chegada a
## hora, começa um novo, sorteado entre os liberados pelos marcos (peso de cada um), sem repetir um
## que já está em andamento. O de ilha cai numa das colonizadas; a feira, num bem que o
## comerciante compra. Tudo pela semente e pelo número do evento: a partida carregada segue igual.


static func run(world: WorldState, data: GameData, config: GameConfig) -> void:
	var state := world.events_state
	if not state.enabled or world.tick % config.events_check_ticks != 0:
		return
	for index: int in range(state.events.size() - 1, -1, -1):
		var event := state.events[index]
		if world.tick >= event.ends_tick:
			state.events.remove_at(index)
			EventBus.world_event_ended.emit(event.def_id, event.island_id)
	if state.next_event_tick == 0:
		state.next_event_tick = world.tick + config.ticks_of(config.event_first_after_s)
		return
	if world.tick < state.next_event_tick:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.seed, &"event", state.event_count])
	state.next_event_tick = world.tick + config.ticks_of(config.event_interval_s + config.event_jitter_s * rng.randf_range(-1.0, 1.0))
	if state.events.size() >= config.max_active_events:
		return
	var event := _draw(world, data, config, rng)
	state.event_count += 1
	if event == null:
		return
	state.events.append(event)
	EventBus.world_event_started.emit(event.def_id, event.island_id)


## Sorteia o evento (null se nenhum serve agora: sem ilha colonizada, tudo em andamento).
static func _draw(world: WorldState, data: GameData, config: GameConfig, rng: RandomNumberGenerator) -> WorldEvent:
	var islands := world.colonized_islands(data)
	var active: Dictionary[StringName, bool] = {}
	for event: WorldEvent in world.events_state.events:
		active[event.def_id] = true
	var choices: Array[EventDef] = []
	var total := 0
	for def: EventDef in data.events:
		if def.after_milestone > world.milestones_reached or active.has(def.id) or (def.is_local() and islands.is_empty()):
			continue
		if def.effect == EventDef.Effect.TRADER_PRICE and data.trader() == null:
			continue
		choices.append(def)
		total += def.weight
	if choices.is_empty():
		return null
	var pick := rng.randi_range(1, total)
	var chosen := choices[0]
	for def: EventDef in choices:
		pick -= def.weight
		if pick <= 0:
			chosen = def
			break
	var event := WorldEvent.new()
	event.def = chosen
	event.def_id = chosen.id
	event.started_tick = world.tick
	event.ends_tick = world.tick + config.ticks_of(chosen.duration_s)
	if chosen.is_local():
		event.island_id = islands[rng.randi_range(0, islands.size() - 1)]
	if chosen.effect == EventDef.Effect.TRADER_PRICE:
		var goods := data.trader().buys
		event.good = goods[rng.randi_range(0, goods.size() - 1)]
	return event
