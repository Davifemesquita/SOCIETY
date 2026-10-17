extends Node
## Roteiro de verificação visual dos prédios de modelo (sem tela, roda no xvfb):
##   tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 9000 res://tools/capture_buildings.tscn -- <pasta>
## Na ilha plana: uma fileira de casas de cada classe nas quatro rotações e todos os outros prédios
## (menos campo, pasto e píer) lado a lado; capturas de longe, de perto e à noite.
## CAPTURA_SO=casas tira só as casas; silhuetas, só os prédios com silhueta de cadeia (Fase 13); postes,
## a rua calçada com postes e as fogueiras atrás das casas, à noite (Fase 13); detalhes, uma casa de cada
## classe vista de frente (quintal, floreiras, sacadas e pórtico, Fase 13); plantacoes, uma fazenda de cada
## planta com os campos em três pontos do ciclo e os estorninhos sobre eles (Fase 14). Os pombos na rua saem
## em postes (Fase 14), e os varais e vasos das casas (Fase 15); decoracao, as peças de decoração entre as
## casas (Fase 16); diagonal, estradas em diagonal de terra e de paralelepípedo (Fase 17).

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
	if OS.get_environment("CAPTURA_SO") == "plantacoes":
		await _crops()
		get_tree().quit()
		return
	if OS.get_environment("CAPTURA_SO") == "detalhes":
		await _house_trims()
		get_tree().quit()
		return
	if OS.get_environment("CAPTURA_SO") == "diagonal":
		await _diagonals()
		get_tree().quit()
		return
	if OS.get_environment("CAPTURA_SO") == "decoracao":
		await _decorations()
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
	# estrada de terra com uma curva e um cruzamento (sulcos de roda, Fase 14)
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(20, 44), Vector2i(60, 44))))
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(40, 44), Vector2i(40, 49))))
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(60, 44), Vector2i(60, 40))))
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
	await _shot("26_estrada_de_terra.png", Vector3(90.0, 0.0, 90.0), 24.0, 0.4, 0.6)
	await _shot("27_meio_fio.png", Vector3(70.0, 0.0, 101.0), 12.0, PI + 0.4, 0.3)
	# pombos: o jogo está pausado, então o relógio deles anda à mão até haver bando no ar (Fase 14)
	_game.bird_view.rebuild()
	print("pássaros ", _game.bird_view.bird_count())
	var flock := _game.bird_view.flock_center(0)
	await _shot("28_pombos.png", Vector3(flock.x, 0.0, flock.z), 6.0, PI + 0.3, 0.45)
	# o mesmo bando no meio do voo
	while BirdView.pigeon_flight(0.0, _game.bird_view.time()) < 0.4:
		_game.bird_view.advance(0.25)
	await _shot("28b_pombos_voando.png", Vector3(flock.x, 0.0, flock.z), 12.0, PI + 0.3, 0.3)
	# varais atrás e vasos na porta (Fase 15); uma casa em três vira de operários (vasos sem o quintal cercado)
	var houses := 0
	for building_id: int in _sim.world.building_ids():
		var record := _sim.world.building(building_id)
		if record.is_house():
			if houses % 3 == 2:
				record.tier = &"workers"
			houses += 1
	_game.building_view.rebuild()
	_game.yard_view.rebuild()
	print("varais ", _game.yard_view.clothesline_count(), " vasos ", _game.yard_view.pot_count())
	await _shot("30_varais.png", Vector3(100.0, 0.0, 110.0), 18.0, 0.3, 0.45)
	await _shot("31_vasos.png", Vector3(92.0, 0.0, 100.0), 11.0, PI + 0.3, 0.35)
	_set_hour(22.0)
	_game.window_view.refresh_lit()
	await _shot("15_postes_noite.png", Vector3(100.0, 0.0, 104.0), 34.0, PI + 0.3, 0.45)
	await _shot("16_fogueiras_noite.png", Vector3(100.0, 0.0, 110.0), 30.0, 0.3, 0.5)


## Fase 13: uma casa de cada classe lado a lado (rotação 0, frente em −Z), vistas de frente.
func _house_trims() -> void:
	var tiers: Array[StringName] = [&"peasants", &"workers", &"artisans", &"engineers", &"investors"]
	for i: int in tiers.size():
		var house := _place(&"house", Vector2i(40 + i * 5, 100), 0)
		if house != 0:
			_sim.world.building(house).tier = tiers[i]
			_sim.world.building(house).residents = 10.0
	_game.building_view.rebuild()
	_game.window_view.rebuild()
	await _shot("17_casas_de_frente.png", Vector3(105.0, 4.0, 202.0), 46.0, PI + 0.35, 0.3)
	await _shot("18_quintal.png", Vector3(83.0, 1.0, 201.0), 14.0, PI + 0.5, 0.35)
	await _shot("19_floreiras_e_sacadas.png", Vector3(108.0, 5.0, 201.0), 22.0, PI + 0.3, 0.2)
	await _shot("20_portico.png", Vector3(123.0, 3.0, 201.0), 18.0, PI + 0.3, 0.15)


