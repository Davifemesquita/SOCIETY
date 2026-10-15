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
## Tamanho do arquipélago e dificuldade do jogo novo (−1 = os padrões do GameConfig), escolhidos na
## tela de jogo novo.
static var archipelago_size: int = -1
static var difficulty: int = -1
## Eventos e encomendas (Fase 11) no jogo novo do arquipélago; a ilha plana dos testes fica sem.
static var events_enabled: bool = true
## Ilha plana de antes da Fase 5 em vez do arquipélago: os testes de interface conhecem as
## coordenadas dela.
static var flat_world: bool = false

const QUICK_SLOT := "rapido"
const MAIN_MENU := "res://ui/screens/boot_screen.tscn"
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
## Nível gráfico aplicado ao ambiente, à câmera e aos efeitos (Fase 9).
var graphics: GraphicsQuality
var clouds: CloudsAdapter
var weather: WeatherView
var smoke_view: SmokeView
## Áudio (Fase 10): música adaptativa, ambiente por zona e efeitos.
var music: MusicDirector
var ambience: AmbiencePlayer
var sound: SoundEffects
var autosave: Autosave
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
## Camada da interface (onde abrem as janelas dos menus).
var _ui_layer: CanvasLayer
## Velocidade de antes do menu da partida (o menu pausa).
var _speed_before_menu: int = TickClock.PAUSED


func _ready() -> void:
	_config = GameConfig.get_default()
	var data := GameData.get_default()
	if flat_world:
		simulation = Simulation.new(_config, data)
		if difficulty >= 0:
			simulation.world.difficulty = difficulty
			simulation.world.money = _config.starting_money_for(difficulty)
	else:
		var seed_value := world_seed if world_seed >= 0 else randi() % 1_000_000
		simulation = Simulation.new(_config, data, ArchipelagoGenerator.new_world(seed_value, _config, data, archipelago_size, difficulty))
		simulation.world.events_state.enabled = events_enabled
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
	graphics = GraphicsQuality.new()
	graphics.name = "GraphicsQuality"
	add_child(graphics)
	graphics.setup(_config, sky, camera, pedestrian_view.crowd, window_view)
	clouds = CloudsAdapter.new()
	clouds.name = "Clouds"
	add_child(clouds)
	clouds.setup(sky.sun(), sky.environment())
	graphics.add_effect(clouds)
	weather = WeatherView.new()
	weather.name = "Weather"
	add_child(weather)
	weather.setup(_config, simulation, sky, clouds, camera)
	graphics.add_effect(weather)
	graphics.add_effect(building_view)
	smoke_view = SmokeView.new()
	smoke_view.name = "Smoke"
	add_child(smoke_view)
	smoke_view.setup(simulation, _config.cell_size_m)
	graphics.add_effect(smoke_view)
	graphics.add_effect(ship_view)
	music = MusicDirector.new()
	music.name = "Music"
	add_child(music)
	music.setup(_config, simulation)
	ambience = AmbiencePlayer.new()
	ambience.name = "Ambience"
	add_child(ambience)
	ambience.setup(_config, simulation, camera, weather)
	sound = SoundEffects.new()
	sound.name = "Sound"
	add_child(sound)
	sound.setup(_config, simulation, camera)
	autosave = Autosave.new()
	autosave.name = "Autosave"
	add_child(autosave)
	autosave.setup(self, _config)
	tool = BuildTool.new()
	tool.setup(simulation, camera, _config.cell_size_m)
	add_child(tool)
	tool.refused.connect(func(_reason: StringName) -> void: sound.play(&"error"))
	# depois da ferramenta: recebe o clique antes dela (navio e destino no mar)
	ship_picker = ShipPicker.new()
	ship_picker.setup(simulation, tool, camera, ship_view)
	add_child(ship_picker)
	var preview := BuildPreviewView.new()
	preview.setup(tool, _config.cell_size_m)
	add_child(preview)
	_ui_layer = CanvasLayer.new()
	_ui_layer.name = "Interface"
	add_child(_ui_layer)
	hud = Hud.new()
	_ui_layer.add_child(hud)
	hud.setup(tool, simulation)
	hud.save_requested.connect(open_save_dialog)
	hud.load_requested.connect(open_load_dialog)
	hud.menu_requested.connect(open_menu)
	hud.overlay_changed.connect(func(_layer: MapOverlays.Layer) -> void: update_highlight())
	hud.notifications.go_to.connect(go_to)
	hud.selection_panel.center_requested.connect(center_on_selected)
	hud.ship_panel.center_requested.connect(center_on_selected)
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
	EventBus.building_removed.connect(func(_id: int) -> void: update_highlight())
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
	tree_view.setup(world, simulation.data)


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


