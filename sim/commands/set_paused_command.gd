class_name SetPausedCommand
extends Command
## Pausa ou retoma um prédio de produção. Pausado, não trabalha e paga metade da manutenção.

var building_id: int
var paused: bool


func _init(target: int, pause: bool) -> void:
	building_id = target
	paused = pause


func execute(context: CommandContext) -> CommandResult:
	var record := context.world.building(building_id)
	if record == null or not context.data.building(record.def_id).is_production():
		return CommandResult.refused(&"REASON_NOT_PRODUCTION")
	record.paused = paused
	var result := CommandResult.new()
	result.island_id = record.island_id
	result.changed.append(building_id)
	return result
