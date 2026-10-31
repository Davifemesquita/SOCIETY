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
## Companhias rivais (Fase 11) no jogo novo do arquipélago; a ilha plana dos testes fica sem.
static var rivals_enabled: bool = true
## Incêndio e doença no jogo novo (caixa do diálogo; ligados por padrão).
static var risks_enabled: bool = true
## Objetivo do jogo novo (Fase 12): GoalDef.Kind (−1 = partida livre), alvo, quantidade e prazo em
## minutos (0 = sem prazo); o cenário de onde veio (vazio = jogo novo comum) e o dinheiro inicial dele
## (0 = o da dificuldade).
static var victory_kind: int = -1
static var victory_target: StringName = &""
static var victory_amount: int = 0
static var victory_deadline_min: float = 0.0
static var scenario_id: StringName = &""
static var starting_money: int = 0
## Ilha plana de antes da Fase 5 em vez do arquipélago: os testes de interface conhecem as
## coordenadas dela.
static var flat_world: bool = false
## Fase 42: o arquipélago já gerado atrás da cortina (ArchipelagoJob, pelo menu); usado uma vez e esquecido. Sem ele (testes,
## ferramentas, benchmark), a partida gera o mundo aqui, de forma síncrona, como antes.
static var prepared_world: WorldState = null
## Fase 45: o gerador do jogo novo (-1: o do GameConfig; 1 ou 2, a escolha do diálogo).
static var terrain_version: int = -1

const QUICK_SLOT := "rapido"
const MAIN_MENU := "res://ui/screens/boot_screen.tscn"
const THUMBNAIL_SIZE := Vector2i(320, 180)
const ACHIEVEMENT_CHECK_SECONDS := 2.0

