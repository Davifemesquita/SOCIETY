extends "res://tools/capture_phase285.gd"
## Fase 286: o custo do tapete de capim na GPU com a câmera em cima do prado (o trajeto do benchmark passa quase só pela vila).
## No prado aberto da captura do ciclo, a 30, 60 e 110 m, mede a GPU média de FRAMES quadros com o tapete ligado e desligado e
## escreve no terminal e em <saida>. Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 60000 res://tools/grass_cost.tscn -- <saida.md>

const FRAMES := 180


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0].get_base_dir() if not args.is_empty() else OS.get_user_data_dir()
	_run.call_deferred()


func _run() -> void:
	var game := _open_game()
	var points: Array[Vector3] = await _build_town(game)
	var grid := game.simulation.world.island(Simulation.MAIN_ISLAND)
	var meadow := grid.cell_world(_find_meadow(grid, points[0]))
	var viewport := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport, true)
	var lines: Array[String] = ["| distância | tufos | GPU com o tapete | GPU sem | diferença |", "|---|---|---|---|---|"]
	for distance: float in [30.0, 60.0, 110.0]:
		var on := await _measure(game, meadow, distance, true)
		var tufts := game.grass_carpet_view.tuft_count()
		var off := await _measure(game, meadow, distance, false)
		lines.append("| %d m | %d | %.2f ms | %.2f ms | %+.2f ms |" % [distance, tufts, on, off, on - off])
	var text := "\n".join(lines)
	print(text)
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		var file := FileAccess.open(args[0], FileAccess.WRITE)
		file.store_string(text + "\n")
	get_tree().quit()


func _measure(game: GameScreen, focus: Vector3, distance: float, carpet: bool) -> float:
	var rig := game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.yaw = 0.6
	rig.target_yaw = 0.6
	rig.ground_height = maxf(game.simulation.world.surface_height(focus.x, focus.z), 0.0)
	game.camera.apply()
	game.grass_carpet_view.set_process(carpet)
	game.grass_carpet_view.visible = carpet
	if carpet:
		game.grass_carpet_view.refresh(1000)
	for frame: int in 60:
		await get_tree().process_frame
	var total := 0.0
	for frame: int in FRAMES:
		await get_tree().process_frame
		total += RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid())
	return total / FRAMES