func save_game(slot: String, display_name: String = "", saved_key: String = "MSG_SAVED") -> bool:
	var world := simulation.world
	var population := 0
	for tier: TierDef in simulation.data.tiers:
		population += world.population(tier.id)
	var info := {"name": display_name, "day": GameClock.clock.day_number(), "population": population,
			"money": world.money, "seed": world.seed}
	var ok := SaveSystem.save_game(slot, game_state(), _thumbnail(), info) == OK
	hud.show_message(tr(saved_key) if ok else tr("MSG_SAVE_FAILED"))
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


## Há uma janela de menu aberta (os atalhos da partida param).
func modal_open() -> bool:
	for child: Node in _ui_layer.get_children():
		if child is Modal:
			return true
	return false


## Menu da partida: pausa enquanto está aberto e volta à velocidade de antes ao fechar.
func open_menu() -> GameMenu:
	var menu := GameMenu.new()
	_speed_before_menu = GameClock.clock.speed_index
	GameClock.set_speed(TickClock.PAUSED)
	var modal := Modal.open(_ui_layer, menu)
	modal.closed.connect(func() -> void:
		if not modal_open_except(modal):
			GameClock.set_speed(_speed_before_menu))
	menu.save_requested.connect(open_save_dialog)
	menu.load_requested.connect(open_load_dialog)
	menu.options_requested.connect(func() -> void: Modal.open(_ui_layer, OptionsDialog.new()))
	menu.main_menu_requested.connect(func() -> void: get_tree().change_scene_to_file.call_deferred(MAIN_MENU))
	menu.quit_requested.connect(func() -> void: get_tree().quit())
	return menu


func modal_open_except(modal: Modal) -> bool:
	for child: Node in _ui_layer.get_children():
		if child is Modal and child != modal and not child.is_queued_for_deletion():
			return true
	return false


func open_save_dialog() -> SaveLoadDialog:
	var dialog := SaveLoadDialog.new(SaveLoadDialog.Mode.SAVE)
	var modal := Modal.open(_ui_layer, dialog)
	dialog.save_chosen.connect(func(slot: String, display_name: String) -> void:
		if save_game(slot, display_name):
			modal.close())
	return dialog


func open_load_dialog() -> SaveLoadDialog:
	var dialog := SaveLoadDialog.new(SaveLoadDialog.Mode.LOAD)
	var modal := Modal.open(_ui_layer, dialog)
	dialog.load_chosen.connect(func(slot: String) -> void:
		if load_game(slot):
			_close_all_modals())
	return dialog


func _close_all_modals() -> void:
	for child: Node in _ui_layer.get_children():
		if child is Modal:
			var modal: Modal = child
			modal.close()


## Clique numa notificação: seleciona e leva a câmera ao prédio, ao navio ou à ilha dela.
func go_to(notice: NoticeWatcher.Notice) -> void:
	if notice.opens_missions:
		hud.mission_window.open()
		return
	var ship := simulation.world.ship(notice.ship_id)
	if ship != null:
		tool.select_ship(ship.id)
		center_on_selected()
		return
	if simulation.world.building(notice.building_id) != null:
		tool.select(notice.building_id)
		center_on_selected()
		return
	var grid := simulation.world.island(notice.island_id)
	if grid != null:
		var center := grid.world_rect().get_center()
		camera.rig.center_on(Vector3(center.x, 0.0, center.y))


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
	if tool.mode in [BuildTool.Mode.BUILDING, BuildTool.Mode.MOVE] and tool.building_def != null:
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
	# camada de mapa escolhida pelo jogador, na ilha sob o cursor
	if hud != null and hud.overlay_layer != MapOverlays.Layer.NONE:
		overlay.set_island(island)
		overlay.show_custom(MapOverlays.image(hud.overlay_layer, simulation, island))
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
