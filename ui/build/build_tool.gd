class_name BuildTool
extends Node
## Ferramenta de construção: transforma clique e arrasto em comandos para a simulação.
## A lógica trabalha em células (hover, press, release), o que a deixa testável sem mouse;
## _unhandled_input só converte o mouse em ilha e célula (a ilha sob o cursor, desde a Fase 5).
## Desde a Fase 6 também guarda o navio selecionado e o modo de escolher para onde ele vai (o
## clique no mar e nos navios fica com o ShipPicker). Na Fase 8 entram a estrada de
## paralelepípedo (o mesmo arrasto, com road_paved) e o modo de mover o prédio selecionado.

enum Mode { NONE, BUILDING, ROAD, DEMOLISH, SAIL_TO, MOVE }

signal changed()
signal selection_changed(building_id: int)
signal ship_selection_changed(ship_id: int)
signal refused(reason: StringName)

var mode: Mode = Mode.NONE
var building_def: BuildingDef
var rotation: int = 0
var hover_cell: Vector2i = Vector2i.ZERO
var dragging: bool = false
var drag_start: Vector2i = Vector2i.ZERO
var selected_id: int = 0
## Navio selecionado (0 = nenhum). Prédio e navio não ficam selecionados juntos.
var selected_ship: int = 0
## Ilha em que a ferramenta está (a que está sob o cursor; não troca no meio de um arrasto).
var island_id: int = Simulation.MAIN_ISLAND
## A estrada do modo ROAD é de paralelepípedo.
var road_paved: bool = false
## Ferrovia (Fase 70): o arrasto do modo ROAD põe trilho em vez de estrada.
var road_rail: bool = false
## Traçado em diagonal (Fase 17), alternado com a tecla de girar enquanto se traça estrada.
var road_diagonal: bool = false
## Prédio que está sendo mudado de lugar (modo MOVE).
var moving_id: int = 0
## Fase 47: a obra é uma cópia (tipo e rotação do original, e a configuração dele vai para cada prédio novo).
var copying: bool = false
var copy_paused: bool = false
var copy_upgrade_blocked: bool = false
## Fase 49: no modo planta a obra vira planta (sem custo) e o arrasto de demolir apaga plantas.
var plan_mode: bool = false
## Fase 49: o arrasto com Ctrl na obra substitui, no retângulo, os prédios do mesmo tamanho pelo escolhido.
var replace_drag: bool = false

var _simulation: Simulation
var _camera: StrategyCamera
var _cell_size: float


func setup(simulation: Simulation, camera: StrategyCamera, cell_size: float) -> void:
	_simulation = simulation
	_camera = camera
	_cell_size = cell_size
	EventBus.building_removed.connect(_on_building_removed)
	EventBus.world_replaced.connect(func() -> void:
		select(0)
		select_ship(0))


func start_building(def: BuildingDef) -> void:
	building_def = def
	_enter(Mode.BUILDING)


## Copiar o prédio (Fase 47): a obra do mesmo tipo, com a rotação dele; cada cópia sai com a configuração do original
## (pausado e o bloqueio de subida de classe). Devolve se havia o que copiar.
func copy_building(building_id: int) -> bool:
	var record := _simulation.world.building(building_id)
	if record == null:
		return false
	start_building(_simulation.def_of(record))
	rotation = record.rotation
	copying = true
	copy_paused = record.paused
	copy_upgrade_blocked = record.upgrade_blocked
	changed.emit()
	return true


func start_road(paved: bool = false) -> void:
	road_paved = paved
	road_rail = false
	_enter(Mode.ROAD)


## Ferrovia (Fase 70): o mesmo arrasto da estrada, que põe trilho.
func start_rail() -> void:
	road_paved = false
	road_rail = true
	_enter(Mode.ROAD)


## Alterna o traçado da estrada entre o L e a diagonal (Fase 17).
func toggle_road_diagonal() -> void:
	road_diagonal = not road_diagonal
	changed.emit()


func start_paved_road() -> void:
	start_road(true)


## Muda o prédio de lugar: a prévia é a dele, com a rotação que ele tem, e o clique o leva.
func start_move(building_id: int) -> void:
	var record := _simulation.world.building(building_id)
	if record == null:
		return
	building_def = _simulation.def_of(record)
	rotation = record.rotation
	island_id = record.island_id
	_enter(Mode.MOVE)
	moving_id = building_id


func start_demolish() -> void:
	_enter(Mode.DEMOLISH)


## Escolher no mapa para onde vai o navio selecionado.
func start_sail_to() -> void:
	if selected_ship == 0:
		return
	mode = Mode.SAIL_TO
	dragging = false
	changed.emit()


func cancel() -> void:
	if dragging:
		dragging = false
	elif mode != Mode.NONE:
		mode = Mode.NONE
	else:
		select(0)
		select_ship(0)
	changed.emit()


func rotate_building() -> void:
	rotation = (rotation + 1) % 4
	changed.emit()


