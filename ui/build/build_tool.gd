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
## Prédio que está sendo mudado de lugar (modo MOVE).
var moving_id: int = 0

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


func start_road(paved: bool = false) -> void:
	road_paved = paved
	_enter(Mode.ROAD)


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
		Mode.BUILDING:
			_run(PlaceBuildingCommand.new(island_id, building_def.id, building_origin(), rotation))
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
	var command: Command = BuildRoadCommand.new(island_id, road_cells(), road_paved) if mode == Mode.ROAD \
			else DemolishCommand.new(island_id, demolish_rect())
	dragging = false
	_run(command)
	changed.emit()


func building_origin() -> Vector2i:
	return Footprint.origin_centered_on(hover_cell, building_def.size, rotation)


func building_rect() -> Rect2i:
	return Footprint.rect(building_origin(), building_def.size, rotation)


## Traçado da estrada: o L do arrasto, ou só a célula sob o cursor antes de arrastar.
func road_cells() -> Array[Vector2i]:
	if dragging:
		return RoadPath.l_path(drag_start, hover_cell)
	return [hover_cell]


func demolish_rect() -> Rect2i:
	return GridSpace.rect_between(drag_start, hover_cell) if dragging else Rect2i(hover_cell, Vector2i.ONE)


## Motivo pelo qual a prévia atual seria recusada, ou &"" se ela pode ser feita: lugar,
## terreno, desbloqueio e custo, igual ao que o comando vai conferir.
func preview_reason() -> StringName:
	match mode:
		Mode.BUILDING:
			return _simulation.placement_reason(building_def, building_origin(), rotation, island_id)
		Mode.MOVE:
			return _simulation.move_reason(moving_id, building_origin(), rotation)
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
	return BuildRoadCommand.cost_money(_simulation.config, BuildRoadCommand.new_cells(grid(), road_cells(), road_paved), road_paved)


## Tijolos do traçado de paralelepípedo (vazio na estrada de terra).
func road_materials() -> Dictionary[StringName, int]:
	return BuildRoadCommand.cost_materials(_simulation.config, BuildRoadCommand.new_cells(grid(), road_cells(), road_paved), road_paved)


func _enter(new_mode: Mode) -> void:
	mode = new_mode
	moving_id = 0
	dragging = false
	select(0)
	select_ship(0)
	changed.emit()


func _run(command: Command) -> bool:
	var result := _simulation.execute(command)
	if not result.ok():
		refused.emit(result.reason)
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
	elif event.is_action_pressed(&"build_cancel"):
		cancel()
	elif event.is_action_pressed(&"build_road"):
		start_road()
	elif event.is_action_pressed(&"build_demolish"):
		start_demolish()


func _on_mouse_button(event: InputEventMouseButton) -> void:
	var raw_cell: Variant = _screen_cell(event.position)
	if event.button_index == MOUSE_BUTTON_LEFT and raw_cell is Vector2i:
		var cell: Vector2i = raw_cell
		if event.pressed:
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
