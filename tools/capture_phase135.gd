extends Node
## Roteiro de verificação visual da Fase 135 (galinhas no quintal): na ilha plana, uma fileira de casas de camponeses
## com a rua de terra na frente, às 10h e sem a interface, de longe e de perto. Precisa de GPU; no PC do dono roda na área de
## trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 30000 res://tools/capture_phase135.tscn -- <pasta>

const ORIGIN := Vector2i(20, 20)

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
	var grid := _sim.world.island(0)
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(ORIGIN + Vector2i(-2, 3), ORIGIN + Vector2i(30, 3))))
	for i: int in 8:
		_sim.execute(PlaceBuildingCommand.new(0, &"house", ORIGIN + Vector2i(i * 3, 0), 2))
	_game.building_view.rebuild()
	_game.chicken_view.rebuild()
	_set_hour(10.0)
	_game.chicken_view.advance(3.0)
	for frame: int in 5:
		await get_tree().process_frame
	print("galinhas ", _game.chicken_view.chicken_count())
	var middle := grid.cell_world(ORIGIN + Vector2i(12, 2))
	await _shot("quintais.png", middle, 30.0, 0.3)
	var near := grid.cell_world(ORIGIN + Vector2i(4, 2))
	await _shot("galinhas_de_perto.png", near, 6.5, 0.45, 24.0)
	_game.chicken_view.advance(4.3)
	await _shot("galinhas_bicando.png", near, 6.5, 0.45, 24.0)
	get_tree().quit()


func _shot(file_name: String, focus: Vector3, distance: float, yaw: float, pitch: float = 0.0) -> void:
	var rig := _game.camera.rig
	rig.pitch_offset_deg = pitch
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.target_distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = 0.0
	_game.camera.apply()
	for frame: int in 25:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
