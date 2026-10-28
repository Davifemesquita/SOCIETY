extends Node
## Roteiro de verificação visual da Fase 70 (ferrovia e petróleo): na semente 1840, os dois campos de petróleo da ilha
## principal — um livre (a mancha escura) e um com o poço, ligado por trilho até uma usina a petróleo. Precisa de GPU;
## no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase70.tscn -- <pasta>

const SEED := 1840

var _out_dir: String


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_run.call_deferred()


func _run() -> void:
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = false
	GameScreen.world_seed = SEED
	GameScreen.terrain_version = ArchipelagoGenerator.VERSION_V3
	var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(game)
	GameClock.set_speed(TickClock.PAUSED)
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(11.0 - clock.hour(), 24.0)
	game.hud.visible = false
	var sim := game.simulation
	sim.free_build = true
	sim.ignore_terrain = true
	var grid := sim.world.island(Simulation.MAIN_ISLAND)
	print("campos ", grid.oil_spots)
	if grid.oil_spots.size() < 2:
		get_tree().quit()
		return
	var free_spot := grid.cell_at(grid.oil_spots[1])
	await _shot(game, "campo_livre.png", grid.cell_world(free_spot), 45.0, 2.4)
	var spot := grid.cell_at(grid.oil_spots[0])
	var well := sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"oil_well", spot - Vector2i.ONE, 0))
	print("poço ", well.ok(), " ", well.reason)
	# a usina num lugar válido perto do poço (com o terreno de verdade) e o trilho em L entre os dois
	sim.ignore_terrain = false
	var site := SiteFinder.find(sim, &"oil_power_station", Simulation.MAIN_ISLAND, spot + Vector2i(10, 0))
	if site.is_empty():
		print("sem lugar para a usina")
		get_tree().quit()
		return
	var station_origin: Vector2i = site[0]
	var station_rotation: int = site[1]
	var station := sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"oil_power_station", station_origin, station_rotation))
	print("usina ", station.ok(), " ", station.reason, " em ", station_origin)
	var station_rect := Footprint.rect(station_origin, Vector2i(5, 5), station_rotation)
	var from := spot + Vector2i(0, 2)
	var to := Vector2i(station_rect.position.x + 2, station_rect.end.y)
	sim.ignore_terrain = true
	var rail := sim.execute(BuildRailCommand.new(Simulation.MAIN_ISLAND, RoadPath.l_path(from, to)))
	print("trilho ", rail.ok(), " ", rail.reason)
	var focus := grid.cell_world((spot + to) / 2)
	await _shot(game, "poco_trilho_usina.png", focus, 60.0, 0.5)
	await _shot(game, "trilho_perto.png", grid.cell_world(from + (to - from) / 3), 14.0, 1.2)
	GameScreen.terrain_version = -1
	get_tree().quit()


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = maxf(game.simulation.world.surface_height(focus.x, focus.z), 0.0)
	game.camera.apply()
	for frame: int in 25:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)
