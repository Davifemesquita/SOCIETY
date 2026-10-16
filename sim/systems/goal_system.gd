class_name GoalSystem
extends RefCounted
## Metas guiadas (seção 3): uma por vez, na ordem de GameData.goals. A meta da vez é conferida a
## cada goal_check_ticks; cumprida, paga o prêmio, avisa (goal_completed) e passa a vez. Meta
## ligada a marco (after_milestone) só conta depois dele. Um save de antes das metas
## (goals_catch_up) passa de uma vez, sem prêmio, as que já estão cumpridas.


static func run(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState) -> void:
	if world.tick % config.goal_check_ticks != 0:
		return
	var catching_up := world.goals_catch_up
	world.goals_catch_up = false
	while world.goals_done < data.goals.size():
		var goal := data.goals[world.goals_done]
		if world.milestones_reached < goal.after_milestone or progress(world, data, config, derived, goal) < goal.amount:
			return
		if not catching_up:
			world.money += goal.reward_money
		world.goals_done += 1
		if not catching_up:
			EventBus.goal_completed.emit(world.goals_done - 1)


## A meta da vez, ou null quando todas já foram cumpridas (a partida segue livre).
static func current(world: WorldState, data: GameData) -> GoalDef:
	return data.goals[world.goals_done] if world.goals_done < data.goals.size() else null


## Quanto da meta já está feito, na unidade de amount.
static func progress(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState, goal: GoalDef) -> int:
	match goal.kind:
		GoalDef.Kind.BUILDING_COUNT:
			var count := 0
			for record: BuildingRecord in world.buildings.values():
				if record.def_id == goal.target:
					count += 1
			return count
		GoalDef.Kind.TIER_POPULATION:
			return world.population(goal.target)
		GoalDef.Kind.NEED_SUPPLIED:
			var supplied := 0.0
			for island_id: int in world.islands.size():
				if world.economy(island_id).supply_of(goal.target, goal.need) >= config.need_met_threshold:
					supplied += derived.residents_by_tier(island_id).get(goal.target, 0.0)
			return floori(supplied)
		GoalDef.Kind.TOTAL_POPULATION:
			var total := 0.0
			for island_id: int in world.islands.size():
				for count: float in derived.residents_by_tier(island_id).values():
					total += count
			return floori(total)
		GoalDef.Kind.PAVED_CELLS:
			var paved := 0
			for grid: IslandGrid in world.islands:
				paved += grid.roads.count(IslandGrid.Road.PAVED)
			return paved
		GoalDef.Kind.COLONIZED_ISLANDS:
			return world.colonized_islands(data).size()
		GoalDef.Kind.MONEY:
			return maxi(floori(world.money), 0)
	return 0
