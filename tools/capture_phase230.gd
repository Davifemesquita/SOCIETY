extends Node
## Roteiro de verificação visual da Fase 230 (sinal no trilho): na ilha plana, o poço de petróleo e a usina a petróleo ligados por
## um trilho, às 10h e às 21h, e o sinal de braço em cada ponta da linha; de perto, de dia e de noite, e de longe. Precisa de GPU;
## no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 20000 res://tools/capture_phase230.tscn -- <pasta>

const STREET := 20

var _out_dir: String
var _game: GameScreen
var _sim: Simulation


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = true
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	GameClock.set_speed(TickClock.PAUSED)
	_run.call_deferred()


func _run() -> void:
	_sim = _game.simulation
	_sim.free_build = true
	_sim.ignore_terrain = true
	_game.hud.visible = false
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(6, STREET), Vector2i(40, STREET))))
	_sim.execute(PlaceBuildingCommand.new(0, &"oil_well", Vector2i(10, STREET + 1), 0))
	_sim.execute(PlaceBuildingCommand.new(0, &"oil_power_station", Vector2i(30, STREET + 1), 0))
	var path: Array[Vector2i] = []
	for x: int in range(10, 35):
		path.append(Vector2i(x, STREET + 6))
	for y: int in range(STREET + 4, STREET + 6):
		path.append(Vector2i(11, y))
	_sim.execute(BuildRailCommand.new(0, path))
	_game.building_view.rebuild()
	_game.rail_signal_view.rebuild()
	print("sinais: ", _game.rail_signal_view.signal_count())
	if _game.rail_signal_view.places.is_empty():
		get_tree().quit()
		return
	var post := _game.rail_signal_view.places[0]
	var top := post.origin + Vector3(0.0, 3.0, 0.0)
	_set_hour(10.0)
	await _aimed("sinal_de_perto.png", top + post.basis.z * 5.0 - post.basis.x * 4.0 + Vector3(0.0, 1.0, 0.0), top)
	await _aimed("sinal_e_linha.png", top + post.basis.z * 14.0 - post.basis.x * 10.0 + Vector3(0.0, 8.0, 0.0), top)
	_set_hour(21.5)
	await _aimed("sinal_de_noite.png", top + post.basis.z * 5.0 - post.basis.x * 4.0 + Vector3(0.0, 1.0, 0.0), top)
	get_tree().quit()


func _aimed(file_name: String, eye: Vector3, at: Vector3) -> void:
	_game.camera.set_process(false)
	_game.camera.camera.global_transform = Transform3D(Basis.looking_at(at - eye, Vector3.UP), eye)
	for frame: int in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
