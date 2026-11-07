class_name EventEffects
extends RefCounted
## O que os eventos em andamento mudam (Fase 11), lido pelos sistemas a cada tick. Com poucos
## eventos ao mesmo tempo, percorrer a lista é mais barato que manter índices. Sem evento, tudo
## vale 1 (ou 0 de felicidade).


## Multiplicador da velocidade de produção do prédio.
static func production(state: EventsState, island_id: int, def: BuildingDef) -> float:
	var factor := 1.0
	for event: WorldEvent in state.events:
		if event.def.effect == EventDef.Effect.PRODUCTION and event.island_id == island_id and event.def.covers(def):
			factor *= event.def.amount
	return factor


## Multiplicador do preço do comerciante para o bem.
static func price(state: EventsState, good: StringName) -> float:
	var factor := 1.0
	for event: WorldEvent in state.events:
		if event.def.effect == EventDef.Effect.TRADER_PRICE and event.good == good:
			factor *= event.def.amount
	return factor


## Multiplicador da velocidade dos navios.
static func ship_speed(state: EventsState) -> float:
	var factor := 1.0
	for event: WorldEvent in state.events:
		if event.def.effect == EventDef.Effect.SHIP_SPEED:
			factor *= event.def.amount
	return factor


## Pontos de felicidade somados ao alvo das casas da ilha (com a manchete do jornal, Fase 63, que vale em todas).
static func happiness(state: EventsState, island_id: int) -> float:
	var points := state.headline.happiness if state.headline != null else 0.0
	for event: WorldEvent in state.events:
		if event.def.effect == EventDef.Effect.HAPPINESS and event.island_id == island_id:
			points += event.def.amount
	return points


## Multiplicador da chegada de moradores na ilha.
static func arrival(state: EventsState, island_id: int) -> float:
	var factor := 1.0
	for event: WorldEvent in state.events:
		if event.def.effect == EventDef.Effect.ARRIVAL and event.island_id == island_id:
			factor *= event.def.amount
	return factor
