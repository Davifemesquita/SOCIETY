extends Node
## Roteiro de verificação visual dos prédios de modelo (sem tela, roda no xvfb):
##   tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 9000 res://tools/capture_buildings.tscn -- <pasta>
## Na ilha plana: uma fileira de casas de cada classe nas quatro rotações e todos os outros prédios
## (menos campo, pasto e píer) lado a lado; capturas de longe, de perto e à noite.
## CAPTURA_SO=casas tira só as casas.

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