var simulation: Simulation
var camera: StrategyCamera
var tool: BuildTool
var hud: Hud
## Fase 47: interface escondida, hora e inclinação para fotos.
var photo_mode: PhotoMode
## Fase 49: os fantasmas das plantas.
var plan_view: PlanView
var building_view: BuildingView
var road_view: RoadView
var rail_view: RailView
var train_view: TrainView
var cart_view: CartView
var overlay: DebugOverlay
var sky: SkyAdapter
var pedestrian_view: PedestrianView
var window_view: WindowLightsView
var ship_view: ShipView
## Fase 30: moedas e o "+X" sobre o entreposto quando o comerciante paga.
var money_fx_view: MoneyFxView
var rival_view: RivalView
var ship_picker: ShipPicker
## Nível gráfico aplicado ao ambiente, à câmera e aos efeitos (Fase 9).
var graphics: GraphicsQuality
var clouds: CloudsAdapter
var weather: WeatherView
var smoke_view: SmokeView
var stockpile_view: StockpileView
var lamp_view: LampView
var animal_view: AnimalView
var crop_view: CropView
var bird_view: BirdView
## Fase 65: bandeirolas e fogos nas praças da ilha em festa.
var festival_view: FestivalView
var harbor_view: HarborView
var fishing_boat_view: FishingBoatView
var lighthouse_view: LighthouseView
## Fase 115: a carreira dos estaleiros, com o casco em obra.
var shipway_view: ShipwayView
## Fase 116: as mesas e os guarda-sóis em volta das tavernas.
var tavern_garden_view: TavernGardenView
## Fase 117: silos e caixas d'água ao lado das fazendas.
var farm_silo_view: FarmSiloView
## Fase 118: o cocho de cada pasto (as manchas de chão gasto ficam na máscara das estradas).
var pasture_trough_view: PastureTroughView
## Fase 119: as poças de luz no chão à noite, debaixo dos postes, das fogueiras e nas portas das casas.
var light_pool_view: LightPoolView
## Fase 120: os postes e os fios pelas ruas em volta das usinas.
var power_line_view: PowerLineView
## Fase 121: o gavião planando sobre cada cidade.
var hawk_view: HawkView
## Fase 122: matacões no leito dos rios e seixos na margem.
var river_stone_view: RiverStoneView
## Fase 123: o borrifo do mar batendo nos rochedos e nas falésias perto da câmera.
var surf_spray_view: SurfSprayView
## Fase 128: o afloramento e as pedras do minério nas jazidas ainda sem mina.
var deposit_view: DepositView
## Fase 131: as tampas de bueiro nas ruas de paralelepípedo.
var manhole_view: ManholeView
## Fase 132: as bombas d'água junto das casas.
var water_pump_view: WaterPumpView
## Fase 133: as bandeirolas fixas sobre o pátio dos mercados.
var market_bunting_view: MarketBuntingView
## Fase 135: as galinhas no quintal cercado das casas dos camponeses.
var chicken_view: ChickenView
## Fase 136: a vagoneta e o monte de rejeito das minas.
var spoil_tip_view: SpoilTipView
## Fase 137: a boca do forno acesa nas fábricas de forno.
var furnace_glow_view: FurnaceGlowView
## Fase 139: as redes de pesca secando ao lado das cabanas de pesca.
var fish_net_view: FishNetView
## Fase 140: os tocos e as toras da clareira em volta dos lenhadores.
var stump_view: StumpView
## Fase 142: os botes a remo dando voltas diante dos entrepostos.
var rowboat_view: RowboatView
## Fase 144: as boias marcando a entrada diante dos entrepostos.
var buoy_view: BuoyView
## Fase 145: os mostradores do relógio na torre da igreja.
var clock_view: ClockView
## Fase 146: a grade de ferro e os lampiões no cais de pedra.
var quay_rail_view: QuayRailView
## Fase 147: os mastros com flâmulas nas pontas do cais de pedra.
var quay_mast_view: QuayMastView
var forecourt_view: ForecourtView
var avenue_view: AvenueView
var yard_view: YardView
var chimney_smoke_view: ChimneySmokeView
var decoration_view: DecorationView
var fire_view: FireView
## Áudio (Fase 10): música adaptativa, ambiente por zona e efeitos.
var music: MusicDirector
var ambience: AmbiencePlayer
var sound: SoundEffects
## Fase 85: estouros e palmas da festa.
var festival_sounds: FestivalSounds
var autosave: Autosave
## Chão do mundo: a ilha plana (FlatIsland) ou terreno, água e árvores do arquipélago.
var terrain_view: TerrainView
var water_view: WaterView
var tree_view: TreeView
var rock_view: RockView
var scatter_view: ScatterView
## Fase 64: baleias e golfinhos no mar.
var marine_view: MarineLifeView
var _ground: Node3D
## Destaque de terreno por ilha e prédio (percorre a ilha inteira: guardado até árvores caírem).
var _terrain_highlights: Dictionary[String, Image] = {}
## Quanto é noite agora (0 a 1), o mesmo valor do uniforme global night_light.
var night_light: float = 0.0

