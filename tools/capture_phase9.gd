extends Node
## Roteiro de verificação visual da Fase 9 (sem tela, roda no xvfb):
##   tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 60000 res://tools/capture_phase9.tscn -- <pasta>
## A vila de demonstração (ilha plana) com os materiais PBR, de perto com o efeito miniatura e de
## longe; a hora dourada; chuva com o chão molhado; neblina de manhã; fumaça das fábricas; os quatro
## níveis gráficos no mesmo enquadramento; e o arquipélago com nuvens, navios, rastro e gaivotas.

const SEED := 1840

var _out_dir: String
var _game: GameScreen
var _sim: Simulation


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	GameScreen.load_slot_on_start = ""
	GameScreen.use_sky3d = OS.get_environment("CAPTURA_SKY3D") == "1"
	Settings.edge_pan = false
	_run.call_deferred()


func _run() -> void:
	var only := OS.get_environment("CAPTURA_SO")
	await _village(only)
	get_tree().quit()


func _village(only: String) -> void:
	var level := OS.get_environment("CAPTURA_NIVEL")
	_set_preset(int(level) if not level.is_empty() else 2)
	GameScreen.flat_world = true
	GameScreen.world_seed = SEED
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	_sim = _game.simulation
	GameClock.set_speed(TickClock.PAUSED)
	await get_tree().process_frame
	# depuração: CAPTURA_DESLIGA=nuvens,ssil,neblina,foco desliga o efeito no nível escolhido
	var off := OS.get_environment("CAPTURA_DESLIGA")
	if off.contains("nuvens"):
		_game.clouds.set_enabled(false)
	var environment := _game.sky.environment()
	environment.ssil_enabled = environment.ssil_enabled and not off.contains("ssil")
	environment.volumetric_fog_enabled = environment.volumetric_fog_enabled and not off.contains("neblina")
	var ids := DemoVillage.build(_sim)
	_sim.free_build = true
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(0, 6), Vector2i(60, 6)), true))
	_sim.run_ticks(_sim.config.ticks_per_second * 60 * 10)
	GameClock.clock.tick_count = _sim.world.tick
	# a vila ocupa as células x 60 a 150, y 0 a 35; uma olaria a mais solta a fumaça pesada
	var center := Vector3(200.0, 0.0, 40.0)
	_sim.execute(PlaceBuildingCommand.new(0, &"brickworks", Vector2i(126, 23), 2))
	var houses: Array[int] = ids["houses"]
	var close := _focus_of(houses[2])
	var weather := _game.weather
	weather.hours_override = _clear_day_hour(11.0)
	_set_hour(11.0)
	await _shot("01_vila_de_longe.png", center, 160.0)
	await _shot("02_vila_de_perto_miniatura.png", close, 40.0)
	if only == "rapido":
		return
	weather.hours_override = _clear_day_hour(18.2)
	_set_hour(18.2)
	await _shot("03_hora_dourada.png", center, 90.0)
	weather.hours_override = _rain_hour()
	_set_hour(fposmod(weather.hours_override, 24.0))
	await _shot("04_chuva.png", close, 60.0)
	weather.hours_override = _mist_hour()
	_set_hour(fposmod(weather.hours_override, 24.0))
	await _shot("05_neblina_da_manha.png", center, 120.0)
	weather.hours_override = _clear_day_hour(14.0)
	_set_hour(14.0)
	for building_id: int in _sim.world.buildings:
		_sim.world.building(building_id).state = BuildingRecord.State.PRODUCING
	_game.smoke_view.refresh()
	for frame: int in 90:
		await get_tree().process_frame
	var bakery: int = ids["bakery"]
	await _shot("06_fumaca_das_fabricas.png", _focus_of(bakery) + Vector3(20, 0, 10), 75.0)
	EventBus.house_upgraded.emit(houses[2])
	for frame: int in 20:
		await get_tree().process_frame
	await _shot("06b_andaime_da_mudanca_de_classe.png", close, 35.0)
	for index: int in 4:
		_set_preset(index)
		await _shot("07_nivel_%d_%s.png" % [index, Settings.preset().id], center, 90.0)
	_set_preset(2)
	remove_child(_game)
	_game.queue_free()
	await get_tree().process_frame
	await _archipelago()


## Navios no arquipélago da semente: casco, velas, rastro e as gaivotas do porto.
func _archipelago() -> void:
	GameScreen.flat_world = false
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	_sim = _game.simulation
	GameClock.set_speed(TickClock.PAUSED)
	await get_tree().process_frame
	var ids := TradeDemo.build(_sim)
	for i: int in _sim.config.ticks_per_second * 60 * 3:
		_sim.tick(0)
	_game.weather.hours_override = _clear_day_hour(16.0)
	_set_hour(16.0)
	var ship_id: int = ids["ship"]
	var ship: Ship = _sim.world.ship(ship_id)
	for frame: int in 60:
		await get_tree().process_frame
	await _shot("08_navio_rastro.png", Vector3(ship.position.x, 0, ship.position.y), 55.0)
	var port := _sim.world.island(0).rect_world(Footprint.rect(_sim.world.building(_first_berth()).origin, Vector2i(6, 6), 0))
	await _shot("09_porto_gaivotas.png", port, 60.0)


func _first_berth() -> int:
	for building_id: int in _sim.world.building_ids():
		if _sim.def_of(_sim.world.building(building_id)).is_berth():
			return building_id
	return 0


func _set_preset(index: int) -> void:
	Settings.set_graphics_preset(index)
	Settings.apply()


## Uma hora (total, em horas de jogo) num dia de céu limpo, sem neblina e sem chão molhado.
func _clear_day_hour(hour: float) -> float:
	for day: int in 200:
		var total := day * 24.0 + hour
		var sample := WeatherCycle.sample(_sim.world.seed, total, _sim.config)
		if sample.kind == WeatherCycle.Kind.CLEAR and sample.mist <= 0.01 and sample.wetness <= 0.01:
			return total
	return hour


## O meio da primeira chuva forte.
func _rain_hour() -> float:
	for day: int in 200:
		var today := WeatherCycle.day(_sim.world.seed, day, _sim.config)
		if today.kind == WeatherCycle.Kind.RAIN:
			return day * 24.0 + (today.rain_start + today.rain_end) * 0.5
	return 12.0


func _mist_hour() -> float:
	for day: int in 200:
		if WeatherCycle.day(_sim.world.seed, day, _sim.config).mist > 0.7:
			return day * 24.0 + _sim.config.weather_mist_peak_hour
	return 6.5


func _focus_of(building_id: int) -> Vector3:
	var record := _sim.world.building(building_id)
	return _sim.world.island(record.island_id).rect_world(Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation))


func _shot(file_name: String, focus: Vector3, distance: float) -> void:
	var rig := _game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.ground_height = _sim.world.surface_height(focus.x, focus.z)
	_game.camera.apply()
	_game.weather.refresh()
	await _save(file_name)


func _save(file_name: String) -> void:
	for frame: int in 16:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
