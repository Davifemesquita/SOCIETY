class_name GameScreen
extends Node
## Raiz da partida: monta simulação, ilha, câmera, apresentação, ferramenta e interface,
## e cuida de salvar e carregar. A simulação roda nos ticks do GameClock.

## Slot a carregar ao abrir a tela (vazio = jogo novo). Definido pela tela de abertura.
static var load_slot_on_start: String = ""
## Céu do Sky3D (padrão) ou o céu simples. Os testes de interface que não testam o céu desligam:
## o Sky3D renderizado por software (xvfb) leva segundos por quadro.
static var use_sky3d: bool = true
## Semente do arquipélago do jogo novo (−1 = sorteada). A tela de abertura lê `-- --semente N`.
static var world_seed: int = -1
## Ilha plana de antes da Fase 5 em vez do arquipélago: os testes de interface conhecem as
## coordenadas dela.
static var flat_world: bool = false

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
var sky: SkyAdapter
var pedestrian_view: PedestrianView
var window_view: WindowLightsView
var ship_view: ShipView
var ship_picker: ShipPicker
## Chão do mundo: a ilha plana (FlatIsland) ou terreno, água e árvores do arquipélago.
var terrain_view: TerrainView
var water_view: WaterView
var tree_view: TreeView
var _ground: Node3D
## Destaque de terreno por ilha e prédio (percorre a ilha inteira: guardado até árvores caírem).
var _terrain_highlights: Dictionary[String, Image] = {}
## Quanto é noite agora (0 a 1), o mesmo valor do uniforme global night_light.
var night_light: float = 0.0

var _config: GameConfig


func _ready() -> void:
	_config = GameConfig.get_default()
	var data := GameData.get_default()
	if flat_world:
		simulation = Simulation.new(_config, data)
	else:
		var seed_value := world_seed if world_seed >= 0 else randi() % 1_000_000
		simulation = Simulation.new(_config, data, ArchipelagoGenerator.new_world(seed_value, _config, data))
	_build_ground()
	sky = SkyAdapter.new()
	add_child(sky)
	sky.setup(_config, use_sky3d)
	road_view = RoadView.new()
	road_view.setup(simulation, _config.cell_size_m)
	add_child(road_view)
	building_view = BuildingView.new()
	building_view.setup(simulation, _config.cell_size_m)
	add_child(building_view)
	window_view = WindowLightsView.new()
	window_view.setup(simulation, _config)
	add_child(window_view)
	cart_view = CartView.new()
	cart_view.setup(simulation, _config.cell_size_m)
	add_child(cart_view)
	ship_view = ShipView.new()
	add_child(ship_view)
	ship_view.setup(simulation)
	pedestrian_view = PedestrianView.new()
	pedestrian_view.setup(simulation, _config)
	add_child(pedestrian_view)
	overlay = DebugOverlay.new()
	overlay.setup(simulation, _config.cell_size_m)
	add_child(overlay)
	camera = StrategyCamera.new()
	add_child(camera)
	camera.setup(_config, world_bounds())
	camera.height_at = simulation.world.surface_height
	look_at_start()
	tool = BuildTool.new()
	tool.setup(simulation, camera, _config.cell_size_m)
	add_child(tool)
	# depois da ferramenta: recebe o clique antes dela (navio e destino no mar)
	ship_picker = ShipPicker.new()
	ship_picker.setup(simulation, tool, camera, ship_view)
	add_child(ship_picker)
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
		overlay.set_island(tool.island_id)
		update_highlight())
	tool.selection_changed.connect(func(building_id: int) -> void:
		building_view.select(building_id)
		update_highlight())
	EventBus.roads_changed.connect(func(_island_id: int) -> void: update_highlight())
	EventBus.trees_changed.connect(func(_island_id: int, _area: Rect2i) -> void: _terrain_highlights.clear())
	EventBus.world_replaced.connect(func() -> void: _terrain_highlights.clear())
	EventBus.building_placed.connect(func(_id: int) -> void: update_highlight())
	var shortcuts := GameShortcuts.new()
	shortcuts.setup(self)
	add_child(shortcuts)
	GameClock.ticked.connect(simulation.tick)
	# a hora do dia sai dos ticks da partida: jogo novo começa no dia 1, em day_start_hour
	GameClock.clock.tick_count = simulation.world.tick
	GameClock.clock.extra_hours = 0.0
	if not load_slot_on_start.is_empty():
		load_game(load_slot_on_start)
		load_slot_on_start = ""


## Céu e luzes seguem a hora do GameClock, lisa entre os ticks.
func _process(_delta: float) -> void:
	var hour := GameClock.clock.hour()
	sky.set_hour(hour)
	night_light = DayClock.night_factor(_config, hour)
	RenderingServer.global_shader_parameter_set(&"night_light", night_light)


func _exit_tree() -> void:
	if GameClock.ticked.is_connected(simulation.tick):
		GameClock.ticked.disconnect(simulation.tick)


## O chão do mundo atual: a ilha plana de antes ou o terreno, a água e as árvores do arquipélago.
## Refeito ao carregar um save de outro mundo.
func _build_ground() -> void:
	for node: Node in [_ground, terrain_view, water_view, tree_view]:
		if node != null:
			node.queue_free()
	_ground = null
	terrain_view = null
	water_view = null
	tree_view = null
	var world := simulation.world
	if world.terrain_version == 0:
		var island := FlatIsland.new()
		island.setup(Vector2(world.island(Simulation.MAIN_ISLAND).size) * _config.cell_size_m)
		add_child(island)
		_ground = island
		return
	terrain_view = TerrainView.new()
	add_child(terrain_view)
	terrain_view.setup(world, _config, simulation.data)
	water_view = WaterView.new()
	add_child(water_view)
	water_view.setup(simulation)
	tree_view = TreeView.new()
	add_child(tree_view)
	tree_view.setup(world)


