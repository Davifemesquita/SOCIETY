class_name ObjectiveText
extends RefCounted
## Texto do objetivo da partida (Fase 12): "Chegar a 300 artesãos", "Juntar 250.000 moedas", com o
## prazo e o progresso quando pedidos. Já traduzido.


static func describe(kind: int, target: StringName, amount: int, data: GameData) -> String:
	match kind:
		GoalDef.Kind.TIER_POPULATION:
			var tier := data.tier(target)
			return TranslationServer.translate("OBJECTIVE_TIER_POPULATION") % [Fmt.integer(amount),
					TranslationServer.translate(tier.name_key).to_lower() if tier != null else ""]
		GoalDef.Kind.MONEY:
			return TranslationServer.translate("OBJECTIVE_MONEY") % Fmt.integer(amount)
		GoalDef.Kind.COLONIZED_ISLANDS:
			return TranslationServer.translate("OBJECTIVE_COLONIZED_ISLANDS") % Fmt.integer(amount)
		GoalDef.Kind.TOTAL_POPULATION:
			return TranslationServer.translate("OBJECTIVE_TOTAL_POPULATION") % Fmt.integer(amount)
	return TranslationServer.translate("OBJECTIVE_FREE")


static func deadline(minutes: float) -> String:
	if minutes <= 0.0:
		return TranslationServer.translate("OBJECTIVE_NO_DEADLINE")
	return TranslationServer.translate("OBJECTIVE_DEADLINE") % Fmt.countdown(minutes * 60.0)


## A linha da partida em andamento: objetivo, progresso e o tempo que falta.
static func progress_line(simulation: Simulation) -> String:
	var state := simulation.world.victory_state
	if not state.has_goal():
		return ""
	var text := describe(state.kind, state.target, state.amount, simulation.data)
	var done := VictorySystem.progress(simulation.world, simulation.data, simulation.config, simulation.derived_state())
	text += "  ·  " + TranslationServer.translate("OBJECTIVE_PROGRESS") % [Fmt.integer(mini(done, state.amount)), Fmt.integer(state.amount)]
	if state.deadline_tick > 0 and state.outcome == VictoryState.Outcome.PLAYING:
		var left := float(state.deadline_tick - simulation.world.tick) / simulation.config.ticks_per_second
		text += "  ·  " + TranslationServer.translate("OBJECTIVE_TIME_LEFT") % Fmt.countdown(maxf(left, 0.0))
	return text
