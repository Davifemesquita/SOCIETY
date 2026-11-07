class_name TourismSystem
extends RefCounted
## Turismo (Fase 68): os turistas visitam as ilhas atraentes e pagam por minuto a atratividade da ilha (DerivedState:
## beleza menos poluição) vezes tourism_coins_per_point, mais tourism_festival_bonus com a festa na ilha. Só com os
## eventos ligados (como o jornal): o mundo novo da simulação, os testes e o robô não têm turismo. A renda entra no
## dinheiro e na receita por minuto (como os acordos com as rivais) e fica em tourism_per_min para a barra e o
## detalhamento.


static func run(world: WorldState, config: GameConfig, derived: DerivedState, dt: float) -> void:
	world.tourism_per_min = 0.0
	if not world.events_state.enabled or derived.attractiveness.is_empty():
		return
	for island_id: int in derived.attractiveness:
		world.tourism_per_min += island_income(world, config, derived, island_id)
	world.money += world.tourism_per_min * dt / 60.0
	world.income_per_min += world.tourism_per_min


## Os turistas de uma ilha, em moedas por minuto (com a festa, se houver).
static func island_income(world: WorldState, config: GameConfig, derived: DerivedState, island_id: int) -> float:
	var income: float = derived.attractiveness.get(island_id, 0.0) * config.tourism_coins_per_point
	return income * (1.0 + config.tourism_festival_bonus) if has_festival(world, island_id) else income


## A festa está acontecendo na ilha (também usado pelos turistas na rua, Fase 81).
static func has_festival(world: WorldState, island_id: int) -> bool:
	for event: WorldEvent in world.events_state.events:
		if event.def_id == &"festival" and event.island_id == island_id:
			return true
	return false
