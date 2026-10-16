class_name VictorySystem
extends RefCounted
## Objetivo da partida (Fase 12), a cada goal_check_ticks: cumprido, a partida está vencida
## (match_won); passado o prazo sem cumprir, perdida (match_lost). Depois disso não confere mais.


static func run(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState) -> void:
	var state := world.victory_state
	if not state.has_goal() or state.outcome != VictoryState.Outcome.PLAYING or world.tick % config.goal_check_ticks != 0:
		return
	if progress(world, data, config, derived) >= state.amount:
		state.outcome = VictoryState.Outcome.WON
		state.ended_tick = world.tick
		EventBus.match_won.emit()
	elif state.deadline_tick > 0 and world.tick >= state.deadline_tick:
		state.outcome = VictoryState.Outcome.LOST
		state.ended_tick = world.tick
		EventBus.match_lost.emit()


static func progress(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState) -> int:
	var goal := world.victory_state.as_goal()
	return GoalSystem.progress(world, data, config, derived, goal) if goal != null else 0


## Põe o objetivo numa partida nova: o do cenário, ou o escolhido no jogo novo.
static func start(world: WorldState, config: GameConfig, kind: int, target: StringName, amount: int, time_limit_min: float,
		scenario_id: StringName = &"") -> void:
	var state := VictoryState.new()
	state.kind = kind
	state.target = target
	state.amount = amount
	state.scenario_id = scenario_id
	if time_limit_min > 0.0:
		state.deadline_tick = world.tick + config.ticks_of(time_limit_min * 60.0)
	world.victory_state = state
