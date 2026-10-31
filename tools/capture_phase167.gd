extends Node
## Roteiro de verificação visual da Fase 167 (capim alto): na semente 1840, o trecho da ilha principal com mais
## touceiras de capim alto, de perto, a meia distância e de longe, às 10h. Precisa de GPU; no PC do dono roda na área de
## trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase167.tscn -- <pasta>

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
	var focus := _densest(game)
	print("capim alto em ", focus)
	await _shot(game, "capim_alto_de_perto.png", focus, 12.0, 0.7)
	await _shot(game, "capim_alto.png", focus, 35.0, 0.4)
	await _shot(game, "capim_alto_de_longe.png", focus, 130.0, 0.4)
	get_tree().quit()


## A touceira mais perto do meio das touceiras do trecho da ilha principal que tem mais delas.
func _densest(game: GameScreen) -> Vector3:
	var simulation := game.simulation
	var grid := simulation.world.island(Simulation.MAIN_ISLAND)
	var best: Array = []
	for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
		for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
			var items := ScatterView.places(simulation.world, simulation.data, simulation.config, Simulation.MAIN_ISLAND,
					Vector2i(cx, cy))
			var clumps: Array = items[ScatterView.Kind.TALL_GRASS]
			if clumps.size() > best.size():
				best = clumps
	var sum := Vector3.ZERO
	for item: Array in best:
		var place: Transform3D = item[0]
		sum += place.origin
	# a touceira mais perto do meio delas (o meio pode cair entre duas manchas)
	var middle := sum / maxf(best.size(), 1.0)
	var nearest := middle
	for item: Array in best:
		var place: Transform3D = item[0]
		if place.origin.distance_to(middle) < nearest.distance_to(middle) or nearest == middle:
			nearest = place.origin
	return nearest


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
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
