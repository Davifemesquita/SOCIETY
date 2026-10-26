class_name PlacePlanCommand
extends Command
## Desenha uma planta (Fase 49): confere o lugar (dentro da ilha, sem prédio, o terreno) e que não cobre outra planta;
## não cobra nada nem confere desbloqueio (isso fica para quando for construída).

const OVER_PLAN := &"REASON_OVER_PLAN"

var island_id: int
var def_id: StringName
var origin: Vector2i
var rotation: int


func _init(island: int, def: StringName, at: Vector2i, rot: int) -> void:
	island_id = island
	def_id = def
	origin = at
	rotation = rot


func execute(context: CommandContext) -> CommandResult:
	var world := context.world
	var grid := world.island(island_id)
	var def := context.data.building(def_id)
	if grid == null or def == null:
		return CommandResult.refused(PlacementRules.OUT_OF_ISLAND)
	var reason := PlacementRules.check_building(grid, def, origin, rotation)
	if reason == PlacementRules.OK and not context.ignore_terrain:
		var profile := context.data.profile(world.economy(island_id).profile_id)
		reason = PlacementRules.check_terrain(grid, profile, def, origin, rotation, context.config)
	if reason != PlacementRules.OK:
		return CommandResult.refused(reason)
	var area := Footprint.rect(origin, def.size, rotation)
	for plan: PlanRecord in world.plans.values():
		if plan.island_id == island_id and plan.rect(context.data).intersects(area):
			return CommandResult.refused(OVER_PLAN)
	var plan := PlanRecord.new(world.next_plan_id, def_id, island_id, origin, rotation)
	world.next_plan_id += 1
	world.plans[plan.id] = plan
	var result := CommandResult.new()
	result.island_id = island_id
	result.plans_changed = true
	result.created_id = plan.id
	return result
