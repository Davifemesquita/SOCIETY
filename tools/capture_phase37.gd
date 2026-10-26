extends Node
## Roteiro de verificação visual da Fase 37 (luz e cor de época): as mesmas tomadas do arquipélago da semente 1840 — a
## ilha a 420 m e o litoral do entreposto a 110 m — em quatro horas (7h, 11h, 18h30 e 22h), com a "Cor de época"
## desligada e ligada, para o dono do produto comparar (o A/B do plano). Precisa de GPU:
##   godot --path . --resolution 1920x1080 --quit-after 30000 res://tools/capture_phase37.tscn -- <pasta>

const SEED := 1840
const HOURS: Array[float] = [7.0, 11.0, 18.5, 22.0]

var _out_dir: String
var _game: GameScreen
var _sim: Simulation


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = false
	GameScreen.world_seed = SEED
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	GameClock.set_speed(TickClock.PAUSED)
	_run.call_deferred()


func _run() -> void:
	_sim = _game.simulation
	var grid := _sim.world.island(0)
	var post := SiteFinder.find(_sim, &"trading_post", 0, Vector2i(grid.size.x / 2, 0))
	var post_origin: Vector2i = post[0]
	var before := Settings.period_look
	for period: bool in [false, true]:
		Settings.period_look = period
		Settings.apply()
		var tag := "epoca" if period else "atual"
		for hour: float in HOURS:
			_set_hour(hour)
			var label := "%02dh%02d" % [floori(hour), roundi(fmod(hour, 1.0) * 60.0)]
			await _shot("ilha_%s_%s.png" % [label, tag], grid.cell_world(grid.size / 2), 420.0, 0.0)
			await _shot("litoral_%s_%s.png" % [label, tag], grid.cell_world(post_origin), 110.0, 0.6)
	Settings.period_look = before
	Settings.apply()
	get_tree().quit()


func _shot(file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := _game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = _sim.world.surface_height(focus.x, focus.z)
	_game.camera.camera.far = maxf(4000.0, distance * 3.0)
	_game.camera.apply()
	for frame: int in 24:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
