extends Node
## Roteiro de verificação visual da Fase 147 (mastros no cais): na semente 1840, um entreposto na costa da ilha principal
## (achado pelo SiteFinder) e os mastros com as flâmulas nas pontas do cais de pedra, com o vento correndo. Precisa de GPU; no
## PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase147.tscn -- <pasta>

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
		push_warning("capture_phase147: sem lugar para o entreposto")
		get_tree().quit()
		return
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"trading_post", origin, rotation))
	for frame: int in 3:
		await get_tree().process_frame
	var record := sim.world.building(result.placed[0])
	var masts := QuayMastView.masts(sim, record)
	print("mastros ", game.quay_mast_view.mast_count())
	if masts.is_empty():
		get_tree().quit()
		return
	# o vento sopra (o jogo anda um pouco a 1x para o WeatherView virar as flâmulas)
	GameClock.set_speed(0)
	for frame: int in 30:
		await get_tree().process_frame
	GameClock.set_speed(TickClock.PAUSED)
	var post := grid.rect_world(Footprint.rect(record.origin, sim.def_of(record).size, record.rotation))
	var at := masts[0]
	await _shot(game, "mastros.png", (at + post) * 0.5, 30.0, atan2(at.x - post.x, at.z - post.z) + 0.8, 4.0)
	# de perto, do lado do mar, com a câmera posta à mão (a da partida fica presa ao chão)
	var plan := HarborView.walkway(sim, record)
	var outward: Vector3 = plan["direction"]
	var top := at + Vector3(0.0, QuayMastView.MAST_M - 1.0, 0.0)
	var eye := top + outward * 9.0 + Vector3(0.0, 1.5, 0.0) + (at - post).normalized() * 3.0
	game.camera.set_process(false)
	game.camera.camera.global_transform = Transform3D(Basis.looking_at(top - eye, Vector3.UP), eye)
	for frame: int in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join("flamula_de_perto.png"))
	print("capturado flamula_de_perto.png")
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
