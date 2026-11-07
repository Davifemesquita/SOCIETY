class_name BuyPropagandaCommand
extends Command
## Propaganda no jornal (Fase 63): paga newspaper_propaganda_cost moedas e troca a manchete da edição de agora pela de
## propaganda escolhida, até a próxima edição. Uma vez por edição, só depois da primeira, só manchete de propaganda
## liberada pelos marcos.

const NO_EDITION := &"REASON_NO_EDITION"
const ALREADY_USED := &"REASON_PROPAGANDA_USED"
const NOT_PROPAGANDA := &"REASON_NOT_PROPAGANDA"

var headline_id: StringName


func _init(id: StringName) -> void:
	headline_id = id


func execute(context: CommandContext) -> CommandResult:
	var world := context.world
	var state := world.events_state
	if not state.enabled or state.edition_count == 0:
		return CommandResult.refused(NO_EDITION)
	if state.propaganda_used:
		return CommandResult.refused(ALREADY_USED)
	var def := context.data.headline(headline_id)
	if def == null or not def.propaganda or def.after_milestone > world.milestones_reached:
		return CommandResult.refused(NOT_PROPAGANDA)
	var cost := context.config.newspaper_propaganda_cost
	if world.money < cost:
		return CommandResult.refused(PlacementRules.NO_MONEY)
	world.money -= cost
	state.headline = def
	state.headline_id = def.id
	state.propaganda_used = true
	var result := CommandResult.new()
	result.newspaper_changed = true
	return result
