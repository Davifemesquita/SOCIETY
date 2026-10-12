class_name BuildTool
extends Node
## Ferramenta de construção: transforma clique e arrasto em comandos para a simulação.
## A lógica trabalha em células (hover, press, release), o que a deixa testável sem mouse;
## _unhandled_input só converte o mouse em célula.

enum Mode { NONE, BUILDING, ROAD, DEMOLISH }

signal changed()
signal selection_changed(building_id: int)
signal refused(reason: StringName)

var mode: Mode = Mode.NONE
var building_def: BuildingDef
var rotation: int = 0
var hover_cell: Vector2i = Vector2i.ZERO
var dragging: bool = false
var drag_start: Vector2i = Vector2i.ZERO
var selected_id: int = 0

var _simulation: Simulation
var _camera: StrategyCamera
var _cell_size: float


func setup(simulation: Simulation, camera: StrategyCamera, cell_size: float) -> void:
	_simulation = simulation
	_camera = camera
	_cell_size = cell_size
	EventBus.building_removed.connect(_on_building_removed)
	EventBus.world_replaced.connect(func() -> void: select(0))


func start_building(def: BuildingDef) -> void:
	building_def = def
	_enter(Mode.BUILDING)


func start_road() -> void:
	_enter(Mode.ROAD)


func start_demolish() -> void:
	_enter(Mode.DEMOLISH)


func cancel() -> void:
	if dragging:
		dragging = false
	elif mode != Mode.NONE:
		mode = Mode.NONE
	else:
		select(0)
	changed.emit()


func rotate_building() -> void:
	rotation = (rotation + 1) % 4
	changed.emit()


func select(building_id: int) -> void:
	if selected_id == building_id:
		return
	selected_id = building_id
	selection_changed.emit(building_id)


func hover(cell: Vector2i) -> void:
	if cell != hover_cell:
		hover_cell = cell
		changed.emit()


func press(cell: Vector2i) -> void:
	hover(cell)
	match mode:
		Mode.NONE:
			select(_grid().building_at(cell))
		Mode.BUILDING:
			_run(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, building_def.id, building_origin(), rotation))
		Mode.ROAD, Mode.DEMOLISH:
			dragging = true
			drag_start = cell
			changed.emit()


func release(cell: Vector2i) -> void:
	hover(cell)
	if not dragging:
		return
	var command: Command = BuildRoadCommand.new(Simulation.MAIN_ISLAND, road_cells()) if mode == Mode.ROAD \
			else DemolishCommand.new(Simulation.MAIN_ISLAND, demolish_rect())
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
			return _simulation.placement_reason(building_def, building_origin(), rotation)
		Mode.ROAD:
			for cell: Vector2i in road_cells():
				var reason := PlacementRules.check_road_cell(_grid(), cell)
				if reason != PlacementRules.OK:
					return reason
			if not _simulation.free_build:
				var world := _simulation.world
				if not _simulation.config.instant_logistics and not world.has_trading_post(Simulation.MAIN_ISLAND, _simulation.data):
					return PlacementRules.NEEDS_TRADING_POST
				var empty: Dictionary[StringName, int] = {}
				return PlacementRules.check_cost(world, world.economy(Simulation.MAIN_ISLAND), _simulation.config, road_cost(), empty)
	return PlacementRules.OK


## Custo do traçado atual: só as células que ainda não são estrada.
func road_cost() -> int:
	var new_cells := 0
	for cell: Vector2i in road_cells():
		if _grid().in_bounds(cell) and not _grid().has_road(cell):
			new_cells += 1
	return new_cells * _simulation.config.road_cost_per_cell


func _enter(new_mode: Mode) -> void:
	mode = new_mode
	dragging = false
	select(0)
	changed.emit()


func _run(command: Command) -> void:
	var result := _simulation.execute(command)
	if not result.ok():
		refused.emit(result.reason)


func _grid() -> IslandGrid:
	return _simulation.world.island(Simulation.MAIN_ISLAND)


func _on_building_removed(building_id: int) -> void:
	if building_id == selected_id:
		select(0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event
		_hover_screen(motion.position)
	elif event is InputEventMouseButton:
		var button: InputEventMouseButton = event
		_on_mouse_button(button)
	elif event.is_action_pressed(&"build_rotate") and mode == Mode.BUILDING:
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


func _screen_cell(screen_position: Vector2) -> Variant:
	var point: Variant = _camera.ground_point(screen_position)
	if point is Vector3:
		var ground: Vector3 = point
		return GridSpace.world_to_cell(ground, _cell_size)
	return null
