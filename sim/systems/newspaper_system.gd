class_name NewspaperSystem
extends RefCounted
## Jornal da partida (Fase 63): a primeira edição sai depois de newspaper_first_after_s de jogo e as seguintes a cada
## newspaper_interval_s. Cada uma traz uma manchete sorteada entre as de notícia liberadas pelos marcos (peso de cada
## uma), que vale até a próxima edição e soma a felicidade dela ao alvo das casas de todas as ilhas (EventEffects).
## A propaganda comprada (BuyPropagandaCommand) troca a manchete da edição de agora. Só com os eventos ligados; o
## sorteio sai da semente e do número da edição, então a partida carregada segue igual.


static func run(world: WorldState, data: GameData, config: GameConfig) -> void:
	var state := world.events_state
	if not state.enabled or world.tick % config.events_check_ticks != 0:
		return
	if state.next_edition_tick == 0:
		state.next_edition_tick = world.tick + config.ticks_of(config.newspaper_first_after_s)
		return
	if world.tick < state.next_edition_tick:
		return
	state.next_edition_tick = world.tick + config.ticks_of(config.newspaper_interval_s)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.seed, &"jornal", state.edition_count])
	var chosen := _draw(world, data, rng)
	state.edition_count += 1
	state.propaganda_used = false
	state.headline = chosen
	state.headline_id = chosen.id if chosen != null else &""
	EventBus.newspaper_published.emit(state.headline_id)


## A manchete de notícia sorteada (null se nenhuma está liberada).
static func _draw(world: WorldState, data: GameData, rng: RandomNumberGenerator) -> HeadlineDef:
	var choices: Array[HeadlineDef] = []
	var total := 0
	for def: HeadlineDef in data.headlines:
		if def.propaganda or def.after_milestone > world.milestones_reached:
			continue
		choices.append(def)
		total += def.weight
	if choices.is_empty():
		return null
	var pick := rng.randi_range(1, total)
	for def: HeadlineDef in choices:
		pick -= def.weight
		if pick <= 0:
			return def
	return choices[-1]


## As manchetes de propaganda que o jogador pode comprar agora (liberadas pelos marcos).
static func propaganda_choices(world: WorldState, data: GameData) -> Array[HeadlineDef]:
	var list: Array[HeadlineDef] = []
	for def: HeadlineDef in data.headlines:
		if def.propaganda and def.after_milestone <= world.milestones_reached:
			list.append(def)
	return list
