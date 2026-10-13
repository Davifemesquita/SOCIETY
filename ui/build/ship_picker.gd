class_name ShipPicker
extends Node
## Clique nos navios e no mar (Fase 6): sem ferramenta ativa, o clique perto de um navio o
## seleciona; no modo de escolher destino, o clique numa ilha (ou no posto do comerciante) manda o
## navio para lá. Recebe a entrada antes da BuildTool (fica depois dela na árvore) e marca o
## evento como tratado quando usa o clique.

var _simulation: Simulation
var _tool: BuildTool
var _camera: StrategyCamera
var _view: ShipView


func setup(simulation: Simulation, tool: BuildTool, camera: StrategyCamera, view: ShipView) -> void:
	_simulation = simulation
	_tool = tool
	_camera = camera
	_view = view
	tool.ship_selection_changed.connect(view.select)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var button: InputEventMouseButton = event
	if button.button_index != MOUSE_BUTTON_LEFT or not button.pressed:
		return
	if click(button.position):
		get_viewport().set_input_as_handled()


## Trata um clique na tela; true se ele era do navio (o resto segue para a BuildTool).
func click(screen_position: Vector2) -> bool:
	if _tool.mode == BuildTool.Mode.SAIL_TO:
		send_to(destination_at(screen_position))
		return true
	if _tool.mode != BuildTool.Mode.NONE:
		return false
	var ship_id := _view.ship_at_screen(_camera.camera, screen_position)
	if ship_id == 0 or _simulation.world.ship(ship_id).owner != Ship.Owner.PLAYER:
		return false
	_tool.select_ship(ship_id)
	return true


## Destino sob a tela: o posto do comerciante, a ilha sob o cursor ou, no mar aberto, a ilha mais
## perto do ponto. Ship.NOWHERE se o clique não acertou o mundo.
func destination_at(screen_position: Vector2) -> int:
	if _view.trader_post_at_screen(_camera.camera, screen_position):
		return Ship.TRADER_POST
	var origin := _camera.camera.project_ray_origin(screen_position)
	var normal := _camera.camera.project_ray_normal(screen_position)
	var raw: Variant = Plane(Vector3.UP, 0.0).intersects_ray(origin, normal)
	if not raw is Vector3:
		return Ship.NOWHERE
	var point: Vector3 = raw
	var best := Ship.NOWHERE
	var best_gap := INF
	for island_id: int in _simulation.world.islands.size():
		var rect := _simulation.world.island(island_id).world_rect()
		var nearest := Vector2(clampf(point.x, rect.position.x, rect.end.x), clampf(point.z, rect.position.y, rect.end.y))
		var gap := nearest.distance_to(Vector2(point.x, point.z))
		if gap < best_gap:
			best = island_id
			best_gap = gap
	return best


func send_to(target: int) -> void:
	var ship_id := _tool.selected_ship
	_tool.mode = BuildTool.Mode.NONE
	_tool.changed.emit()
	if target == Ship.NOWHERE:
		return
	var result := _simulation.execute(MoveShipCommand.new(ship_id, target))
	if not result.ok():
		_tool.refused.emit(result.reason)
