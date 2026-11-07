class_name ExpeditionSystem
extends RefCounted
## Volta das expedições (Fase 69): a cada events_check_ticks, a que chegou ao fim é sorteada pela semente e pelo número
## dela — naufrágio (o navio se perde), mãos vazias ou a recompensa (uma peça do tipo do destino ainda não comprada,
## guardada para o zoológico ou o museu; sem nenhuma, o dobro do custo em moedas; ou as moedas do destino). O navio que
## volta para no porto de onde saiu. Devolve os ids dos navios que voltaram (a simulação os põe no mapa).

enum Outcome { REWARD, EMPTY, LOST }


static func run(world: WorldState, data: GameData, config: GameConfig) -> Array[int]:
	var back: Array[int] = []
	var state := world.expeditions_state
	if state.trips.is_empty() or world.tick % config.events_check_ticks != 0:
		return back
	for index: int in range(state.trips.size() - 1, -1, -1):
		var trip := state.trips[index]
		if world.tick < trip.ends_tick:
			continue
		state.trips.remove_at(index)
		var result := resolve(world, data, trip)
		var outcome: Outcome = result[0]
		var reward: StringName = result[1]
		if outcome != Outcome.LOST:
			var ship := trip.ship
			ship.stop()
			ship.at = trip.home
			ship.position = Vector2(NAN, NAN)
			world.ships[ship.id] = ship
			back.append(ship.id)
		EventBus.expedition_returned.emit(trip.def_id, outcome, reward)
	return back


## O sorteio da volta e o que ele dá: [Outcome, a peça ganha (vazia se não foi peça)]. Já paga a recompensa.
static func resolve(world: WorldState, data: GameData, trip: ExpeditionsState.Trip) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.seed, &"expedicao", trip.number])
	var roll := rng.randf()
	var def := trip.def
	if roll < def.lost_chance:
		return [Outcome.LOST, &""]
	if roll < def.lost_chance + def.empty_chance:
		return [Outcome.EMPTY, &""]
	if def.reward == ExpeditionDef.Reward.MONEY:
		world.money += def.reward_money
		return [Outcome.REWARD, &""]
	var choices: Array[ExhibitDef] = []
	for exhibit: ExhibitDef in data.exhibits:
		if exhibit.kind == def.exhibit_kind() and not world.exhibits_state.owns(exhibit.id):
			choices.append(exhibit)
	if choices.is_empty():
		world.money += def.cost_money * 2
		return [Outcome.REWARD, &""]
	var found := choices[rng.randi_range(0, choices.size() - 1)]
	world.exhibits_state.placed[found.id] = 0
	return [Outcome.REWARD, found.id]
