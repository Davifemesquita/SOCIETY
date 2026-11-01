extends Node
## Roteiro de verificação visual da Fase 198 (bancos no cais): na semente 1840, o entreposto da ilha principal (achado pelo
## SiteFinder) com os bancos no cais de pedra, vistos do lado do mar e por trás, de perto e de meia distância. Precisa de GPU;
## no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase198.tscn -- <pasta>

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
	var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(game)
	GameClock.set_speed(TickClock.PAUSED)
	_set_hour(10.0)
	game.hud.visible = false
	var sim := game.simulation
	var grid := sim.world.island(Simulation.MAIN_ISLAND)
	sim.free_build = true
	var found := SiteFinder.find(sim, &"trading_post", Simulation.MAIN_ISLAND, grid.size / 2)
	if not found.is_empty():
		var origin: Vector2i = found[0]
		var rotation: int = found[1]
		sim.execute(PlaceBuildingCommand.new(0, &"trading_post", origin, rotation))
	await get_tree().process_frame
	game.quay_bench_view.rebuild()
	print("bancos: ", game.quay_bench_view.bench_count())
	var shot := 0
	for place: Transform3D in game.quay_bench_view.places:
		# do mar (a frente do banco) e de trás (o banco olhando o mar)
		await _shot(game, "banco_%d_do_mar.png" % shot, place.origin, 8.0, atan2(-place.basis.z.x, -place.basis.z.z) + 0.5)
		await _shot(game, "banco_%d_de_tras.png" % shot, place.origin, 8.0, atan2(place.basis.z.x, place.basis.z.z) + 0.4)
		shot += 1
		if shot >= 2:
			break
	if not game.quay_bench_view.places.is_empty():
		var first := game.quay_bench_view.places[0]
		await _shot(game, "bancos_longe.png", first.origin, 24.0, atan2(-first.basis.z.x, -first.basis.z.z) - 0.3)
	get_tree().quit()


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.target_distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = maxf(game.simulation.world.surface_height(focus.x, focus.z), 0.0)
	game.camera.apply()
	for frame: int in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
