extends Node
## Roteiro de verificação visual da Fase 155 (carneirinhos): na semente 1840, o mar aberto a leste da ilha principal às 11h,
## com o ar parado (sem carneirinhos), com a brisa de um dia limpo, com o vento de chuva e de perto. A força vai direto nos
## globais (a WeatherView fica parada para o sorteio do dia não a trocar). Precisa de GPU; no PC do dono roda na área de
## trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase155.tscn -- <pasta>

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
	RenderingServer.global_shader_parameter_set(&"cloud_cover", 0.0)
	RenderingServer.global_shader_parameter_set(&"wind_direction", Vector2(0.8, 0.6).normalized())
	var grid := game.simulation.world.island(Simulation.MAIN_ISLAND)
	var rect := grid.world_rect()
	var sea := Vector3(rect.end.x + 120.0, 0.0, rect.get_center().y)
	var config := game.simulation.config
	for shot: Array in [[0.0, "parado"], [config.weather_wind_clear, "brisa"], [config.weather_wind_rain, "vento_forte"]]:
		var wind: float = shot[0]
		RenderingServer.global_shader_parameter_set(&"wind_strength", wind)
		RenderingServer.global_shader_parameter_set(&"sea_whitecaps", WeatherView.whitecaps_of(wind))
		await _shot(game, "carneirinhos_%s.png" % shot[1], sea, 160.0, 0.6)
	await _shot(game, "carneirinhos_de_perto.png", sea, 55.0, 0.9)
	get_tree().quit()


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = 0.0
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
