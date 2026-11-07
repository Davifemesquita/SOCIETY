extends Node
## Roteiro de verificação visual da Fase 184 (limo na pedra): na semente 1840, as rochas da ilha principal que encostam no mar
## (os pontos do borrifo da Fase 123, `RockView.spray_sites`), de perto, com a câmera posta à mão do lado do mar, e a de meia
## distância. Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase184.tscn -- <pasta>

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
	var middle := grid.cell_world(grid.size / 2)
	var sites := Array(game.rock_view.spray_sites())
	sites.sort_custom(func(a: Vector3, b: Vector3) -> bool:
		return Vector2(a.x - middle.x, a.y - middle.z).length() < Vector2(b.x - middle.x, b.y - middle.z).length())
	print("rochas no mar: ", sites.size())
	var shot := 0
	for site: Vector3 in sites:
		var at := Vector3(site.x, 0.4, site.y)
		# do lado do mar: o rumo em que a altura em volta é a mais baixa
		var best := 0.0
		var lowest := INF
		for k: int in 8:
			var angle := TAU * k / 8.0
			var height := sim.world.surface_height(at.x + sin(angle) * 8.0, at.z + cos(angle) * 8.0)
			if height < lowest:
				lowest = height
				best = angle
		await _aimed(game, "limo_%d.png" % shot, at, maxf(site.z * 3.0, 6.0), best)
		await _aimed(game, "limo_%d_longe.png" % shot, at, maxf(site.z * 7.0, 16.0), best + 0.4)
		shot += 1
		if shot >= 3:
			break
	get_tree().quit()


## Põe a Camera3D à mão, um pouco acima do ponto, a distance metros dele no rumo yaw (o offset da câmera é (sen, ·, cos)).
func _aimed(game: GameScreen, file_name: String, at: Vector3, distance: float, yaw: float) -> void:
	game.camera.set_process(false)
	var eye := at + Vector3(sin(yaw), 0.4, cos(yaw)).normalized() * distance
	game.camera.camera.global_transform = Transform3D(Basis.looking_at(at - eye, Vector3.UP), eye)
	for frame: int in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)
	game.camera.set_process(true)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
