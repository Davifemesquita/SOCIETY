class_name AnswerMissionCommand
extends Command
## Resposta a uma encomenda oferecida (Fase 11): aceitar começa a contar o prazo; recusar tira a
## oferta. Encomenda já aceita não se responde de novo.

const NO_MISSION := &"REASON_NO_MISSION"

var mission_id: int
var accept: bool


func _init(id: int, accepting: bool) -> void:
	mission_id = id
	accept = accepting


func execute(context: CommandContext) -> CommandResult:
	var state := context.world.events_state
	var item := state.mission(mission_id)
	if item == null or item.state != Mission.State.OFFERED:
		return CommandResult.refused(NO_MISSION)
	if accept:
		item.state = Mission.State.ACCEPTED
		item.expires_tick = context.world.tick + context.config.ticks_of(item.def.duration_s)
	else:
		state.missions.erase(item)
	var result := CommandResult.new()
	result.missions_changed = true
	return result
