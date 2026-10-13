class_name TraderState
extends RefCounted
## Estado do comerciante neutro: o navio dele, a volta pelos entrepostos e a espera no posto.
## Os preços saem da volta (sorteados pela semente do mundo): o save guarda só o número dela.

var ship_id: int = 0
## Voltas começadas; cada volta sorteia preços novos.
var tour: int = 0
## Segundos de jogo que faltam para a próxima volta (com o navio no posto).
var wait_left: float = 0.0
## Ilhas da volta atual e a próxima delas.
var visits: Array[int] = []
var next_visit: int = 0


## Preço de um bem nesta volta: o base com variação de até ±variation, igual para comprar e
## vender.
static func price(world_seed: int, tour_index: int, good: GoodDef, variation: float) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world_seed, tour_index, good.id])
	return good.base_price * (1.0 + variation * rng.randf_range(-1.0, 1.0))


func to_dict() -> Dictionary:
	return {"ship": ship_id, "tour": tour, "wait_left": wait_left, "visits": visits.duplicate(), "next_visit": next_visit}


static func from_dict(data: Dictionary, island_count: int) -> TraderState:
	var raw_ship: Variant = data.get("ship")
	var raw_tour: Variant = data.get("tour")
	var raw_wait: Variant = data.get("wait_left")
	var raw_visits: Variant = data.get("visits")
	var raw_next: Variant = data.get("next_visit")
	if not (raw_ship is int and raw_tour is int and raw_wait is float and raw_visits is Array and raw_next is int):
		return null
	var state := TraderState.new()
	state.ship_id = raw_ship
	state.tour = raw_tour
	state.wait_left = raw_wait
	state.next_visit = raw_next
	var visit_list: Array = raw_visits
	for raw_island: Variant in visit_list:
		if not raw_island is int:
			return null
		var island: int = raw_island
		if island < 0 or island >= island_count:
			return null
		state.visits.append(island)
	if state.next_visit < 0 or state.next_visit > state.visits.size():
		return null
	return state
