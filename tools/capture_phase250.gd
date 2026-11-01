extends Node
## Roteiro de verificação visual da Fase 250 (balança de carga no armazém): na ilha plana, dois armazéns virados para a rua, às
## 10h, e a balança com os sacos ao lado deles; de perto e de longe. Precisa de GPU; no PC do dono roda na área de trabalho
## escondida:
##   godot --path . --resolution 1920x1080 --quit-after 20000 res://tools/capture_phase250.tscn -- <pasta>

const STREET_Y := 30

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
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(18, STREET_Y), Vector2i(42, STREET_Y))))
	_sim.execute(PlaceBuildingCommand.new(0, &"warehouse", Vector2i(21, STREET_Y - 4), 2))
	_sim.execute(PlaceBuildingCommand.new(0, &"warehouse", Vector2i(32, STREET_Y - 4), 2))
	_game.building_view.rebuild()
	_game.scale_view.rebuild()
	print("balancas: ", _game.scale_view.scale_count())
	_set_hour(10.0)
	if _game.scale_view.places.is_empty():
		get_tree().quit()
		return
	var yard := _game.scale_view.places[0]
	var out := yard.basis.z.normalized()
	var yaw := atan2(out.x, out.z)
	await _aimed("balanca_de_perto.png", yard.origin + Vector3(0.0, 0.6, 0.0), 6.0, yaw + 0.5)
	await _aimed("balanca_e_predio.png", yard.origin + Vector3(0.0, 1.0, 0.0), 16.0, yaw + 1.2)
	await _aimed("balanca_de_longe.png", yard.origin + Vector3(0.0, 1.0, 0.0), 30.0, yaw - 0.4)
	get_tree().quit()


func _aimed(file_name: String, at: Vector3, distance: float, yaw: float) -> void:
	_game.camera.set_process(false)
	var eye := at + Vector3(sin(yaw), 0.55, cos(yaw)).normalized() * distance
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
