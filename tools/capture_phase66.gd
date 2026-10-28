extends Node
## Roteiro de verificação visual da Fase 66 (prefeitura): na semente 1840, uma prefeitura com casas em volta no maior
## pedaço de terra da ilha principal, de perto, e o painel dela com a política escolhida. Precisa de GPU; no PC do dono
## roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase66.tscn -- <pasta>

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
	var sim := game.simulation
	sim.free_build = true
	sim.ignore_terrain = true
	var start := _land_corner(sim.world.island(Simulation.MAIN_ISLAND))
	sim.execute(BuildRoadCommand.new(Simulation.MAIN_ISLAND, RoadPath.l_path(start, start + Vector2i(40, 0))))
	var hall_result := sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"town_hall", start + Vector2i(18, -4), 2))
	for k: int in 4:
		sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"house", start + Vector2i(4 + k * 3, -3), 2))
		sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"house", start + Vector2i(24 + k * 3, -3), 2))
	if not hall_result.ok():
		print("prefeitura recusada: ", hall_result.reason)
		get_tree().quit()
		return
	var hall: int = hall_result.placed[0]
	sim.execute(SetPolicyCommand.new(hall, &"holidays"))
	var grid := sim.world.island(Simulation.MAIN_ISLAND)
	var focus := grid.rect_world(Footprint.rect(start + Vector2i(18, -4), Vector2i(4, 4), 2))
	game.hud.visible = false
	await _shot(game, "prefeitura.png", focus, 28.0, 0.5)
	game.hud.visible = true
	game.tool.select(hall)
	await _shot(game, "prefeitura_painel.png", focus, 40.0, 0.5)
	GameScreen.terrain_version = -1
	get_tree().quit()


## O canto do retângulo de 60 × 50 células com mais terra (passo de 10 células), uma fileira abaixo da borda.
func _land_corner(grid: IslandGrid) -> Vector2i:
	var best := Vector2i(2, 8)
	var most := -1
	for y: int in range(8, grid.size.y - 50, 10):
		for x: int in range(0, grid.size.x - 60, 10):
			var land := 0
			for dy: int in range(0, 50, 5):
				for dx: int in range(0, 60, 5):
					if grid.ground[grid.index(Vector2i(x + dx, y + dy))] == IslandGrid.Ground.LAND:
						land += 1
			if land > most:
				most = land
				best = Vector2i(x, y)
	return best + Vector2i(0, 10)


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
