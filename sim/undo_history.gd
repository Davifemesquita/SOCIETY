class_name UndoHistory
extends RefCounted
## Desfazer e refazer (Fase 49), fora do save. Cada ação guardada sabe o que o comando mexeu: o dinheiro e o estoque da
## ilha antes e depois, as estradas, o trilho (Fase 72), as árvores e as árvores derrubadas do retângulo dele, os prédios que criou e os que
## tirou (o próprio registro, com moradores e carroça) e as plantas. O UndoCommand volta tudo; no mesmo tick volta os
## valores exatos (o estado fica idêntico), depois devolve a diferença (o reembolso é integral). A janela é de
## config.undo_window_s de jogo; um mundo novo (carregar) zera tudo.

const NOTHING := &"REASON_NOTHING_TO_UNDO"
const EXPIRED := &"REASON_UNDO_EXPIRED"
const CHANGED := &"REASON_UNDO_CHANGED"


class Entry:
	var command: Command
	var world: WorldState
	var island_id: int
	var tick: int
	var area: Rect2i
	var money_before: float
	var money_after: float
	var stock_before: Dictionary[StringName, float] = {}
	var stock_after: Dictionary[StringName, float] = {}
	var next_id_before: int
	var next_id_after: int
	var roads_before := PackedByteArray()
	var roads_after := PackedByteArray()
	var rails_before := PackedByteArray()
	var rails_after := PackedByteArray()
	var trees_before := PackedByteArray()
	var trees_after := PackedByteArray()
	var cleared_before := PackedByteArray()
	var cleared_after := PackedByteArray()
	var placed: Array[int] = []
	var removed: Array[BuildingRecord] = []
	var removed_carts: Dictionary[int, Cart] = {}
	var plans_before: Dictionary[int, PlanRecord] = {}
	var plans_after: Dictionary[int, PlanRecord] = {}
	var next_plan_before: int
	var next_plan_after: int
	# antes do comando: o que existia (referências; o registro tirado continua vivo aqui)
	var buildings_before: Dictionary[int, BuildingRecord] = {}
	var carts_before: Dictionary[int, Cart] = {}


var _done: Array[Entry] = []
var _redo: Array[Entry] = []


func clear() -> void:
	_done.clear()
	_redo.clear()


func can_undo(simulation: Simulation) -> bool:
	return last(simulation) != null


func can_redo(simulation: Simulation) -> bool:
	return next_redo(simulation) != null


func size() -> int:
	return _done.size()


## Guarda o estado antes do comando, ou null se ele não entra no histórico.
func begin(simulation: Simulation, command: Command) -> Entry:
	var world := simulation.world
	var island_id := _island_of(command)
	var grid := world.island(island_id)
	if grid == null:
		return null
	var area := area_of(command, simulation)
	if area.size == Vector2i.ZERO and not command is PlacePlanCommand and not command is RemovePlansCommand:
		return null
	var entry := Entry.new()
	entry.command = command
	entry.world = world
	entry.island_id = island_id
	entry.tick = world.tick
	entry.area = area.intersection(Rect2i(Vector2i.ZERO, grid.size))
	entry.money_before = world.money
	entry.stock_before = world.economy(island_id).stock.duplicate()
	entry.next_id_before = world.next_building_id
	entry.next_plan_before = world.next_plan_id
	entry.plans_before = world.plans.duplicate()
	entry.buildings_before = world.buildings.duplicate()
	entry.carts_before = world.carts.duplicate()
	entry.roads_before = region(grid.roads, grid.size.x, entry.area)
	entry.rails_before = region(grid.rails, grid.size.x, entry.area)
	entry.trees_before = region(grid.trees, grid.size.x, entry.area)
	entry.cleared_before = region(grid.cleared_trees, grid.size.x, entry.area)
	return entry


