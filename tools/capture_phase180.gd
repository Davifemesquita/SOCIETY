extends Node
## Roteiro de verificação visual da Fase 180 (borboletas): na semente 1840, os grupos de borboletas da ilha principal mais
## perto do meio dela, de manhã e à tarde, de perto e de meia distância. Precisa de GPU; no PC do dono roda na área de
## trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase180.tscn -- <pasta>

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
	game.hud.visible = false
	var sim := game.simulation
	var grid := sim.world.island(Simulation.MAIN_ISLAND)
	var middle := grid.cell_world(grid.size / 2)
	var centers := ButterflyView.groups(sim.world, sim.data, Simulation.MAIN_ISLAND)
	centers.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.distance_to(middle) < b.distance_to(middle))
	print("grupos na principal: ", centers.size())
	var shot := 0
	for center: Vector3 in centers.slice(0, 2):
		for pair: Array in [[10.0, "manha"], [16.5, "tarde"]]:
			var hour: float = pair[0]
			var label: String = pair[1]
			_set_hour(hour)
			await _shot(game, "borboletas_%d_%s.png" % [shot, label], center, 7.0, 0.6 + shot)
			await _shot(game, "borboletas_%d_%s_longe.png" % [shot, label], center, 11.0, 2.2 + shot)
		shot += 1
	print("borboletas: ", game.butterfly_view.butterfly_count())
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