## Conquistas do jogador conferidas nesta partida (Fase 12).
var achievements: AchievementWatcher
var _achievement_left: float = ACHIEVEMENT_CHECK_SECONDS
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
		var world: WorldState = prepared_world
		prepared_world = null
		if world == null:
			var seed_value := world_seed if world_seed >= 0 else randi() % 1_000_000
			world = ArchipelagoGenerator.new_world(seed_value, _config, data, archipelago_size, difficulty, terrain_version)
		simulation = Simulation.new(_config, data, world)
		simulation.world.events_state.enabled = events_enabled
		simulation.world.risks_state.enabled = risks_enabled
		if starting_money > 0:
			simulation.world.money = starting_money
		if victory_kind >= 0:
			VictorySystem.start(simulation.world, _config, victory_kind, victory_target, victory_amount, victory_deadline_min, scenario_id)
		if rivals_enabled:
			simulation.world.rivals_state.start(data, _config)
	_build_ground()
	sky = SkyAdapter.new()
	add_child(sky)
	sky.setup(_config, use_sky3d)
	road_view = RoadView.new()
	road_view.setup(simulation, _config.cell_size_m)
	add_child(road_view)
	# Fase 70: os trilhos e os campos de petróleo
	rail_view = RailView.new()
	rail_view.name = "Rails"
	add_child(rail_view)
	rail_view.setup(simulation, _config)
	# Fase 71: o trem andando no trilho
	train_view = TrainView.new()
	train_view.name = "Trains"
	add_child(train_view)
	train_view.setup(simulation, _config)
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
	money_fx_view = MoneyFxView.new()
	money_fx_view.name = "MoneyFx"
	add_child(money_fx_view)
	money_fx_view.setup(simulation)
	rival_view = RivalView.new()
	add_child(rival_view)
	rival_view.setup(simulation)
	pedestrian_view = PedestrianView.new()
	pedestrian_view.setup(simulation, _config)
	add_child(pedestrian_view)
	overlay = DebugOverlay.new()
	overlay.setup(simulation, _config.cell_size_m, _config.build_grid_radius_m)
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
	smoke_view.weather = weather
	smoke_view.setup(simulation, _config.cell_size_m)
	graphics.add_effect(smoke_view)
	# Fase 76: a fumaça da locomotiva deita no mesmo vento e segue o nível gráfico
	train_view.weather = weather
	graphics.add_effect(train_view)
	stockpile_view = StockpileView.new()
	stockpile_view.name = "Stockpiles"
	add_child(stockpile_view)
	stockpile_view.setup(simulation, _config.cell_size_m)
	graphics.add_effect(stockpile_view)
	lamp_view = LampView.new()
	lamp_view.name = "Lamps"
	add_child(lamp_view)
	lamp_view.setup(simulation, _config.cell_size_m)
	graphics.add_effect(lamp_view)
	animal_view = AnimalView.new()
	animal_view.name = "Animals"
	add_child(animal_view)
	animal_view.setup(simulation)
	graphics.add_effect(animal_view)
	crop_view = CropView.new()
	crop_view.name = "Crops"
	add_child(crop_view)
	crop_view.setup(simulation)
	graphics.add_effect(crop_view)
	bird_view = BirdView.new()
	bird_view.name = "Birds"
	add_child(bird_view)
	bird_view.setup(simulation)
	graphics.add_effect(bird_view)
	festival_view = FestivalView.new()
	festival_view.name = "Festival"
	add_child(festival_view)
	festival_view.setup(simulation)
	harbor_view = HarborView.new()
	harbor_view.name = "Harbor"
	add_child(harbor_view)
	harbor_view.setup(simulation)
	fishing_boat_view = FishingBoatView.new()
	fishing_boat_view.name = "FishingBoats"
	add_child(fishing_boat_view)
	fishing_boat_view.setup(simulation)
	lighthouse_view = LighthouseView.new()
	lighthouse_view.name = "Lighthouses"
	add_child(lighthouse_view)
	lighthouse_view.setup(simulation)
	shipway_view = ShipwayView.new()
	shipway_view.name = "Shipways"
	add_child(shipway_view)
	shipway_view.setup(simulation)
	tavern_garden_view = TavernGardenView.new()
	tavern_garden_view.name = "TavernGardens"
	add_child(tavern_garden_view)
	tavern_garden_view.setup(simulation)
	farm_silo_view = FarmSiloView.new()
	farm_silo_view.name = "FarmSilos"
	add_child(farm_silo_view)
	farm_silo_view.setup(simulation)
	pasture_trough_view = PastureTroughView.new()
	pasture_trough_view.name = "PastureTroughs"
	add_child(pasture_trough_view)
	pasture_trough_view.setup(simulation)
	light_pool_view = LightPoolView.new()
	light_pool_view.name = "LightPools"
	add_child(light_pool_view)
	light_pool_view.setup(simulation, lamp_view)
	power_line_view = PowerLineView.new()
	power_line_view.name = "PowerLines"
	add_child(power_line_view)
	power_line_view.setup(simulation)
	hawk_view = HawkView.new()
	hawk_view.name = "Hawks"
	add_child(hawk_view)
	hawk_view.setup(simulation)
	river_stone_view = RiverStoneView.new()
	river_stone_view.name = "RiverStones"
	add_child(river_stone_view)
	river_stone_view.setup(simulation)
	surf_spray_view = SurfSprayView.new()
	surf_spray_view.name = "SurfSpray"
	add_child(surf_spray_view)
	surf_spray_view.setup(func() -> PackedVector3Array:
		return rock_view.spray_sites() if rock_view != null else PackedVector3Array(),
		func(x: float, z: float) -> float: return simulation.world.surface_height(x, z))
	graphics.add_effect(surf_spray_view)
	deposit_view = DepositView.new()
	deposit_view.name = "Deposits"
	add_child(deposit_view)
	deposit_view.setup(simulation)
	manhole_view = ManholeView.new()
	manhole_view.name = "Manholes"
	add_child(manhole_view)
	manhole_view.setup(simulation)
	water_pump_view = WaterPumpView.new()
	water_pump_view.name = "WaterPumps"
	add_child(water_pump_view)
	water_pump_view.setup(simulation)
	market_bunting_view = MarketBuntingView.new()
	market_bunting_view.name = "MarketBunting"
	add_child(market_bunting_view)
	market_bunting_view.setup(simulation)
	chicken_view = ChickenView.new()
	chicken_view.name = "Chickens"
	add_child(chicken_view)
	chicken_view.setup(simulation)
	spoil_tip_view = SpoilTipView.new()
	spoil_tip_view.name = "SpoilTips"
	add_child(spoil_tip_view)
	spoil_tip_view.setup(simulation)
	furnace_glow_view = FurnaceGlowView.new()
	furnace_glow_view.name = "FurnaceGlows"
	add_child(furnace_glow_view)
	furnace_glow_view.setup(simulation)
	fish_net_view = FishNetView.new()
	fish_net_view.name = "FishNets"
	add_child(fish_net_view)
	fish_net_view.setup(simulation)
	stump_view = StumpView.new()
	stump_view.name = "Stumps"
	add_child(stump_view)
	stump_view.setup(simulation)
	rowboat_view = RowboatView.new()
	rowboat_view.name = "Rowboats"
	add_child(rowboat_view)
	rowboat_view.setup(simulation)
	buoy_view = BuoyView.new()
	buoy_view.name = "Buoys"
	add_child(buoy_view)
	buoy_view.setup(simulation)
	clock_view = ClockView.new()
	clock_view.name = "Clocks"
	add_child(clock_view)
	clock_view.setup(simulation)
	quay_rail_view = QuayRailView.new()
	quay_rail_view.name = "QuayRails"
	add_child(quay_rail_view)
	quay_rail_view.setup(simulation)
	quay_mast_view = QuayMastView.new()
	quay_mast_view.name = "QuayMasts"
	add_child(quay_mast_view)
	quay_mast_view.setup(simulation)
	forecourt_view = ForecourtView.new()
	forecourt_view.name = "Forecourts"
	add_child(forecourt_view)
	forecourt_view.setup(simulation)
	avenue_view = AvenueView.new()
	avenue_view.name = "Avenues"
	add_child(avenue_view)
	avenue_view.setup(simulation)
	yard_view = YardView.new()
	yard_view.name = "Yards"
	add_child(yard_view)
	yard_view.setup(simulation)
	graphics.add_effect(yard_view)
	chimney_smoke_view = ChimneySmokeView.new()
	chimney_smoke_view.name = "ChimneySmoke"
	add_child(chimney_smoke_view)
	chimney_smoke_view.setup(simulation)
	graphics.add_effect(chimney_smoke_view)
	decoration_view = DecorationView.new()
	decoration_view.name = "Decorations"
	add_child(decoration_view)
	decoration_view.setup(simulation)
	graphics.add_effect(decoration_view)
	fire_view = FireView.new()
	fire_view.name = "Fire"
	add_child(fire_view)
	fire_view.setup(simulation, _config.cell_size_m)
	graphics.add_effect(fire_view)
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
	festival_sounds = FestivalSounds.new()
	festival_sounds.name = "FestivalSounds"
	add_child(festival_sounds)
	festival_sounds.setup(camera, festival_view, pedestrian_view.crowd)
	festival_view.finale_started.connect(_on_finale_started)
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
	preview.setup(tool, _config.cell_size_m, simulation)
	add_child(preview)
	plan_view = PlanView.new()
	plan_view.setup(simulation, _config.cell_size_m)
	add_child(plan_view)
	_ui_layer = CanvasLayer.new()
	_ui_layer.name = "Interface"
	add_child(_ui_layer)
	hud = Hud.new()
	_ui_layer.add_child(hud)
	hud.setup(tool, simulation)
	hud.save_requested.connect(open_save_dialog)
	hud.load_requested.connect(open_load_dialog)
	hud.menu_requested.connect(open_menu)
	hud.overlay_changed.connect(func(layer: MapOverlays.Layer) -> void:
		# Fase 33: com uma camada do mapa ligada, todos os ícones de estado aparecem
		building_view.show_all_icons = layer != MapOverlays.Layer.NONE
		update_highlight())
	hud.notifications.go_to.connect(go_to)
	photo_mode = PhotoMode.new()
	_ui_layer.add_child(photo_mode)
	photo_mode.setup(self)
	hud.selection_panel.center_requested.connect(center_on_selected)
	hud.ship_panel.center_requested.connect(center_on_selected)
	tool.changed.connect(func() -> void:
		overlay.grid_visible = tool.mode != BuildTool.Mode.NONE
		overlay.set_island(tool.island_id)
		overlay.set_focus(tool.grid().cell_world(tool.hover_cell))
		building_view.hovered_id = tool.grid().building_at(tool.hover_cell) if tool.grid().in_bounds(tool.hover_cell) else 0
		update_highlight())
	tool.selection_changed.connect(func(building_id: int) -> void:
		building_view.select(building_id)
		update_highlight())
	EventBus.roads_changed.connect(func(_island_id: int) -> void: update_highlight())
	EventBus.trees_changed.connect(func(_island_id: int, _area: Rect2i) -> void: _terrain_highlights.clear())
	EventBus.world_replaced.connect(func() -> void: _terrain_highlights.clear())
	EventBus.building_placed.connect(func(_id: int) -> void: update_highlight())
	EventBus.building_removed.connect(func(_id: int) -> void: update_highlight())
	EventBus.match_won.connect(open_victory)
	EventBus.match_lost.connect(open_victory)
	achievements = AchievementWatcher.new(simulation, Achievements.shared())
	achievements.connect_events()
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
	# Fase 32: a primeira vez de cada material cai atrás da cortina, não no primeiro prédio da partida
	if WarmUp.enabled():
		var warm := WarmUp.new()
		add_child(warm)
		warm.start(_config, simulation.data, camera.camera)


