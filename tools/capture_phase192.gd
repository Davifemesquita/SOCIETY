extends Node
## Roteiro de verificação visual da Fase 192 (roupa sobre a rua): na ilha plana, uma rua de terra com uma fileira de casas de
## operários de cada lado, frente a frente, às 10h, e os varais atravessando a rua; de perto (a câmera posta à mão na rua) e de
## cima. Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 20000 res://tools/capture_phase192.tscn -- <pasta>

const HOUSES := 8
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
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(18, STREET_Y), Vector2i(20 + HOUSES * 3, STREET_Y))))
	for i: int in HOUSES:
		for pair: Array in [[Vector2i(20 + i * 3, STREET_Y - 3), 2], [Vector2i(20 + i * 3, STREET_Y + 1), 0]]:
			var origin: Vector2i = pair[0]
			var rotation: int = pair[1]
			var result := _sim.execute(PlaceBuildingCommand.new(0, &"house", origin, rotation))
			if result.ok():
				_sim.world.building(result.placed[0]).tier = &"workers"
				_sim.world.building(result.placed[0]).residents = 5.0
	_game.building_view.rebuild()
	_game.street_laundry_view.rebuild()
	print("varais: ", _game.street_laundry_view.line_count())
	_set_hour(10.0)
	var grid := _sim.world.island(0)
	var street := grid.cell_world(Vector2i(20 + HOUSES * 3 / 2, STREET_Y))
	# na rua, olhando ao longo dela, um pouco acima de quem anda
	await _aimed("roupa_na_rua.png", street + Vector3(-9.0, 2.6, 0.0), street + Vector3(4.0, 4.2, 0.0))
	await _aimed("roupa_na_rua_de_cima.png", street + Vector3(-6.0, 14.0, 9.0), street + Vector3(0.0, 3.0, 0.0))
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