func select(building_id: int) -> void:
	if selected_id == building_id:
		return
	if building_id != 0:
		select_ship(0)
	selected_id = building_id
	selection_changed.emit(building_id)


func select_ship(ship_id: int) -> void:
	if selected_ship == ship_id:
		return
	if ship_id != 0:
		select(0)
	elif mode == Mode.SAIL_TO:
		mode = Mode.NONE
	selected_ship = ship_id
	ship_selection_changed.emit(ship_id)


func hover(cell: Vector2i) -> void:
	if cell != hover_cell:
		hover_cell = cell
		changed.emit()


func press(cell: Vector2i) -> void:
	hover(cell)
	match mode:
		Mode.NONE:
			select(grid().building_at(cell))
		Mode.BUILDING when replace_drag:
			dragging = true
			drag_start = cell
			changed.emit()
		Mode.BUILDING when plan_mode:
			_run(PlacePlanCommand.new(island_id, building_def.id, building_origin(), rotation))
		Mode.BUILDING:
			var result := _simulation.execute_undoable(PlaceBuildingCommand.new(island_id, building_def.id, building_origin(), rotation))
			if not result.ok():
				refused.emit(result.reason)
			elif copying:
				for placed: int in result.placed:
					if copy_paused:
						_simulation.execute(SetPausedCommand.new(placed, true))
					if copy_upgrade_blocked:
						_simulation.execute(SetUpgradeBlockedCommand.new(placed, true))
		Mode.MOVE:
			var moved := moving_id
			if _run(MoveBuildingCommand.new(moved, building_origin(), rotation)):
				mode = Mode.NONE
				moving_id = 0
				select(moved)
				changed.emit()
		Mode.ROAD, Mode.DEMOLISH:
			dragging = true
			drag_start = cell
			changed.emit()


func release(cell: Vector2i) -> void:
	hover(cell)
	if not dragging:
		return
	var command: Command
	match mode:
		Mode.ROAD when road_rail:
			command = BuildRailCommand.new(island_id, road_cells())
		Mode.ROAD:
			command = BuildRoadCommand.new(island_id, road_cells(), road_paved)
		Mode.BUILDING:
			command = ReplaceCommand.new(island_id, demolish_rect(), building_def.id)
		_:
			command = RemovePlansCommand.new(island_id, demolish_rect()) if plan_mode else DemolishCommand.new(island_id, demolish_rect())
	dragging = false
	_run(command)
	changed.emit()


func building_origin() -> Vector2i:
	return Footprint.origin_centered_on(hover_cell, building_def.size, rotation)


func building_rect() -> Rect2i:
	return Footprint.rect(building_origin(), building_def.size, rotation)


## Traçado da estrada: o L (ou a diagonal) do arrasto, ou só a célula sob o cursor antes de arrastar.
func road_cells() -> Array[Vector2i]:
	if dragging:
		# o trilho (Fase 70) liga só por lado: sempre o L
		if road_diagonal and not road_rail:
			return RoadPath.diagonal_path(drag_start, hover_cell)
		return RoadPath.l_path(drag_start, hover_cell)
	return [hover_cell]


func demolish_rect() -> Rect2i:
	return GridSpace.rect_between(drag_start, hover_cell) if dragging else Rect2i(hover_cell, Vector2i.ONE)


## Motivo pelo qual a prévia atual seria recusada, ou &"" se ela pode ser feita: lugar,
## terreno, desbloqueio e custo, igual ao que o comando vai conferir.
func preview_reason() -> StringName:
	match mode:
		Mode.BUILDING when plan_mode:
			# a planta não cobra nem confere desbloqueio: só o lugar e o terreno
			var reason := PlacementRules.check_building(grid(), building_def, building_origin(), rotation)
			if reason == PlacementRules.OK:
				var profile := _simulation.data.profile(_simulation.world.economy(island_id).profile_id)
				reason = PlacementRules.check_terrain(grid(), profile, building_def, building_origin(), rotation, _simulation.config)
			return reason
		Mode.BUILDING:
			return _simulation.placement_reason(building_def, building_origin(), rotation, island_id)
		Mode.MOVE:
			return _simulation.move_reason(moving_id, building_origin(), rotation)
		Mode.ROAD when road_rail:
			for cell: Vector2i in road_cells():
				var reason := BuildRailCommand.check_cell(grid(), cell, _simulation.config)
				if reason != PlacementRules.OK:
					return reason
			if not _simulation.free_build:
				var world := _simulation.world
				if not world.has_trading_post(island_id, _simulation.data):
					return PlacementRules.NEEDS_TRADING_POST
				return PlacementRules.check_cost(world, world.economy(island_id), _simulation.config, road_cost(), road_materials())
		Mode.ROAD:
			for cell: Vector2i in road_cells():
				var reason := PlacementRules.check_road_cell(grid(), cell, _simulation.config)
				if reason != PlacementRules.OK:
					return reason
			if not _simulation.free_build:
				var world := _simulation.world
				var config := _simulation.config
				if not config.instant_logistics and not world.has_trading_post(island_id, _simulation.data):
					return PlacementRules.NEEDS_TRADING_POST
				if road_paved and world.population(config.paved_road_unlock_tier) < config.paved_road_unlock_residents:
					return PlacementRules.LOCKED
				return PlacementRules.check_cost(world, world.economy(island_id), config, road_cost(), road_materials())
	return PlacementRules.OK