## Céu e luzes seguem a hora do GameClock, lisa entre os ticks. As conquistas de estado são
## conferidas a cada ACHIEVEMENT_CHECK_SECONDS.
func _process(delta: float) -> void:
	_achievement_left -= delta
	if _achievement_left <= 0.0:
		_achievement_left = ACHIEVEMENT_CHECK_SECONDS
		for def: AchievementDef in achievements.check():
			hud.notifications.push(hud.notifications.watcher.achievement(def))
			EventBus.achievement_unlocked.emit(def.id)
	var hour := GameClock.clock.hour()
	sky.set_hour(hour)
	night_light = DayClock.night_factor(_config, hour)
	RenderingServer.global_shader_parameter_set(&"night_light", night_light)
	# Fase 110: para onde fica o sol (o brilho dele no mar)
	var sun_light := sky.sun()
	if sun_light != null and sun_light.is_inside_tree():
		RenderingServer.global_shader_parameter_set(&"sun_direction", sun_light.global_basis.z.normalized())


func _exit_tree() -> void:
	if GameClock.ticked.is_connected(simulation.tick):
		GameClock.ticked.disconnect(simulation.tick)


## O chão do mundo atual: a ilha plana de antes ou o terreno, a água e as árvores do arquipélago.
## Refeito ao carregar um save de outro mundo.
func _build_ground() -> void:
	for node: Node in [_ground, terrain_view, water_view, tree_view, rock_view, scatter_view, marine_view]:
		if node != null:
			node.queue_free()
	_ground = null
	terrain_view = null
	water_view = null
	marine_view = null
	tree_view = null
	rock_view = null
	scatter_view = null
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
	water_view.setup(simulation, terrain_view.coast_field())
	marine_view = MarineLifeView.new()
	marine_view.name = "MarineLife"
	add_child(marine_view)
	marine_view.setup(terrain_view.coast_field(), world_bounds(), world.seed)
	tree_view = TreeView.new()
	add_child(tree_view)
	tree_view.setup(world, simulation.data, _config)
	# Fase 56: rocha nos rochedos e nas falésias
	rock_view = RockView.new()
	add_child(rock_view)
	rock_view.setup(terrain_view, world, _config)
	# Fase 41: o recheio entre as casas, na beira da mata, da estrada e do mar
	scatter_view = ScatterView.new()
	add_child(scatter_view)
	scatter_view.setup(world, simulation.data, _config, simulation)


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


