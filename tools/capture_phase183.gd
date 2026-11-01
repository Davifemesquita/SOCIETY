extends Node
## Roteiro de verificação visual da Fase 183 (barco na areia): na semente 1840, cabanas de pesca na ilha principal (achadas pelo
## SiteFinder) com o barco virado na praia ao lado; fotos de perto e de meia distância, da terra para o mar. Precisa de GPU; no
## PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase183.tscn -- <pasta>

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
	var near := grid.size / 2
	var placed := 0
	for k: int in 12:
		var found := SiteFinder.find(sim, &"fishery", Simulation.MAIN_ISLAND, near)
		if found.is_empty():
			break
		var origin: Vector2i = found[0]
		var rotation: int = found[1]
		var result := sim.execute(PlaceBuildingCommand.new(0, &"fishery", origin, rotation))
		if result.ok():
			placed += 1
		near = Vector2i(posmod(near.x + 37, grid.size.x), posmod(near.y + 53, grid.size.y))
		if placed >= 4:
			break
	await get_tree().process_frame
	game.beach_boat_view.rebuild()
	print("barcos na areia: ", game.beach_boat_view.boat_count())
	var sites := BeachBoatView.sites(sim.world, sim.data, Simulation.MAIN_ISLAND)
	var shot := 0
	for cell: Vector2i in sites:
		var sea := sites[cell]
		var at := grid.cell_world(cell)
		# a câmera do lado de terra, olhando para o mar
		var yaw := atan2(-float(sea.x), -float(sea.y))
		await _shot(game, "barco_%d.png" % shot, at, 9.0, yaw + 0.5)
		await _shot(game, "barco_%d_longe.png" % shot, at, 24.0, yaw + 0.3)
		shot += 1
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
