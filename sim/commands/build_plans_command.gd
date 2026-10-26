class_name BuildPlansCommand
extends Command
## Constrói as plantas da ilha (Fase 49), em ordem de id, cada uma pelo PlaceBuildingCommand de sempre (lugar, terreno,
## desbloqueio, custo). A que der certo vira prédio e sai da lista; a que não der fica (sem dinheiro, coberta por um
## prédio feito depois). Recusado só se nenhuma der certo, com o motivo da primeira.

var island_id: int
## Só estas plantas (vazio: todas da ilha).
var plan_ids: Array[int]


func _init(island: int, only: Array[int] = []) -> void:
	island_id = island
	plan_ids = only


func execute(context: CommandContext) -> CommandResult:
	var world := context.world
	var chosen: Array[int] = []
	for plan_id: int in world.plans.keys():
		var plan := world.plans[plan_id]
		if plan.island_id == island_id and (plan_ids.is_empty() or plan_ids.has(plan_id)):
			chosen.append(plan_id)
	chosen.sort()
	if chosen.is_empty():
		return CommandResult.refused(&"REASON_NO_PLAN_HERE")
	var result := CommandResult.new()
	result.island_id = island_id
	var first_reason := &""
	for plan_id: int in chosen:
		var plan := world.plans[plan_id]
		var built := PlaceBuildingCommand.new(island_id, plan.def_id, plan.origin, plan.rotation).execute(context)
		if not built.ok():
			if first_reason == &"":
				first_reason = built.reason
			continue
		world.plans.erase(plan_id)
		result.plans_changed = true
		result.placed.append_array(built.placed)
		if built.trees_cleared.has_area():
			result.trees_cleared = built.trees_cleared if not result.trees_cleared.has_area() \
					else result.trees_cleared.merge(built.trees_cleared)
		result.ships_changed = result.ships_changed or built.ships_changed
		result.colonized = result.colonized or built.colonized
	if result.placed.is_empty():
		return CommandResult.refused(first_reason)
	return result