## Fecha a ação depois do comando que deu certo. Fundar colônia ou mexer na frota não volta atrás: fica fora.
func commit(simulation: Simulation, entry: Entry, result: CommandResult, clear_redo: bool = true) -> void:
	if entry == null or result.colonized or result.ships_changed:
		return
	var world := simulation.world
	var grid := world.island(entry.island_id)
	entry.money_after = world.money
	entry.stock_after = world.economy(entry.island_id).stock.duplicate()
	entry.next_id_after = world.next_building_id
	entry.next_plan_after = world.next_plan_id
	entry.plans_after = world.plans.duplicate()
	entry.roads_after = region(grid.roads, grid.size.x, entry.area)
	entry.rails_after = region(grid.rails, grid.size.x, entry.area)
	entry.trees_after = region(grid.trees, grid.size.x, entry.area)
	entry.cleared_after = region(grid.cleared_trees, grid.size.x, entry.area)
	entry.placed = result.placed.duplicate()
	for building_id: int in result.removed:
		if entry.buildings_before.has(building_id):
			entry.removed.append(entry.buildings_before[building_id])
			if entry.carts_before.has(building_id):
				entry.removed_carts[building_id] = entry.carts_before[building_id]
	# só o que a ação precisa: as cópias do mundo inteiro vão embora
	entry.buildings_before = {}
	entry.carts_before = {}
	_done.append(entry)
	while _done.size() > maxi(1, simulation.config.undo_max_entries):
		_done.pop_front()
	if clear_redo:
		_redo.clear()


## A última ação do mundo atual, ou null.
func last(simulation: Simulation) -> Entry:
	while not _done.is_empty() and _done.back().world != simulation.world:
		_done.pop_back()
	return _done.back() if not _done.is_empty() else null


func moved_to_redo(entry: Entry) -> void:
	_done.erase(entry)
	_redo.append(entry)


func next_redo(simulation: Simulation) -> Entry:
	while not _redo.is_empty() and _redo.back().world != simulation.world:
		_redo.pop_back()
	return _redo.back() if not _redo.is_empty() else null


func redone(entry: Entry) -> void:
	_redo.erase(entry)


## Saiu da janela: ela e as de antes não voltam mais.
func expire() -> void:
	_done.clear()


## O retângulo que o comando pode mexer (estradas, árvores): o lote, o traçado, a área.
static func area_of(command: Command, simulation: Simulation) -> Rect2i:
	var data := simulation.data
	if command is PlaceBuildingCommand:
		var place := command as PlaceBuildingCommand
		var def := data.building(place.def_id)
		return Footprint.rect(place.origin, def.size, place.rotation) if def != null else Rect2i()
	if command is BuildRoadCommand or command is BuildRailCommand:
		var cells: Array[Vector2i] = command.get(&"cells")
		if cells.is_empty():
			return Rect2i()
		var box := Rect2i(cells[0], Vector2i.ONE)
		for cell: Vector2i in cells:
			box = box.expand(cell).expand(cell + Vector2i.ONE)
		return box
	if command is DemolishCommand:
		return (command as DemolishCommand).area
	if command is ReplaceCommand:
		return (command as ReplaceCommand).area
	if command is BuildPlansCommand:
		var build := command as BuildPlansCommand
		var box := Rect2i()
		for plan: PlanRecord in simulation.world.plans.values():
			if plan.island_id == build.island_id and (build.plan_ids.is_empty() or build.plan_ids.has(plan.id)):
				box = plan.rect(data) if not box.has_area() else box.merge(plan.rect(data))
		return box
	if command is PlacePlanCommand or command is RemovePlansCommand:
		return Rect2i()
	return Rect2i()


static func _island_of(command: Command) -> int:
	for kind: Array in [[PlaceBuildingCommand, &"island_id"], [BuildRoadCommand, &"island_id"], [BuildRailCommand, &"island_id"],
			[DemolishCommand, &"island_id"],
			[ReplaceCommand, &"island_id"], [BuildPlansCommand, &"island_id"], [PlacePlanCommand, &"island_id"],
			[RemovePlansCommand, &"island_id"]]:
		var script: Script = kind[0]
		if is_instance_of(command, script):
			var field: StringName = kind[1]
			var island: int = command.get(field)
			return island
	return -1


## Os bytes do retângulo (linha a linha), de um array da grade de largura "width"; vazio se o array é vazio.
static func region(bytes: PackedByteArray, width: int, area: Rect2i) -> PackedByteArray:
	var out := PackedByteArray()
	if bytes.is_empty() or not area.has_area():
		return out
	for y: int in range(area.position.y, area.end.y):
		out.append_array(bytes.slice(y * width + area.position.x, y * width + area.end.x))
	return out


## Põe os bytes de volta no retângulo.
static func paste(bytes: PackedByteArray, width: int, area: Rect2i, values: PackedByteArray) -> void:
	if values.is_empty():
		return
	var k := 0
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			bytes[y * width + x] = values[k]
			k += 1