## Fase 94: com a opção ligada (Opções → Jogo), o grand finale leva a câmera à praça dele (desliza, como o clique num aviso).
func _on_finale_started(site: Vector3) -> void:
	if Settings.finale_camera and not photo_mode.active:
		camera.rig.center_on(site)


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
	menu.main_menu_requested.connect(func() -> void: SceneFader.change_to.call_deferred(MAIN_MENU))
	menu.quit_requested.connect(func() -> void: get_tree().quit())
	# Fase 47: o menu fecha (a velocidade volta) e o modo foto guarda essa velocidade para devolver na saída
	menu.photo_requested.connect(func() -> void:
		modal.close()
		photo_mode.toggle())
	return menu


## Fim da partida com objetivo (Fase 12): pausa e mostra o resumo; continuar fecha e volta à
## velocidade de antes (a partida segue livre); o menu principal sai da partida.
func open_victory() -> VictoryDialog:
	var dialog := VictoryDialog.new(simulation)
	_speed_before_menu = GameClock.clock.speed_index
	GameClock.set_speed(TickClock.PAUSED)
	var modal := Modal.open(_ui_layer, dialog)
	dialog.continue_requested.connect(func() -> void:
		modal.close()
		if not modal_open():
			GameClock.set_speed(_speed_before_menu))
	dialog.menu_requested.connect(func() -> void: SceneFader.change_to.call_deferred(MAIN_MENU))
	return dialog


