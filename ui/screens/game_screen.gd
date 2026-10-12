class_name GameScreen
extends Node
## Raiz da partida: monta simulação, ilha, câmera, apresentação, ferramenta e interface,
## e cuida de salvar e carregar. A simulação roda nos ticks do GameClock.

## Slot a carregar ao abrir a tela (vazio = jogo novo). Definido pela tela de abertura.
static var load_slot_on_start: String = ""

const QUICK_SLOT := "rapido"
const THUMBNAIL_SIZE := Vector2i(320, 180)

var simulation: Simulation
var camera: StrategyCamera
var tool: BuildTool
var hud: Hud
var building_view: BuildingView
var road_view: RoadView
var overlay: DebugOverlay

var _config: GameConfig


func _ready() -> void:
	_config = GameConfig.get_default()
	simulation = Simulation.new(_config, BuildingCatalog.get_default())
	var grid := simulation.world.island(Simulation.MAIN_ISLAND)
	var size_m := Vector2(grid.size) * _config.cell_size_m
	var island := FlatIsland.new()
	island.setup(size_m)
	add_child(island)
	road_view = RoadView.new()
	road_view.setup(simulation, _config.cell_size_m)
	add_child(road_view)
	building_view = BuildingView.new()
	building_view.setup(simulation, _config.cell_size_m)
	add_child(building_view)
	overlay = DebugOverlay.new()
	overlay.setup(simulation, _config.cell_size_m)
	add_child(overlay)
	camera = StrategyCamera.new()
	add_child(camera)
	camera.setup(_config, Rect2(Vector2.ZERO, size_m))
	tool = BuildTool.new()
	tool.setup(simulation, camera, _config.cell_size_m)
	add_child(tool)
	var preview := BuildPreviewView.new()
	preview.setup(tool, _config.cell_size_m)
	add_child(preview)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	layer.add_child(hud)
	hud.setup(tool, simulation)
	hud.save_requested.connect(quicksave)
	hud.load_requested.connect(quickload)
	tool.changed.connect(func() -> void: overlay.grid_visible = tool.mode != BuildTool.Mode.NONE)
	tool.selection_changed.connect(building_view.select)
	var shortcuts := GameShortcuts.new()
	shortcuts.setup(self)
	add_child(shortcuts)
	GameClock.ticked.connect(simulation.tick)
	if not load_slot_on_start.is_empty():
		load_game(load_slot_on_start)
		load_slot_on_start = ""


func _exit_tree() -> void:
	if GameClock.ticked.is_connected(simulation.tick):
		GameClock.ticked.disconnect(simulation.tick)


func game_state() -> Dictionary:
	return {"world": simulation.world.to_dict(), "clock": GameClock.clock.to_dict(), "camera": camera.rig.to_dict()}


func quicksave() -> void:
	save_game(QUICK_SLOT)


func quickload() -> void:
	load_game(QUICK_SLOT)


func save_game(slot: String) -> bool:
	var ok := SaveSystem.save_game(slot, game_state(), _thumbnail()) == OK
	hud.show_message(tr("MSG_SAVED") if ok else tr("MSG_SAVE_FAILED"))
	return ok


## Troca o mundo pelo do save. Save inválido não mexe na partida em andamento.
func load_game(slot: String) -> bool:
	var state := SaveSystem.load_game(slot)
	var raw_world: Variant = state.get("world")
	var world: WorldState = null
	if raw_world is Dictionary:
		var world_data: Dictionary = raw_world
		world = WorldState.from_dict(world_data, simulation.catalog)
	if world == null:
		hud.show_message(tr("MSG_LOAD_FAILED"))
		return false
	simulation.world = world
	var raw_clock: Variant = state.get("clock")
	if raw_clock is Dictionary:
		var clock_data: Dictionary = raw_clock
		GameClock.clock.load_dict(clock_data)
	var raw_camera: Variant = state.get("camera")
	if raw_camera is Dictionary:
		var camera_data: Dictionary = raw_camera
		camera.rig.load_dict(camera_data)
		camera.apply()
	EventBus.world_replaced.emit()
	EventBus.time_speed_changed.emit(GameClock.clock.speed_index, GameClock.clock.is_paused())
	hud.show_message(tr("MSG_LOADED"))
	return true


func center_on_selected() -> void:
	var record := simulation.world.building(tool.selected_id)
	if record == null:
		return
	var def := simulation.def_of(record)
	camera.rig.center_on(GridSpace.rect_center(Footprint.rect(record.origin, def.size, record.rotation), _config.cell_size_m))


func _thumbnail() -> Image:
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		return null
	image.resize(THUMBNAIL_SIZE.x, THUMBNAIL_SIZE.y, Image.INTERPOLATE_BILINEAR)
	return image
