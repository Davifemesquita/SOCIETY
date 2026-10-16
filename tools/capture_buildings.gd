extends Node
## Roteiro de verificação visual dos prédios de modelo (sem tela, roda no xvfb):
##   tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 9000 res://tools/capture_buildings.tscn -- <pasta>
## Na ilha plana: uma fileira de casas de cada classe nas quatro rotações e todos os outros prédios
## (menos campo, pasto e píer) lado a lado; capturas de longe, de perto e à noite.
## CAPTURA_SO=casas tira só as casas; silhuetas, só os prédios com silhueta de cadeia (Fase 13); postes,
## a rua calçada com postes e as fogueiras atrás das casas, à noite (Fase 13).

var _out_dir: String
var _game: GameScreen
var _sim: Simulation


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = true
	Settings.edge_pan = false
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	GameClock.set_speed(TickClock.PAUSED)
	_run.call_deferred()


func _run() -> void:
	_sim = _game.simulation
	_sim.free_build = true
	_sim.ignore_terrain = true
	_set_hour(15.0)
	_place(&"trading_post", Vector2i(200, 2), 2)
	if OS.get_environment("CAPTURA_SO") == "silhuetas":
		await _silhouettes()
		get_tree().quit()
		return
	if OS.get_environment("CAPTURA_SO") == "postes":
		await _lamps()
		get_tree().quit()
		return
	var tiers: Array[StringName] = [&"peasants", &"workers", &"artisans", &"engineers", &"investors"]
	for row: int in tiers.size():
		for i: int in 6:
			var house := _place(&"house", Vector2i(20 + i * 4, 20 + row * 5), i % 4)
			if house != 0:
				_sim.world.building(house).tier = tiers[row]
				_sim.world.building(house).residents = 10.0
	_game.building_view.rebuild()
	_game.window_view.rebuild()
	var x := 60
	var y := 20
	var row_depth := 0
	for def: BuildingDef in _sim.data.buildings:
		if def.kind in [BuildingDef.Kind.RESIDENCE, BuildingDef.Kind.MODULE, BuildingDef.Kind.PIER] or def.is_trading_post:
			continue
		if x + def.size.x > 150:
			x = 60
			y += row_depth + 3
			row_depth = 0
		_place(def.id, Vector2i(x, y), 0)
		x += def.size.x + 2
		row_depth = maxi(row_depth, def.size.y)
	await _shot("01_casas.png", Vector3(64.0, 0.0, 66.0), 70.0, 0.6, 0.6)
	await _shot("02_casas_de_perto.png", Vector3(52.0, 0.0, 48.0), 30.0, 0.4, 0.45)
	if OS.get_environment("CAPTURA_SO") == "noite":
		_set_hour(22.0)
		_game.window_view.refresh_lit()
		await _shot("07_noite_de_perto.png", Vector3(48.0, 4.0, 36.0), 22.0, 3.1, 0.25)
		get_tree().quit()
		return
	if OS.get_environment("CAPTURA_SO") == "casas":
		get_tree().quit()
		return
	await _shot("03_predios.png", Vector3(210.0, 0.0, 70.0), 110.0, 0.5, 0.7)
	await _shot("04_predios_de_perto.png", Vector3(160.0, 0.0, 50.0), 45.0, 0.3, 0.45)
	await _shot("05_predios_de_lado.png", Vector3(220.0, 0.0, 90.0), 60.0, 2.6, 0.35)
	_set_hour(22.0)
	_game.window_view.refresh_lit()
	await _shot("06_noite.png", Vector3(60.0, 0.0, 60.0), 45.0, 0.4, 0.45)
	await _shot("07_noite_de_perto.png", Vector3(48.0, 4.0, 36.0), 22.0, 3.1, 0.25)
	get_tree().quit()


func _place(def_id: StringName, origin: Vector2i, rotation: int) -> int:
	var result := _sim.execute(PlaceBuildingCommand.new(0, def_id, origin, rotation))
	return result.placed[0] if result.ok() else 0


func _shot(file_name: String, focus: Vector3, distance: float, yaw: float, pitch: float) -> void:
	var rig := _game.camera.rig
	rig.focus = focus
	rig.distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	if "pitch" in rig:
		rig.set(&"pitch", pitch)
	rig.ground_height = 0.0
	_game.camera.apply()
	for frame: int in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)


## Fase 13: os prédios com silhueta própria numa fileira, produzindo (as partes giradas um pouco).
func _silhouettes() -> void:
	var x := 40
	for def_id: StringName in [&"mill", &"sawmill", &"coal_mine", &"market", &"warehouse", &"furnace", &"tavern", &"brewery", &"clockmaker"]:
		var id := _place(def_id, Vector2i(x, 100), 0)
		if id != 0:
			_sim.world.building(id).state = BuildingRecord.State.PRODUCING
			# estoque de saída cheio: as pilhas (Fase 13, parte 2) aparecem
			_sim.world.building(id).output_buffer = 3.0 + (x % 2)
		x += _sim.data.building(def_id).size.x + 3
	_game.building_view.spin_rotors(0.6)
	_game.stockpile_view.refresh()
	# a frente dos prédios (rotação 0) olha para −Z: a câmera fica do lado de −Z
	await _shot("08_silhuetas.png", Vector3(100.0, 0.0, 196.0), 60.0, PI + 0.25, 0.5)
	await _shot("09_silhuetas_moinho.png", Vector3(88.0, 3.0, 200.0), 30.0, PI + 0.35, 0.3)
	await _shot("10_silhuetas_mercado.png", Vector3(122.0, 2.0, 200.0), 26.0, PI - 0.3, 0.4)
	await _shot("11_silhuetas_fundicao.png", Vector3(152.0, 3.0, 204.0), 34.0, PI + 0.5, 0.45)
	await _shot("12_pilhas.png", Vector3(100.0, 1.0, 196.0), 26.0, PI + 0.15, 0.35)
	await _shot("13_pilhas_cervejaria.png", Vector3(186.0, 1.0, 196.0), 26.0, PI + 0.15, 0.35)


## Fase 13: rua calçada com casas de camponeses de frente para ela (rotação 0, frente em −Z), à noite.
func _lamps() -> void:
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(20, 50), Vector2i(80, 50)), true))
	for i: int in 14:
		var house := _place(&"house", Vector2i(21 + i * 4, 51), 0)
		if house != 0:
			_sim.world.building(house).tier = &"peasants"
			_sim.world.building(house).residents = 5.0
	_game.building_view.rebuild()
	_game.window_view.rebuild()
	_game.lamp_view.rebuild()
	print("postes ", _game.lamp_view.lamp_count(), " fogueiras ", _game.lamp_view.bonfire_count())
	await _shot("14_postes_de_dia.png", Vector3(100.0, 0.0, 104.0), 34.0, PI + 0.3, 0.45)
	_set_hour(22.0)
	_game.window_view.refresh_lit()
	await _shot("15_postes_noite.png", Vector3(100.0, 0.0, 104.0), 34.0, PI + 0.3, 0.45)
	await _shot("16_fogueiras_noite.png", Vector3(100.0, 0.0, 110.0), 30.0, 0.3, 0.5)
