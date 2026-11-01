extends Node
## Roteiro de verificação visual da Fase 186 (estacas na água): na semente 1840, o entreposto da ilha principal (achado pelo
## SiteFinder) com os feixes de estacas diante dele, de perto e de meia distância, do lado da terra para o mar. Precisa de GPU;
## no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase186.tscn -- <pasta>

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
	game.mooring_pile_view.rebuild()
	print("feixes de estacas: ", game.mooring_pile_view.cluster_count())
	var shot := 0
	for place: Transform3D in game.mooring_pile_view.places:
		await _shot(game, "estacas_%d.png" % shot, place.origin, 11.0, 0.4 + shot * 2.1)
		shot += 1
	if not game.mooring_pile_view.places.is_empty():
		await _shot(game, "estacas_longe.png", game.mooring_pile_view.places[0].origin, 40.0, 0.9)
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
