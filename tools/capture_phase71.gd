extends Node
## Roteiro de verificação visual da Fase 71 (o trem no trilho): no mundo plano, um poço num campo de petróleo posto à mão
## ligado por trilho em L até uma usina a petróleo, e o trem parado no poço, andando na curva e de longe. Precisa de GPU;
## no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase71.tscn -- <pasta>

const SPOT := Vector2i(40, 60)
const STATION := Vector2i(56, 59)

var _out_dir: String


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_run.call_deferred()


func _run() -> void:
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = true
	var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(game)
	GameClock.set_speed(TickClock.PAUSED)
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(11.0 - clock.hour(), 24.0)
	game.hud.visible = false
	var sim := game.simulation
	sim.free_build = true
	var grid := sim.world.island(Simulation.MAIN_ISLAND)
	grid.oil_spots = PackedInt32Array([grid.index(SPOT)])
	var well := sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"oil_well", SPOT - Vector2i.ONE, 0))
	var station := sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"oil_power_station", STATION, 0))
	print("poço ", well.ok(), " ", well.reason, " usina ", station.ok(), " ", station.reason)
	# do lado de baixo do poço, descendo e virando até o lado de baixo da usina
	var cells: Array[Vector2i] = []
	for y: int in range(SPOT.y + 2, STATION.y + 6):
		cells.append(Vector2i(SPOT.x, y))
	for x: int in range(SPOT.x + 1, STATION.x + 3):
		cells.append(Vector2i(x, STATION.y + 5))
	var rail := sim.execute(BuildRailCommand.new(Simulation.MAIN_ISLAND, cells))
	print("trilho ", rail.ok(), " ", rail.reason)
	var trains := game.train_view
	trains.refresh()
	print("trens ", trains.train_count())
	if trains.train_count() == 0:
		get_tree().quit()
		return
	await _shot(game, "trem_no_poco.png", trains.loco_transform(0).origin, 18.0, 0.9)
	trains.advance(TrainView.DWELL_S + 2.2)
	await _shot(game, "trem_na_curva.png", trains.loco_transform(0).origin, 13.0, 2.2)
	trains.advance(4.0)
	await _shot(game, "trem_de_longe.png", trains.loco_transform(0).origin, 50.0, 0.5)
	GameScreen.flat_world = false
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
