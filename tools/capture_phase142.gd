extends Node
## Roteiro de verificação visual da Fase 142 (botes no porto): na semente 1840, um entreposto na costa da ilha principal
## (achado pelo SiteFinder) e os botes remando diante dele, às 10h: a roda de longe e um bote de perto. Precisa de GPU; no
## PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase142.tscn -- <pasta>

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
	if found.is_empty():
		push_warning("capture_phase142: sem lugar para o entreposto")
		get_tree().quit()
		return
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"trading_post", origin, rotation))
	for frame: int in 3:
		await get_tree().process_frame
	var record := sim.world.building(result.placed[0])
	var loop := RowboatView.loop(sim.world, record, sim.def_of(record), sim.config.cell_size_m)
	print("botes ", game.rowboat_view.boat_count(), " roda ", loop)
	if loop.is_empty():
		get_tree().quit()
		return
	var center: Vector3 = loop[0]
	var radius: float = loop[1]
	game.rowboat_view.advance(5.0)
	var post := grid.rect_world(Footprint.rect(record.origin, sim.def_of(record).size, record.rotation))
	await _shot(game, "botes.png", (center + post) * 0.5, 36.0, atan2(center.x - post.x, center.z - post.z) + 0.6, 8.0)
	var first: int = game.rowboat_view._loops[0][2]
	var boat := RowboatView.pose(center, radius, first, game.rowboat_view._time)
	await _shot(game, "bote_de_perto.png", boat.origin, 7.0, 0.8, 14.0)
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
