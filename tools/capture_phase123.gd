extends Node
## Roteiro de verificação visual da Fase 123 (borrifo nas falésias): na semente 1840, a rocha de falésia da ilha principal
## mais perto do meio dela, com o jogo andando a 1x e a câmera perto, em três momentos dos jatos. Precisa de GPU; no PC do
## dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase123.tscn -- <pasta>

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
	var grid := game.simulation.world.island(Simulation.MAIN_ISLAND)
	var middle := grid.rect_world(Rect2i(Vector2i.ZERO, grid.size))
	var sites := game.rock_view.spray_sites()
	print("pontos de borrifo ", sites.size())
	if sites.is_empty():
		get_tree().quit()
		return
	var best := sites[0]
	for site: Vector3 in sites:
		if Vector2(site.x, site.y).distance_to(Vector2(middle.x, middle.z)) \
				< Vector2(best.x, best.y).distance_to(Vector2(middle.x, middle.z)):
			best = site
	var focus := Vector3(best.x, 0.0, best.y)
	_aim(game, focus, 34.0, 0.8)
	# o jogo andando: os jatos só sobem com o relógio correndo
	GameClock.set_speed(0)
	for frame: int in 20:
		await get_tree().process_frame
	for k: int in 3:
		game.surf_spray_view.launch(SurfSprayView.spot(best, k * 7, _height(game)))
		await get_tree().create_timer(0.35 + 0.25 * k).timeout
		await _save("borrifo_%d.png" % k)
	_aim(game, focus, 18.0, 0.8)
	game.surf_spray_view.launch(SurfSprayView.spot(best, 3, _height(game)))
	await get_tree().create_timer(0.5).timeout
	await _save("borrifo_de_perto.png")
	print("jatos ", game.surf_spray_view.spray_count())
	get_tree().quit()


func _aim(game: GameScreen, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = 0.0
	game.camera.apply()


func _save(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)


func _height(game: GameScreen) -> Callable:
	return func(x: float, z: float) -> float: return game.simulation.world.surface_height(x, z)
