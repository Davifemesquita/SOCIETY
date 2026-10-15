class_name RivalState
extends RefCounted
## Uma companhia rival na partida (Fase 11): as ilhas dela com os moradores de cada uma, a relação
## com o jogador, a postura (neutra, acordo comercial ou guerra), o navio dela e quando sai a
## próxima colônia.

enum Stance { NEUTRAL, TRADE, WAR }

var def_id: StringName
## Ilha → moradores (float, cresce aos poucos).
var islands: Dictionary[int, float] = {}
var relation: float = 0.0
var stance: Stance = Stance.NEUTRAL
## Navio mercante dela (0 = ainda nenhum).
var ship_id: int = 0
## Tick da próxima colônia (0 = ainda não marcada).
var next_colony_tick: int = 0
## Último presente aceito (o próximo só depois de rival_gift_cooldown_s).
var last_gift_tick: int = -1_000_000
## Última vez que a postura mudou (guerra e paz não se alternam a cada segundo).
var stance_tick: int = 0
## runtime: a definição, fora do save.
var def: RivalDef


func population() -> float:
	var total := 0.0
	for count: float in islands.values():
		total += count
	return total


## Ilhas em ordem de índice (para varrer sempre igual).
func island_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(islands.keys())
	ids.sort()
	return ids


func to_dict() -> Dictionary:
	var island_list: Array[Dictionary] = []
	for island_id: int in island_ids():
		island_list.append({"island": island_id, "population": islands[island_id]})
	return {"def": def_id, "islands": island_list, "relation": relation, "stance": stance, "ship": ship_id,
			"next_colony_tick": next_colony_tick, "last_gift_tick": last_gift_tick, "stance_tick": stance_tick}


static func from_dict(data: Dictionary, game_data: GameData, island_count: int) -> RivalState:
	var raw_def: Variant = data.get("def")
	var raw_islands: Variant = data.get("islands")
	var raw_relation: Variant = data.get("relation")
	var raw_stance: Variant = data.get("stance")
	var raw_ship: Variant = data.get("ship")
	var raw_next: Variant = data.get("next_colony_tick")
	var raw_gift: Variant = data.get("last_gift_tick")
	var raw_stance_tick: Variant = data.get("stance_tick")
	if not (raw_def is StringName and raw_islands is Array and raw_relation is float and raw_stance is int and raw_ship is int \
			and raw_next is int and raw_gift is int and raw_stance_tick is int):
		return null
	var state := RivalState.new()
	state.def_id = raw_def
	state.def = game_data.rival(state.def_id)
	state.relation = raw_relation
	var stance_value: int = raw_stance
	if state.def == null or stance_value < Stance.NEUTRAL or stance_value > Stance.WAR or absf(state.relation) > 100.0001:
		return null
	state.stance = stance_value as Stance
	state.ship_id = raw_ship
	state.next_colony_tick = raw_next
	state.last_gift_tick = raw_gift
	state.stance_tick = raw_stance_tick
	var island_list: Array = raw_islands
	for raw: Variant in island_list:
		if not raw is Dictionary:
			return null
		var entry: Dictionary = raw
		var raw_island: Variant = entry.get("island")
		var raw_population: Variant = entry.get("population")
		if not (raw_island is int and raw_population is float):
			return null
		var island_id: int = raw_island
		var count: float = raw_population
		if island_id <= 0 or island_id >= island_count or state.islands.has(island_id) or count < 0.0:
			return null
		state.islands[island_id] = count
	return state
