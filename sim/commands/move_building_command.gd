class_name MoveBuildingCommand
extends Command
## Muda um prédio de lugar sem custo (Fase 8): mesma ilha, nova origem e rotação, com as mesmas
## regras de lugar e terreno de construir. O prédio leva tudo o que tem (moradores, buffers,
## nível, pausa); a carroça que estava fora volta para casa com a carga, que segue na próxima
## viagem. Píer ou entreposto com navio encostado não sai do lugar.

const SAME_PLACE := &"REASON_SAME_PLACE"
const SHIP_AT_BERTH := &"REASON_SHIP_AT_BERTH"

var building_id: int
var origin: Vector2i
var rotation: int


func _init(id: int, at: Vector2i, rot: int) -> void:
	building_id = id
	origin = at
	rotation = rot


func execute(context: CommandContext) -> CommandResult:
	var reason := check(context.world, context.data, context.config, building_id, origin, rotation, context.ignore_terrain)
	if reason != PlacementRules.OK:
		return CommandResult.refused(reason)
	var world := context.world
	var record := world.building(building_id)
	var def := context.data.building(record.def_id)
	var grid := world.island(record.island_id)
	grid.fill_building(Footprint.rect(record.origin, def.size, record.rotation), 0)
	record.origin = origin
	record.rotation = rotation
	var area := Footprint.rect(origin, def.size, rotation)
	grid.fill_building(area, building_id)
	var cart := world.cart(building_id)
	if cart != null:
		cart.return_home()
		# a entrada que vinha a caminho chega junto com o prédio
		for good: StringName in cart.cargo.keys():
			if def.inputs.has(good):
				record.input_buffer[good] = record.input_buffer.get(good, 0.0) + cart.cargo[good]
				cart.cargo.erase(good)
	var result := CommandResult.new()
	result.island_id = record.island_id
	# a vista e o resto da interface refazem o prédio como se ele saísse e entrasse de novo
	result.removed.append(building_id)
	result.placed.append(building_id)
	var cells: Array[Vector2i] = []
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			cells.append(Vector2i(x, y))
	if grid.clear_trees(cells):
		result.trees_cleared = area
	if def.is_berth():
		result.ships_changed = true
	return result


## Motivo pelo qual o prédio não pode ir para lá, ou &"" (também usado pela prévia).
static func check(world: WorldState, data: GameData, config: GameConfig, id: int, at: Vector2i, rot: int,
		ignore_terrain: bool = false) -> StringName:
	var record := world.building(id)
	if record == null:
		return PlacementRules.UNKNOWN_BUILDING
	if at == record.origin and rot == record.rotation:
		return SAME_PLACE
	var def := data.building(record.def_id)
	if def.is_berth():
		for ship: Ship in world.ships.values():
			if ship.berth_id == id:
				return SHIP_AT_BERTH
	var grid := world.island(record.island_id)
	var old_area := Footprint.rect(record.origin, def.size, record.rotation)
	# o prédio não atrapalha a si mesmo: a área antiga fica livre durante a conferência
	grid.fill_building(old_area, 0)
	var reason := PlacementRules.check_building(grid, def, at, rot)
	if reason == PlacementRules.OK and not ignore_terrain:
		reason = PlacementRules.check_terrain(grid, data.profile(world.economy(record.island_id).profile_id), def, at, rot, config)
	grid.fill_building(old_area, id)
	return reason
