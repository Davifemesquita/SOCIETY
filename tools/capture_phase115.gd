extends Node
## Roteiro de verificação visual da Fase 115 (carreira do estaleiro): na semente 1840, um estaleiro na costa da ilha
## principal (achado pelo SiteFinder) e o casco em obra em três degraus do progresso. Precisa de GPU; no PC do dono roda
## na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase115.tscn -- <pasta>

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
	var found := SiteFinder.find(sim, &"shipyard", Simulation.MAIN_ISLAND, grid.size / 2)
	if found.is_empty():
		push_warning("capture_phase115: sem lugar para o estaleiro")
		get_tree().quit()
		return
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := sim.execute(PlaceBuildingCommand.new(0, &"shipyard", origin, rotation))
	var record := sim.world.building(result.placed[0])
	var view := game.shipway_view
	view.rebuild()
	var plan := view.site_of(record.id)
	print("carreiras ", view.ramp_count())
	if plan.is_empty():
		get_tree().quit()
		return
	var middle := ShipwayView.ramp_point(plan, 10.0)
	for progress: float in [0.25, 0.6, 0.9]:
		var order := ShipyardState.Order.new()
		order.def_id = &"merchant_ship"
		order.progress = progress
		sim.world.shipyard_state.orders[record.id] = order
		view.refresh_hulls()
		await _shot(game, "casco_%d.png" % roundi(progress * 100.0), middle, 34.0, 0.8)
	await _shot(game, "casco_de_perto.png", middle, 18.0, 2.2)
	sim.world.shipyard_state.forget(record.id)
	view.refresh_hulls()
	await _shot(game, "carreira_vazia.png", middle, 30.0, 0.8)
	get_tree().quit()


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
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
