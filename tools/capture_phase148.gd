extends Node
## Roteiro de verificação visual da Fase 148 (cavalete do lenhador): na semente 1840, um lenhador na beira da mata da ilha
## principal (num lote quase plano com mata em volta), às 10h: de longe e de perto do terreiro. Precisa de GPU; no PC do
## dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase148.tscn -- <pasta>

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
	sim.free_build = true
	sim.ignore_terrain = true
	var grid := sim.world.island(Simulation.MAIN_ISLAND)
	# a beira da mata: um lote quase plano sem árvore com bastante mata em volta
	var best := Vector2i(-1, -1)
	var best_score := -1
	for y: int in range(8, grid.size.y - 11, 2):
		for x: int in range(8, grid.size.x - 11, 2):
			var lot := Rect2i(x, y, 3, 3)
			if not grid.area_is_land(lot.grow(2)) or grid.area_relief(lot.grow(1)) > 0.6 or grid.trees_in(lot) > 0:
				continue
			var trees := grid.trees_in(lot.grow(4))
			if trees > best_score:
				best_score = trees
				best = Vector2i(x, y)
	var result := sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"lumberjack", best, 0))
	for frame: int in 3:
		await get_tree().process_frame
	print("lenhador ", result.ok(), " em ", best, " terreiros ", game.lumber_yard_view.yard_count())
	var found := LumberYardView.cells(sim.world, sim.data, Simulation.MAIN_ISLAND)
	if found.is_empty():
		get_tree().quit()
		return
	var cell: Vector2i = found.keys()[0]
	var at := grid.cell_world(cell)
	var center := grid.rect_world(Rect2i(best, Vector2i(3, 3)))
	await _shot(game, "terreiro.png", (at + center) * 0.5, 24.0, 0.6, 22.0)
	await _shot(game, "terreiro_de_perto.png", at, 8.0, atan2(at.x - center.x, at.z - center.z) + 0.8, 16.0)
	get_tree().quit()


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float, pitch: float) -> void:
	var rig := game.camera.rig
	rig.pitch_offset_deg = pitch
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
