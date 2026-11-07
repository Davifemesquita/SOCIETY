extends Node
## Roteiro de verificação visual da Fase 129 (sombra das nuvens): na semente 1840, a ilha principal de longe às 11h, com o
## céu limpo (sem sombra), nublado e meio nublado, e as sombras andando com o vento (dois quadros um depois do outro). A
## cobertura vai direto no global cloud_cover (a WeatherView fica parada para o sorteio do dia não a trocar). Precisa de
## GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase129.tscn -- <pasta>

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
	_set_hour(11.0)
	game.hud.visible = false
	game.weather.set_process(false)
	var grid := game.simulation.world.island(Simulation.MAIN_ISLAND)
	var middle := grid.rect_world(Rect2i(Vector2i.ZERO, grid.size))
	for shot: Array in [[0.0, "limpo"], [0.95, "nublado"], [0.55, "meio_nublado"]]:
		var cover: float = shot[0]
		RenderingServer.global_shader_parameter_set(&"cloud_cover", cover)
		await _shot(game, "sombras_%s.png" % shot[1], middle, 220.0, 0.5)
	RenderingServer.global_shader_parameter_set(&"cloud_cover", 0.95)
	RenderingServer.global_shader_parameter_set(&"cloud_offset", Vector2(60.0, 25.0))
	await _shot(game, "sombras_andando.png", middle, 220.0, 0.5)
	await _shot(game, "sombras_de_perto.png", middle, 70.0, 0.9)
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
