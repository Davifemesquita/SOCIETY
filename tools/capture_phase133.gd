extends Node
## Roteiro de verificação visual da Fase 133 (bandeirolas da feira): na ilha plana, dois mercados virados para lados
## diferentes com a rua na frente, às 10h e sem a interface, de longe e de perto. Precisa de GPU; no PC do dono roda na
## área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 30000 res://tools/capture_phase133.tscn -- <pasta>

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
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(ORIGIN + Vector2i(-2, 8), ORIGIN + Vector2i(30, 8)), true))
	var first := _sim.execute(PlaceBuildingCommand.new(0, &"market", ORIGIN + Vector2i(2, 2), 2))
	_sim.execute(PlaceBuildingCommand.new(0, &"market", ORIGIN + Vector2i(14, 2), 2))
	for i: int in 3:
		_sim.execute(PlaceBuildingCommand.new(0, &"house", ORIGIN + Vector2i(22 + i * 3, 5), 2))
	_game.building_view.rebuild()
	_set_hour(10.0)
	for frame: int in 5:
		await get_tree().process_frame
	print("mercados ", _game.market_bunting_view.market_count(), " ok ", first.ok())
	var middle := grid.cell_world(ORIGIN + Vector2i(10, 6))
	await _shot("feira.png", middle, 40.0, 0.35)
	var market := grid.cell_world(ORIGIN + Vector2i(5, 6))
	await _shot("feira_de_perto.png", market, 17.0, 0.5)
	get_tree().quit()


func _shot(file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := _game.camera.rig
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