## Fase 14: cada fazenda de campo com os campos dela, em três pontos do ciclo (começo, meio e colheita).
func _crops() -> void:
	var farms: Array[StringName] = [&"sheep_farm", &"wheat_farm", &"potato_farm", &"hop_farm", &"vineyard", &"sugar_cane_farm",
			&"coffee_plantation", &"tobacco_plantation"]
	var growths: Array[float] = [0.1, 0.5, 0.95]
	for i: int in farms.size():
		var def := _sim.data.building(farms[i])
		var origin := Vector2i(30 + i * 22, 140)
		var farm := _place(farms[i], origin, 0)
		var reach := Footprint.rect(origin, def.size, 0).grow(def.module_radius_cells)
		var placed := 0
		for y: int in range(origin.y - 3, reach.end.y - 2, 3):
			for x: int in range(reach.position.x, reach.end.x - 2, 3):
				if placed < def.modules_required and _place(def.module_id, Vector2i(x, y), 0) != 0:
					placed += 1
		if farm != 0:
			_sim.world.building(farm).progress = growths[i % growths.size()]
	_game.building_view.rebuild()
	_game.crop_view.rebuild()
	print("plantas ", _game.crop_view.plant_count())
	await _shot("21_plantacoes.png", Vector3(130.0, 0.0, 290.0), 90.0, 0.3, 0.6)
	await _shot("22_trigo_batata.png", Vector3(85.0, 0.0, 286.0), 30.0, 0.4, 0.5)
	await _shot("23_lupulo_parreira.png", Vector3(150.0, 0.0, 286.0), 30.0, 0.4, 0.5)
	await _shot("24_cana_cafe_tabaco.png", Vector3(230.0, 0.0, 286.0), 40.0, 0.4, 0.5)
	await _shot("25_pasto.png", Vector3(66.0, 0.0, 282.0), 26.0, 0.5, 0.5)
	_game.bird_view.rebuild()
	print("estorninhos ", _game.bird_view.flock_count(BirdView.Kind.STARLING))
	await _shot("29_estorninhos.png", Vector3(110.0, 0.0, 286.0), 45.0, 0.4, 0.35)


## Fase 16: uma rua de casas de artesãos com árvores plantadas na calçada de trás, canteiros e bancos.
func _decorations() -> void:
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(20, 50), Vector2i(60, 50)), true))
	for i: int in 8:
		var house := _place(&"house", Vector2i(21 + i * 4, 51), 0)
		if house != 0:
			_sim.world.building(house).tier = &"artisans"
			_sim.world.building(house).residents = 10.0
	for i: int in 10:
		_place(&"planted_tree", Vector2i(20 + i * 4, 48), 0)
		_place(&"flower_bed", Vector2i(22 + i * 4, 48), 0)
		_place(&"park_bench", Vector2i(21 + i * 4, 47), 2)
	# praça com chafariz do outro lado da rua (Fase 16, parte 2)
	_place(&"fountain_square", Vector2i(30, 42), 0)
	# estátua e coreto (Fase 16, parte 3)
	_place(&"statue", Vector2i(36, 43), 0)
	_place(&"bandstand", Vector2i(41, 42), 0)
	_game.building_view.rebuild()
	_game.decoration_view.rebuild()
	print("decorações ", _game.decoration_view.piece_count())
	await _shot("32_decoracao.png", Vector3(70.0, 0.0, 96.0), 26.0, PI + 0.3, 0.45)
	await _shot("33_decoracao_de_perto.png", Vector3(62.0, 0.0, 95.0), 10.0, PI + 0.5, 0.35)
	await _shot("34_chafariz.png", Vector3(62.0, 0.0, 86.0), 14.0, PI + 0.4, 0.4)
	await _shot("35_estatua_e_coreto.png", Vector3(80.0, 0.0, 87.0), 16.0, PI + 0.4, 0.4)
	_game.hud.set_overlay(MapOverlays.Layer.BEAUTY)
	await _shot("36_camada_beleza.png", Vector3(70.0, 0.0, 92.0), 60.0, PI + 0.3, 0.7)


## Fase 17: uma estrada de terra que sai reta e vira diagonal, e uma de paralelepípedo em diagonal com casas.
func _diagonals() -> void:
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(20, 40), Vector2i(30, 40))))
	_sim.execute(BuildRoadCommand.new(0, RoadPath.diagonal_path(Vector2i(31, 41), Vector2i(45, 55))))
	_sim.execute(BuildRoadCommand.new(0, RoadPath.diagonal_path(Vector2i(50, 40), Vector2i(64, 54)), true))
	_sim.execute(BuildRoadCommand.new(0, RoadPath.diagonal_path(Vector2i(50, 40), Vector2i(64, 54))))
	for i: int in 3:
		var house := _place(&"house", Vector2i(54 + i * 4, 37 + i * 4), 0)
		if house != 0:
			_sim.world.building(house).tier = &"workers"
	_game.building_view.rebuild()
	_game.road_view.rebuild()
	print("ladrilhos ", _game.road_view.tile_count(), " meio-fio ", _game.road_view.curb_count())
	await _shot("37_diagonal.png", Vector3(80.0, 0.0, 92.0), 40.0, 0.3, 0.6)
	await _shot("38_diagonal_de_perto.png", Vector3(72.0, 0.0, 96.0), 12.0, 0.6, 0.45)
	await _shot("39_paralelepipedo_diagonal.png", Vector3(114.0, 0.0, 94.0), 12.0, 0.6, 0.45)