## Área que a câmera alcança: todas as ilhas.
func world_bounds() -> Rect2:
	var bounds := Rect2()
	for grid: IslandGrid in simulation.world.islands:
		bounds = grid.world_rect() if bounds.size == Vector2.ZERO else bounds.merge(grid.world_rect())
	return bounds


## Jogo novo começa olhando o litoral do entreposto: na ilha plana, a borda norte; no
## arquipélago, o lugar de entreposto mais perto do norte da ilha principal.
func look_at_start() -> void:
	var grid := simulation.world.island(Simulation.MAIN_ISLAND)
	var focus := Vector3(grid.size.x * _config.cell_size_m * 0.5, 0.0, 70.0)
	if not grid.flat:
		var site := SiteFinder.find(simulation, &"trading_post", Simulation.MAIN_ISLAND, Vector2i(grid.size.x / 2, 0))
		if not site.is_empty():
			var origin: Vector2i = site[0]
			var rotation: int = site[1]
			var def := simulation.data.building(&"trading_post")
			focus = grid.rect_world(Footprint.rect(origin, def.size, rotation))
			focus.y = 0.0
	camera.rig.focus = focus
	camera.rig.ground_height = simulation.world.surface_height(focus.x, focus.z)
	camera.apply()


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
	var other_world := world.seed != simulation.world.seed or world.terrain_version != simulation.world.terrain_version
	simulation.world = world
	if other_world:
		_build_ground()
		camera.rig.set_bounds(world_bounds())
	camera.height_at = world.surface_height
	if world.terrain_mismatch:
		push_warning("GameScreen: o terreno deste save saiu diferente nesta plataforma")
	var raw_clock: Variant = state.get("clock")
	if raw_clock is Dictionary:
		var clock_data: Dictionary = raw_clock
		GameClock.clock.load_dict(clock_data)
	# saves antigos podiam ter o relógio adiantado pela tela de abertura; vale o tick da partida
	GameClock.clock.tick_count = world.tick
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
	var ship := simulation.world.ship(tool.selected_ship)
	if ship != null and ship.is_placed():
		camera.rig.center_on(Vector3(ship.position.x, 0.0, ship.position.y))
		return
	var record := simulation.world.building(tool.selected_id)
	if record == null:
		return
	var def := simulation.def_of(record)
	var center := simulation.world.island(record.island_id).rect_world(Footprint.rect(record.origin, def.size, record.rotation))
	camera.rig.center_on(Vector3(center.x, 0.0, center.z))


## Destaque no chão: o alcance do serviço (o que vai ser construído ou o selecionado) e a
## área de campos e pastos da fazenda.
func update_highlight() -> void:
	var world := simulation.world
	var island := tool.island_id
	var grid := world.island(island)
	if tool.mode == BuildTool.Mode.BUILDING and tool.building_def != null:
		var def := tool.building_def
		if def.kind == BuildingDef.Kind.SERVICE or def.is_warehouse():
			var front := Footprint.front_cells(tool.building_origin(), def.size, tool.rotation)
			var radius := _config.logistics_range_cells if def.is_warehouse() else ServiceReach.radius_of(def, _config)
			var reach := ServiceReach.road_cells(grid, front, radius)
			var targets: Array[int] = simulation.derived_state().houses if def.kind == BuildingDef.Kind.SERVICE else simulation.derived_state().production
			var covered := ServiceReach.houses(world, simulation.data, island, reach, targets)
			overlay.show_custom(Highlight.service(world, simulation.data, island, reach, covered))
			return
		if def.modules_required > 0:
			overlay.show_custom(Highlight.area(grid, tool.building_rect().grow(def.module_radius_cells)))
			return
		# terreno pedido pelo prédio: jazida, floresta, litoral ou rio
		var key := "%d/%s" % [island, def.id]
		if not _terrain_highlights.has(key):
			_terrain_highlights[key] = Highlight.terrain(grid, def)
		var terrain := _terrain_highlights[key]
		if terrain != null:
			overlay.show_custom(terrain)
			return
	var selected := world.building(tool.selected_id)
	if tool.mode == BuildTool.Mode.NONE and selected != null:
		var def := simulation.def_of(selected)
		var derived := simulation.derived_state()
		grid = world.island(selected.island_id)
		overlay.set_island(selected.island_id)
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


## Desenvolvimento (só em build de depuração): adianta o relógio do dia em 3 horas. Só a vista
## anda; a economia não.
func advance_day_hours() -> void:
	if OS.is_debug_build():
		GameClock.clock.extra_hours = fposmod(GameClock.clock.extra_hours + 3.0, 24.0)


## Trapaça de desenvolvimento (só em build de depuração): dinheiro e 20 t de cada bem na ilha da
## ferramenta (a que está sob o cursor).
func cheat_resources() -> void:
	if not OS.is_debug_build():
		return
	simulation.world.money += 10000.0
	for good: GoodDef in simulation.data.goods:
		simulation.world.economy(tool.island_id).add(good.id, 20.0, simulation.storage_capacity(tool.island_id))


func _thumbnail() -> Image:
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		return null
	image.resize(THUMBNAIL_SIZE.x, THUMBNAIL_SIZE.y, Image.INTERPOLATE_BILINEAR)
	return image
