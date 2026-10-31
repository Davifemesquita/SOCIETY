extends Node
## Roteiro de verificação visual da Fase 140 (clareira do lenhador): na semente 1840, um lenhador no meio da mata mais
## cerrada da ilha principal, às 10h: de longe (a clareira em volta da cabana) e de perto (os tocos e as toras). Precisa
## de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase140.tscn -- <pasta>

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
	# a mata mais cerrada, num lote quase plano
	var best := Vector2i(-1, -1)
	var best_trees := -1
	for y: int in range(8, grid.size.y - 11, 3):
		for x: int in range(8, grid.size.x - 11, 3):
			var lot := Rect2i(x, y, 3, 3)
			if not grid.area_is_land(lot.grow(5)) or grid.area_relief(lot) > 0.6:
				continue
			var trees := grid.trees_in(lot.grow(5))
			if trees > best_trees:
				best_trees = trees
				best = Vector2i(x, y)
	var result := sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"lumberjack", best, 0))
	for frame: int in 3:
		await get_tree().process_frame
	print("lenhador ", result.ok(), " em ", best, " tocos ", game.stump_view.stump_count(), " toras ", game.stump_view.log_count())
	var center := grid.rect_world(Rect2i(best, Vector2i(3, 3)))
	await _shot(game, "clareira.png", center, 60.0, 0.6, 18.0)
	await _shot(game, "clareira_de_perto.png", center, 26.0, 0.6 + PI, 40.0)
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
