class_name SetUpgradeBlockedCommand
extends Command
## Bloqueia ou libera o upgrade de uma casa.

var building_id: int
var blocked: bool


func _init(target: int, block: bool) -> void:
	building_id = target
	blocked = block


func execute(context: CommandContext) -> CommandResult:
	var record := context.world.building(building_id)
	if record == null or not record.is_house():
		return CommandResult.refused(&"REASON_NOT_HOUSE")
	record.upgrade_blocked = blocked
	var result := CommandResult.new()
	result.island_id = record.island_id
	result.changed.append(building_id)
	return result