## Custo do traçado atual: só as células que ainda não têm a estrada pedida.
func road_cost() -> int:
	if road_rail:
		return BuildRailCommand.new_cells(grid(), road_cells()) * _simulation.config.rail_cost_per_cell
	return BuildRoadCommand.cost_money(_simulation.config, BuildRoadCommand.new_cells(grid(), road_cells(), road_paved), road_paved)


## Tijolos do traçado de paralelepípedo (vazio na estrada de terra).
func road_materials() -> Dictionary[StringName, int]:
	if road_rail:
		return BuildRailCommand.cost_materials(_simulation.config, BuildRailCommand.new_cells(grid(), road_cells()))
	return BuildRoadCommand.cost_materials(_simulation.config, BuildRoadCommand.new_cells(grid(), road_cells(), road_paved), road_paved)


func _enter(new_mode: Mode) -> void:
	mode = new_mode
	moving_id = 0
	copying = false
	dragging = false
	select(0)
	select_ship(0)
	changed.emit()


## Fase 49: tudo passa pelo histórico de desfazer (o que não entra nele, como mover, só é executado).
func _run(command: Command) -> bool:
	var result := _simulation.execute_undoable(command)
	if not result.ok():
		refused.emit(result.reason)
	return result.ok()


## Planta liga e desliga (Fase 49).
func toggle_plan_mode() -> void:
	plan_mode = not plan_mode
	changed.emit()


## Constrói as plantas da ilha da vez (pelo histórico: desfazer tira tudo de uma vez).
func build_plans() -> bool:
	return _run(BuildPlansCommand.new(island_id))


func undo() -> bool:
	var result := _simulation.undo_last()
	if not result.ok():
		refused.emit(result.reason)
	changed.emit()
	return result.ok()


func redo() -> bool:
	var result := _simulation.redo_last()
	if not result.ok():
		refused.emit(result.reason)
	changed.emit()
	return result.ok()


func grid() -> IslandGrid:
	return _simulation.world.island(island_id)


func _on_building_removed(building_id: int) -> void:
	if building_id == selected_id:
		select(0)
	if building_id == moving_id and _simulation.world.building(building_id) == null:
		cancel()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event
		_hover_screen(motion.position)
	elif event is InputEventMouseButton:
		var button: InputEventMouseButton = event
		_on_mouse_button(button)
	elif event.is_action_pressed(&"build_rotate") and mode in [Mode.BUILDING, Mode.MOVE]:
		rotate_building()
	elif event.is_action_pressed(&"build_rotate") and mode == Mode.ROAD:
		toggle_road_diagonal()
	elif event.is_action_pressed(&"build_cancel"):
		cancel()
	elif event.is_action_pressed(&"build_road"):
		start_road()
	elif event.is_action_pressed(&"build_demolish"):
		start_demolish()
	elif event.is_action_pressed(&"build_plan"):
		toggle_plan_mode()
	elif event.is_action_pressed(&"build_copy"):
		# o selecionado, ou o prédio sob o cursor
		if not copy_building(selected_id):
			copy_building(grid().building_at(hover_cell))


func _on_mouse_button(event: InputEventMouseButton) -> void:
	var raw_cell: Variant = _screen_cell(event.position)
	if event.button_index == MOUSE_BUTTON_LEFT and raw_cell is Vector2i:
		var cell: Vector2i = raw_cell
		if event.pressed:
			# Fase 49: Ctrl no clique da obra arrasta o retângulo de substituir
			replace_drag = mode == Mode.BUILDING and event.ctrl_pressed
			press(cell)
		else:
			release(cell)
	elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed and not _camera.right_button_dragged():
		cancel()


func _hover_screen(screen_position: Vector2) -> void:
	var raw_cell: Variant = _screen_cell(screen_position)
	if raw_cell is Vector2i:
		var cell: Vector2i = raw_cell
		hover(cell)


## Célula sob o cursor, na ilha sob ele (a ilha só troca fora de um arrasto).
func _screen_cell(screen_position: Vector2) -> Variant:
	var point: Variant = _camera.ground_point(screen_position)
	if not point is Vector3:
		return null
	var ground: Vector3 = point
	if not dragging:
		var under := island_at(ground)
		if under >= 0 and under != island_id:
			island_id = under
			hover_cell = Vector2i(-1, -1)
	return grid().world_to_cell(ground)


## Ilha cuja área contém o ponto do mundo, ou -1.
func island_at(point: Vector3) -> int:
	var islands := _simulation.world.islands
	for index: int in islands.size():
		if islands[index].world_rect().has_point(Vector2(point.x, point.z)):
			return index
	return -1
