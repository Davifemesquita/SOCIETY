extends Node
## Roteiro de verificação visual da Fase 146 (grade e lampiões no cais): na semente 1840, um entreposto na costa da ilha principal
## (achado pelo SiteFinder) e o cais de pedra com a grade e os lampiões, de dia e às 21h. Precisa de GPU; no
## PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase146.tscn -- <pasta>

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
		push_warning("capture_phase146: sem lugar para o entreposto")
		get_tree().quit()
		return
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"trading_post", origin, rotation))
	for frame: int in 3:
		await get_tree().process_frame
	var record := sim.world.building(result.placed[0])
	var lamps := QuayRailView.lamps(sim, record)
	print("lampiões ", game.quay_rail_view.lamp_count(), " trechos de grade ", QuayRailView.rails(sim, record).size())
	var spans := QuayRailView.rails(sim, record)
	if spans.is_empty():
		get_tree().quit()
		return
	var first: Vector3 = spans[spans.size() / 2][0]
	var post := grid.rect_world(Footprint.rect(record.origin, sim.def_of(record).size, record.rotation))
	var at := first if lamps.is_empty() else lamps[0]
	# do lado do mar, olhando o cais
	await _shot(game, "cais_grade.png", at, 14.0, atan2(at.x - post.x, at.z - post.z) + 0.6, 6.0)
	_set_hour(21.0)
	await _shot(game, "cais_de_noite.png", at, 14.0, atan2(at.x - post.x, at.z - post.z) + 0.6, 6.0)
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
