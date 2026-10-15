class_name DiplomacyCommand
extends Command
## Gesto do jogador com uma rival (Fase 11): presente (custa moedas, melhora a relação, um por
## rival_gift_cooldown_s), propor acordo comercial (aceito com relação de rival_trade_relation para
## cima, fora de guerra), desfazer o acordo, declarar guerra e propor paz (aceita com relação de
## rival_peace_relation para cima, pagando rival_peace_money). A recusa diz o motivo.

enum Action { GIFT, PROPOSE_TRADE, CANCEL_TRADE, DECLARE_WAR, PROPOSE_PEACE }

const NO_RIVAL := &"REASON_NO_RIVAL"
const REFUSES := &"REASON_RIVAL_REFUSES"
const TOO_SOON := &"REASON_RIVAL_TOO_SOON"
const WRONG_STANCE := &"REASON_RIVAL_WRONG_STANCE"

var rival_id: StringName
var action: Action


func _init(rival: StringName, what: Action) -> void:
	rival_id = rival
	action = what


func execute(context: CommandContext) -> CommandResult:
	var world := context.world
	var config := context.config
	var rival := world.rivals_state.by_id(rival_id) if world.rivals_state.enabled else null
	if rival == null:
		return CommandResult.refused(NO_RIVAL)
	var reason := check(world, config, rival, action)
	if reason != &"":
		return CommandResult.refused(reason)
	match action:
		Action.GIFT:
			world.money -= config.rival_gift_money
			rival.relation = minf(rival.relation + config.rival_gift_relation, 100.0)
			rival.last_gift_tick = world.tick
		Action.PROPOSE_TRADE:
			RivalSystem.set_stance(world, rival, RivalState.Stance.TRADE)
		Action.CANCEL_TRADE:
			rival.relation = maxf(rival.relation - config.rival_cancel_penalty, -100.0)
			RivalSystem.set_stance(world, rival, RivalState.Stance.NEUTRAL)
		Action.DECLARE_WAR:
			rival.relation = maxf(rival.relation - config.rival_war_penalty, -100.0)
			RivalSystem.set_stance(world, rival, RivalState.Stance.WAR)
		Action.PROPOSE_PEACE:
			world.money -= config.rival_peace_money
			RivalSystem.set_stance(world, rival, RivalState.Stance.NEUTRAL)
	var result := CommandResult.new()
	result.rivals_changed = true
	return result


## Motivo da recusa do gesto agora, ou &"" (a janela usa para desligar o botão).
static func check(world: WorldState, config: GameConfig, rival: RivalState, what: Action) -> StringName:
	match what:
		Action.GIFT:
			if world.tick - rival.last_gift_tick < config.ticks_of(config.rival_gift_cooldown_s):
				return TOO_SOON
			if world.money - config.rival_gift_money < config.min_balance_for(world.difficulty):
				return PlacementRules.NO_MONEY
		Action.PROPOSE_TRADE:
			if rival.stance != RivalState.Stance.NEUTRAL:
				return WRONG_STANCE
			if rival.relation < config.rival_trade_relation:
				return REFUSES
		Action.CANCEL_TRADE:
			if rival.stance != RivalState.Stance.TRADE:
				return WRONG_STANCE
		Action.DECLARE_WAR:
			if rival.stance == RivalState.Stance.WAR:
				return WRONG_STANCE
		Action.PROPOSE_PEACE:
			if rival.stance != RivalState.Stance.WAR:
				return WRONG_STANCE
			if world.tick - rival.stance_tick < config.ticks_of(config.rival_stance_cooldown_s):
				return TOO_SOON
			if rival.relation < config.rival_peace_relation:
				return REFUSES
			if world.money - config.rival_peace_money < config.min_balance_for(world.difficulty):
				return PlacementRules.NO_MONEY
	return &""