## Volta o jogo novo ao padrão (partida livre, sem cenário): a tela de abertura chama antes de
## preencher o que o jogador escolheu.
static func reset_new_game() -> void:
	victory_kind = -1
	victory_target = &""
	victory_amount = 0
	victory_deadline_min = 0.0
	scenario_id = &""
	starting_money = 0


## Prepara o jogo novo de um cenário.
static func apply_scenario(def: ScenarioDef) -> void:
	reset_new_game()
	world_seed = def.seed
	archipelago_size = def.archipelago_size
	difficulty = def.difficulty
	starting_money = def.starting_money
	events_enabled = def.events
	rivals_enabled = def.rivals
	risks_enabled = def.risks
	victory_kind = def.victory_kind
	victory_target = def.victory_target
	victory_amount = def.victory_amount
	victory_deadline_min = def.time_limit_min
	scenario_id = def.id


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
	if notice.opens_rivals:
		hud.diplomacy_window.open()
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


## Destaque no chão: o alcance do serviço (o que vai ser construído ou o selecionado), a
## área de campos e pastos da fazenda e o raio de beleza da decoração (Fase 16).
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
			if def.protects == BuildingDef.Hazard.FIRE:
				targets = simulation.derived_state().houses + simulation.derived_state().production
			var covered := ServiceReach.houses(world, simulation.data, island, reach, targets)
			overlay.show_custom(Highlight.service(world, simulation.data, island, reach, covered))
			return
		if def.modules_required > 0:
			overlay.show_custom(Highlight.area(grid, tool.building_rect().grow(def.module_radius_cells)))
			return
		# decoração (Fase 16): o raio da beleza
		if def.is_decoration():
			overlay.show_custom(Highlight.area(grid, tool.building_rect().grow(def.beauty_radius_cells)))
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
			var houses: Array = derived.protected_by.get(selected.id, []) if def.protects != BuildingDef.Hazard.NONE \
					else derived.service_houses.get(selected.id, [])
			overlay.show_custom(Highlight.service(world, simulation.data, selected.island_id, reach, houses))
			return
		if def.modules_required > 0:
			overlay.show_custom(Highlight.area(grid, Footprint.rect(selected.origin, def.size, selected.rotation).grow(def.module_radius_cells)))
			return
		if def.is_decoration():
			overlay.show_custom(Highlight.area(grid, Footprint.rect(selected.origin, def.size, selected.rotation).grow(def.beauty_radius_cells)))
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
