class_name MissionSystem
extends RefCounted
## Encomendas do comerciante (Fase 11). A cada events_check_ticks: tira as ofertas não respondidas
## e as aceitas que passaram do prazo (sem multa) e, chegada a hora e havendo entreposto, oferece
## uma nova, sorteada entre as liberadas pelos marcos e de bem que nenhuma aberta já pede. A
## entrega é a venda do bem no posto do comerciante (CargoTransfer chama deliver e depois settle,
## que paga o prêmio das cumpridas).


static func run(world: WorldState, data: GameData, config: GameConfig) -> void:
	var state := world.events_state
	if not state.enabled or world.tick % config.events_check_ticks != 0:
		return
	for index: int in range(state.missions.size() - 1, -1, -1):
		var item := state.missions[index]
		if world.tick >= item.expires_tick:
			state.missions.remove_at(index)
			EventBus.mission_expired.emit(item.def_id, item.state == Mission.State.ACCEPTED)
	if not world.any_trading_post(data):
		return
	if state.next_offer_tick == 0:
		state.next_offer_tick = world.tick + config.ticks_of(config.mission_first_after_s)
		return
	if world.tick < state.next_offer_tick:
		return
	state.next_offer_tick = world.tick + config.ticks_of(config.mission_interval_s)
	if state.missions.size() >= config.max_open_missions:
		return
	var def := _draw(world, data, state)
	if def == null:
		return
	var item := Mission.new()
	item.id = state.next_mission_id
	state.next_mission_id += 1
	item.def = def
	item.def_id = def.id
	item.expires_tick = world.tick + config.ticks_of(config.mission_offer_s)
	state.missions.append(item)
	EventBus.mission_offered.emit(item.id)


static func _draw(world: WorldState, data: GameData, state: EventsState) -> MissionDef:
	var asked: Dictionary[StringName, bool] = {}
	for item: Mission in state.missions:
		asked[item.def.good] = true
	var choices: Array[MissionDef] = []
	var total := 0
	for def: MissionDef in data.missions:
		if def.after_milestone <= world.milestones_reached and not asked.has(def.good):
			choices.append(def)
			total += def.weight
	if choices.is_empty():
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.seed, &"mission", state.next_mission_id])
	var pick := rng.randi_range(1, total)
	for def: MissionDef in choices:
		pick -= def.weight
		if pick <= 0:
			return def
	return choices[0]


## Toneladas do bem que as encomendas aceitas ainda esperam.
static func room_for(world: WorldState, good: StringName) -> float:
	var room := 0.0
	for item: Mission in world.events_state.accepted_for(good):
		room += item.remaining()
	return room


## Entrega tons do bem às encomendas aceitas (a mais antiga primeiro); devolve o que coube.
static func deliver(world: WorldState, good: StringName, tons: float) -> float:
	var left := tons
	for item: Mission in world.events_state.accepted_for(good):
		var part := minf(left, item.remaining())
		item.delivered += part
		left -= part
		if left <= 0.000001:
			break
	return tons - maxf(left, 0.0)


## Paga e tira as encomendas cumpridas; devolve o prêmio somado.
static func settle(world: WorldState, data: GameData) -> int:
	var state := world.events_state
	var paid := 0
	for index: int in range(state.missions.size() - 1, -1, -1):
		var item := state.missions[index]
		if item.state == Mission.State.ACCEPTED and item.remaining() <= 0.000001:
			var bonus := item.def.bonus(data)
			world.money += bonus
			paid += bonus
			state.missions_done += 1
			state.missions.remove_at(index)
			EventBus.mission_completed.emit(item.def_id, bonus)
	return paid
