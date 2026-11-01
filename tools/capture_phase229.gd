extends Node
## Roteiro de verificação visual da Fase 229 (morcegos ao anoitecer): na ilha plana, a igreja com uma rua de casas, às 21h30,
## e o bando de morcegos em volta da torre; de perto e de longe (a câmera posta à mão: a da partida fica presa ao chão). Precisa
## de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 20000 res://tools/capture_phase229.tscn -- <pasta>

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
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(14, STREET_Y), Vector2i(46, STREET_Y))))
	_sim.execute(PlaceBuildingCommand.new(0, &"church", Vector2i(26, STREET_Y - 5), 2))
	for i: int in 4:
		for x: int in [15 + i * 3, 33 + i * 3]:
			var result := _sim.execute(PlaceBuildingCommand.new(0, &"house", Vector2i(x, STREET_Y - 3), 2))
			if result.ok():
				_sim.world.building(result.placed[0]).tier = &"workers"
				_sim.world.building(result.placed[0]).residents = 5.0
	_game.building_view.rebuild()
	_game.bat_view.rebuild()
	_game.bat_view.advance(3.0)
	print("morcegos: ", _game.bat_view.bat_count())
	_set_hour(21.5)
	_game.bat_view.show_for_night(1.0)
	var towers := SwallowView.towers(_sim)
	if towers.is_empty():
		get_tree().quit()
		return
	var tower := towers[0]
	await _aimed("morcegos_de_perto.png", tower + Vector3(4.0, 2.0, 16.0), tower)
	_game.bat_view.advance(1.3)
	await _aimed("morcegos_de_lado.png", tower + Vector3(-15.0, 1.0, 9.0), tower + Vector3(0.0, -1.0, 0.0))
	await _aimed("morcegos_de_longe.png", tower + Vector3(10.0, 6.0, 34.0), tower + Vector3(0.0, -4.0, 0.0))
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
