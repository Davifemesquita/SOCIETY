extends Node
## Roteiro de verificação visual da Fase 65 (festa na cidade): na semente 1840, um bairro com casas e mercados (como o
## do benchmark), a festa posta na ilha principal; as bandeirolas de dia e os fogos à noite. Precisa de GPU; no PC do
## dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase65.tscn -- <pasta>

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
	game.hud.visible = false
	var sim := game.simulation
	sim.free_build = true
	sim.ignore_terrain = true
	# o bairro no pedaço de 60 × 50 células com mais terra da ilha principal
	var start := _land_corner(sim.world.island(Simulation.MAIN_ISLAND))
	sim.execute(BuildRoadCommand.new(Simulation.MAIN_ISLAND, RoadPath.l_path(start, start + Vector2i(56, 0))))
	sim.execute(BuildRoadCommand.new(Simulation.MAIN_ISLAND, RoadPath.l_path(start, start + Vector2i(0, 3))))
	TownLayout.build(sim, 30, &"house", start + Vector2i(0, 3))
	TownLayout.build(sim, 6, &"market", start + Vector2i(0, 28))
	sim.execute(BuildRoadCommand.new(Simulation.MAIN_ISLAND, RoadPath.l_path(start + Vector2i(0, 3), start + Vector2i(0, 28))))
	var event := WorldEvent.new()
	event.def = sim.data.event(&"festival")
	event.def_id = &"festival"
	event.island_id = Simulation.MAIN_ISLAND
	event.ends_tick = sim.world.tick + 100000
	sim.world.events_state.events.append(event)
	EventBus.world_event_started.emit(&"festival", Simulation.MAIN_ISLAND)
	var sites := game.festival_view.firework_sites()
	print("mastros ", sites.size())
	if not sites.is_empty():
		_set_hour(11.0)
		await _shot(game, "bandeirolas.png", sites[0], 30.0, 0.7)
		await _shot(game, "bandeirolas_longe.png", sites[0], 70.0, 2.2)
		_set_hour(21.5)
		await _shot(game, "noite.png", sites[0], 110.0, 0.7)
		for k: int in 6:
			game.festival_view.launch(sites[k % sites.size()])
		await _shot(game, "fogos.png", sites[0], 110.0, 0.7, 8)
	GameScreen.terrain_version = -1
	get_tree().quit()


## O canto de cima à esquerda do retângulo de 60 × 50 células com mais terra (passo de 10 células).
func _land_corner(grid: IslandGrid) -> Vector2i:
	var best := Vector2i(2, 2)
	var most := -1
	for y: int in range(0, grid.size.y - 50, 10):
		for x: int in range(0, grid.size.x - 60, 10):
			var land := 0
			for dy: int in range(0, 50, 5):
				for dx: int in range(0, 60, 5):
					if grid.ground[grid.index(Vector2i(x + dx, y + dy))] == IslandGrid.Ground.LAND:
						land += 1
			if land > most:
				most = land
				best = Vector2i(x, y)
	return best


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float, frames: int = 25) -> void:
	var rig := game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = maxf(game.simulation.world.surface_height(focus.x, focus.z), 0.0)
	game.camera.apply()
	for frame: int in frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
