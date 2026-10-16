class_name VictoryState
extends RefCounted
## Objetivo da partida (Fase 12), no save. Sem objetivo (kind = -1) a partida é livre e nunca acaba.
## Com objetivo, o VictorySystem confere a conta (a das metas guiadas) e o prazo; a partida vencida
## ou perdida segue livre (o jogador pode continuar), só não confere mais.

enum Outcome { PLAYING, WON, LOST }

## GoalDef.Kind do objetivo, ou -1 (partida livre).
var kind: int = -1
var target: StringName
var amount: int = 0
## Tick do fim do prazo (0 = sem prazo).
var deadline_tick: int = 0
## Cenário de onde a partida veio (vazio = jogo novo comum).
var scenario_id: StringName
var outcome: Outcome = Outcome.PLAYING
var ended_tick: int = 0


func has_goal() -> bool:
	return kind >= 0


## O objetivo como meta (para a conta e o texto), ou null na partida livre.
func as_goal() -> GoalDef:
	if not has_goal():
		return null
	var goal := GoalDef.new()
	goal.id = &"victory"
	goal.kind = kind as GoalDef.Kind
	goal.target = target
	goal.amount = amount
	return goal


func to_dict() -> Dictionary:
	return {"kind": kind, "target": target, "amount": amount, "deadline_tick": deadline_tick, "scenario": scenario_id,
			"outcome": outcome, "ended_tick": ended_tick}


static func from_dict(data: Dictionary, game_data: GameData) -> VictoryState:
	var raw_kind: Variant = data.get("kind")
	var raw_target: Variant = data.get("target")
	var raw_amount: Variant = data.get("amount")
	var raw_deadline: Variant = data.get("deadline_tick")
	var raw_scenario: Variant = data.get("scenario")
	var raw_outcome: Variant = data.get("outcome")
	var raw_ended: Variant = data.get("ended_tick")
	if not (raw_kind is int and raw_target is StringName and raw_amount is int and raw_deadline is int and raw_scenario is StringName \
			and raw_outcome is int and raw_ended is int):
		return null
	var state := VictoryState.new()
	state.kind = raw_kind
	state.target = raw_target
	state.amount = raw_amount
	state.deadline_tick = raw_deadline
	state.scenario_id = raw_scenario
	var outcome_value: int = raw_outcome
	state.ended_tick = raw_ended
	if state.kind < -1 or state.kind >= GoalDef.Kind.size() or outcome_value < Outcome.PLAYING or outcome_value > Outcome.LOST:
		return null
	state.outcome = outcome_value as Outcome
	if state.has_goal() and (state.amount <= 0 or (state.kind == GoalDef.Kind.TIER_POPULATION and game_data.tier(state.target) == null)):
		return null
	if state.deadline_tick < 0 or (state.scenario_id != &"" and game_data.scenario(state.scenario_id) == null):
		return null
	return state
