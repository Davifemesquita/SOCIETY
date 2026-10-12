class_name UpgradeBuildingCommand
extends Command
## Sobe o nível de um armazém ou entreposto (mais rampas; no entreposto, mais estoque por bem).

var building_id: int


func _init(target: int) -> void:
	building_id = target


func execute(context: CommandContext) -> CommandResult:
	var world := context.world
	var record := world.building(building_id)
	if record == null or context.data.building(record.def_id).levels.is_empty():
		return CommandResult.refused(&"REASON_NOT_UPGRADABLE")
	var def := context.data.building(record.def_id)
	if record.level + 1 >= def.levels.size():
		return CommandResult.refused(&"REASON_MAX_LEVEL")
	var next := def.levels[record.level + 1]
	var economy := world.economy(record.island_id)
	if not context.free_build:
		var reason := PlacementRules.check_cost(world, economy, context.config, next.cost_money, next.cost_materials)
		if reason != PlacementRules.OK:
			return CommandResult.refused(reason)
		world.money -= next.cost_money
		for material: StringName in next.cost_materials:
			economy.take(material, next.cost_materials[material])
	record.level += 1
	var result := CommandResult.new()
	result.island_id = record.island_id
	result.changed.append(building_id)
	return result
