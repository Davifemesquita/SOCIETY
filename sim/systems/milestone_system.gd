class_name MilestoneSystem
extends RefCounted
## Marcos de população (seção 3): ao passar de cada patamar de population_milestones (soma de
## todas as classes em todas as ilhas), o marco fica atingido para sempre e libera navios e
## ilhas (ships_by_milestone, islands_by_milestone). Avisa uma vez por marco.


static func run(world: WorldState, config: GameConfig, derived: DerivedState) -> void:
	var milestones := config.population_milestones
	if world.milestones_reached >= milestones.size():
		return
	var total := 0.0
	for island_id: int in world.islands.size():
		for count: float in derived.residents_by_tier(island_id).values():
			total += count
	while world.milestones_reached < milestones.size() and total >= milestones[world.milestones_reached]:
		world.milestones_reached += 1
		EventBus.milestone_reached.emit(world.milestones_reached)


## Navios do jogador permitidos agora.
static func ship_limit(world: WorldState, config: GameConfig) -> int:
	return config.ships_by_milestone[clampi(world.milestones_reached, 0, config.ships_by_milestone.size() - 1)]


## Ilhas com entreposto permitidas agora.
static func island_limit(world: WorldState, config: GameConfig) -> int:
	return config.islands_by_milestone[clampi(world.milestones_reached, 0, config.islands_by_milestone.size() - 1)]
