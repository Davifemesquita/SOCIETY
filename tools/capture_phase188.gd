extends Node
## Roteiro de verificação visual da Fase 188 (arco-íris): na semente 1840, o primeiro dia em que a chuva acaba de tarde (o sol
## baixo o bastante para o arco ficar acima do horizonte), a hora presa logo depois dela; a câmera posta à mão no alto, olhando
## para o lado oposto ao sol, e a mesma cena no meio da chuva (sem arco). Precisa de GPU; no PC do dono roda na área de
## trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase188.tscn -- <pasta>

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
	game.hud.visible = false
	var sim := game.simulation
	var day := -1
	var end_hour := 0.0
	for index: int in 120:
		var today := WeatherCycle.day(sim.world.seed, index, sim.config)
		if today.kind == WeatherCycle.Kind.RAIN and today.rain_end >= 15.5 and today.rain_end <= 18.0:
			day = index
			end_hour = today.rain_end
			break
	print("dia de chuva com fim à tarde: ", day, " às ", end_hour)
	if day < 0:
		get_tree().quit()
		return
	var grid := sim.world.island(Simulation.MAIN_ISLAND)
	var eye := grid.cell_world(grid.size / 2) + Vector3(0.0, 45.0, 0.0)
	for pair: Array in [[0.35, "arco_iris"], [-1.0, "na_chuva"]]:
		var after: float = pair[0]
		var label: String = pair[1]
		var hour := end_hour + after
		_set_hour(hour)
		game.weather.hours_override = day * 24.0 + hour
		game.rainbow_view.hours_override = day * 24.0 + hour
		for frame: int in 10:
			await get_tree().process_frame
		var toward_sun := game.sky.sun().global_basis.z.normalized()
		var away := Vector3(-toward_sun.x, 0.0, -toward_sun.z).normalized()
		print(label, ": arco ", game.rainbow_view.amount, ", sol a ", rad_to_deg(asin(toward_sun.y)), " graus")
		await _aimed(game, "%s.png" % label, eye, eye + away * 100.0 + Vector3(0.0, 12.0, 0.0))
		await _aimed(game, "%s_largo.png" % label, eye + Vector3(0.0, 30.0, 0.0) - away * 60.0,
				eye + away * 100.0 + Vector3(0.0, 5.0, 0.0))
	get_tree().quit()


func _aimed(game: GameScreen, file_name: String, eye: Vector3, at: Vector3) -> void:
	game.camera.set_process(false)
	game.camera.camera.global_transform = Transform3D(Basis.looking_at(at - eye, Vector3.UP), eye)
	for frame: int in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
