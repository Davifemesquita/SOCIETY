class_name SetTaxLevelCommand
extends Command
## Muda o nível de imposto de uma classe (baixo, normal, alto).

var tier: StringName
var level: int


func _init(tier_id: StringName, tax_level: int) -> void:
	tier = tier_id
	level = tax_level


func execute(context: CommandContext) -> CommandResult:
	if context.data.tier(tier) == null or level < WorldState.TaxLevel.LOW or level > WorldState.TaxLevel.HIGH:
		return CommandResult.refused(&"REASON_INVALID_TAX_LEVEL")
	context.world.tax_levels[tier] = level
	return CommandResult.new()
