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
var cart_view: CartView
var overlay: DebugOverlay

var _config: GameConfig


func _ready() -> void:
	_config = GameConfig.get_default()
	simulation = Simulation.new(_config, GameData.get_default())
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
	cart_view = CartView.new()
	cart_view.setup(simulation, _config.cell_size_m)
	add_child(cart_view)
	overlay = DebugOverlay.new()
	overlay.setup(simulation, _config.cell_size_m)
	add_child(overlay)
	camera = StrategyCamera.new()
	add_child(camera)
	camera.setup(_config, Rect2(Vector2.ZERO, size_m))
	# jogo novo começa olhando o litoral norte, onde vai o entreposto
	camera.rig.focus = Vector3(size_m.x * 0.5, 0.0, 70.0)
	camera.apply()
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
	tool.changed.connect(func() -> void:
		overlay.grid_visible = tool.mode != BuildTool.Mode.NONE
		update_highlight())
	tool.selection_changed.connect(func(building_id: int) -> void:
		building_view.select(building_id)
		update_highlight())
	EventBus.roads_changed.connect(func(_island_id: int) -> void: update_highlight())
	EventBus.building_placed.connect(func(_id: int) -> void: update_highlight())
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
		world = WorldState.from_dict(world_data, simulation.data)
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


## Destaque no chão: o alcance do serviço (o que vai ser construído ou o selecionado) e a
## área de campos e pastos da fazenda.
func update_highlight() -> void:
	var world := simulation.world
	var grid := world.island(Simulation.MAIN_ISLAND)
	if tool.mode == BuildTool.Mode.BUILDING and tool.building_def != null:
		var def := tool.building_def
		if def.kind == BuildingDef.Kind.SERVICE or def.is_warehouse():
			var front := Footprint.front_cells(tool.building_origin(), def.size, tool.rotation)
			var radius := _config.logistics_range_cells if def.is_warehouse() else ServiceReach.radius_of(def, _config)
			var reach := ServiceReach.road_cells(grid, front, radius)
			var targets: Array[int] = simulation.derived_state().houses if def.kind == BuildingDef.Kind.SERVICE else simulation.derived_state().production
			var covered := ServiceReach.houses(world, simulation.data, Simulation.MAIN_ISLAND, reach, targets)
			overlay.show_custom(Highlight.service(world, simulation.data, Simulation.MAIN_ISLAND, reach, covered))
			return
		if def.modules_required > 0:
			overlay.show_custom(Highlight.area(grid, tool.building_rect().grow(def.module_radius_cells)))
			return
	var selected := world.building(tool.selected_id)
	if tool.mode == BuildTool.Mode.NONE and selected != null:
		var def := simulation.def_of(selected)
		var derived := simulation.derived_state()
		if def.kind == BuildingDef.Kind.SERVICE:
			var reach: PackedInt32Array = derived.service_reach.get(selected.id, PackedInt32Array())
			var houses: Array = derived.service_houses.get(selected.id, [])
			overlay.show_custom(Highlight.service(world, simulation.data, selected.island_id, reach, houses))
			return
		if def.modules_required > 0:
			overlay.show_custom(Highlight.area(grid, Footprint.rect(selected.origin, def.size, selected.rotation).grow(def.module_radius_cells)))
			return
		if def.is_warehouse():
			var cells: PackedInt32Array = derived.warehouse_cells.get(selected.id, PackedInt32Array())
			var front: Array[Vector2i] = []
			for index: int in cells:
				front.append(grid.cell_at(index))
			var served: Array[int] = []
			for entry: DerivedState.ProductionEntry in derived.production_entries:
				if entry.warehouse_id == selected.id:
					served.append(entry.record.id)
			overlay.show_custom(Highlight.service(world, simulation.data, selected.island_id,
					ServiceReach.road_cells(grid, front, _config.logistics_range_cells), served))
			return
	overlay.clear_custom()


## Trapaça de desenvolvimento (só em build de depuração): dinheiro e 20 t de cada bem.
func cheat_resources() -> void:
	if not OS.is_debug_build():
		return
	simulation.world.money += 10000.0
	for good: GoodDef in simulation.data.goods:
		simulation.world.economy(Simulation.MAIN_ISLAND).add(good.id, 20.0, simulation.storage_capacity())


func _thumbnail() -> Image:
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		return null
	image.resize(THUMBNAIL_SIZE.x, THUMBNAIL_SIZE.y, Image.INTERPOLATE_BILINEAR)
	return image
