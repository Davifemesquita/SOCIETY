class_name RemovePlansCommand
extends Command
## Apaga as plantas que encostam na área (Fase 49).

var island_id: int
var area: Rect2i


func _init(island: int, region: Rect2i) -> void:
	island_id = island
	area = region


func execute(context: CommandContext) -> CommandResult:
	var world := context.world
	var gone: Array[int] = []
	for plan: PlanRecord in world.plans.values():
		if plan.island_id == island_id and plan.rect(context.data).intersects(area):
			gone.append(plan.id)
	if gone.is_empty():
		return CommandResult.refused(&"REASON_NO_PLAN_HERE")
	for plan_id: int in gone:
		world.plans.erase(plan_id)
	var result := CommandResult.new()
	result.island_id = island_id
	result.plans_changed = true
	return result
