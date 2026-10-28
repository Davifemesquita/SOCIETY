class_name SetPolicyCommand
extends Command
## Política da prefeitura (Fase 66): escolhe a política da prefeitura dada (vazia tira a que há). Só numa prefeitura e
## só política liberada pelos marcos. Mudar não custa nada: o custo é a manutenção por minuto da política.

const NOT_TOWN_HALL := &"REASON_NOT_TOWN_HALL"
const POLICY_LOCKED := &"REASON_POLICY_LOCKED"

var building_id: int
var policy_id: StringName


func _init(id: int, policy: StringName) -> void:
	building_id = id
	policy_id = policy


func execute(context: CommandContext) -> CommandResult:
	var record := context.world.building(building_id)
	if record == null or not context.data.building(record.def_id).is_town_hall():
		return CommandResult.refused(NOT_TOWN_HALL)
	if policy_id != &"":
		var def := context.data.policy(policy_id)
		if def == null or (def.after_milestone > context.world.milestones_reached and not context.free_build):
			return CommandResult.refused(POLICY_LOCKED)
	record.policy = policy_id
	var result := CommandResult.new()
	result.island_id = record.island_id
	result.changed.append(building_id)
	return result
