extends Node
## Roteiro de verificação visual da Fase 73 (o cavalo-de-pau do poço de petróleo): no mundo plano, um poço num campo de
## petróleo posto à mão, de frente, de lado e de longe, com o balancim em dois ângulos. Precisa de GPU; no PC do dono
## roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase73.tscn -- <pasta>

const SPOT := Vector2i(40, 60)

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
	var placed := sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"oil_well", SPOT - Vector2i.ONE, 0))
	print("poço ", placed.ok(), " ", placed.reason)
	if not placed.ok():
		get_tree().quit()
		return
	var record := sim.world.building(placed.placed[0])
	record.state = BuildingRecord.State.PRODUCING
	var focus := grid.cell_world(SPOT)
	game.building_view.spin_rotors(1.2)
	await _shot(game, "poco_frente.png", focus, 16.0, 0.35)
	game.building_view.spin_rotors(2.4)
	await _shot(game, "poco_lado.png", focus, 14.0, 1.6)
	await _shot(game, "poco_longe.png", focus, 45.0, 0.8)
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
