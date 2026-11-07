extends Node
## Roteiro de verificação visual da Fase 130 (telhado de sapê): na ilha plana, uma rua de casas dos camponeses e outra dos
## operários (para comparar), às 10h e sem a interface, de longe e de perto. Precisa de GPU; no PC do dono roda na área
## de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 30000 res://tools/capture_phase130.tscn -- <pasta>

const HOUSES := 6
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
	for row: int in 2:
		var street_y := ORIGIN.y + 3 + row * 9
		_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(ORIGIN.x, street_y),
				Vector2i(ORIGIN.x + HOUSES * 4 + 1, street_y))))
		for i: int in HOUSES:
			var result := _sim.execute(PlaceBuildingCommand.new(0, &"house", Vector2i(ORIGIN.x + 1 + i * 4, street_y - 3), 2))
			if result.ok():
				var record := _sim.world.building(result.placed[0])
				record.tier = &"peasants" if row == 0 else &"workers"
				record.residents = 5.0
	_game.building_view.rebuild()
	_set_hour(10.0)
	var middle := grid.cell_world(Vector2i(ORIGIN.x + HOUSES * 2, ORIGIN.y + 6))
	await _shot("sape.png", middle, 50.0, 0.3)
	var first := grid.cell_world(Vector2i(ORIGIN.x + 6, ORIGIN.y + 1))
	await _shot("sape_de_perto.png", first, 16.0, 0.4)
	await _shot("sape_de_tras.png", first, 16.0, PI + 0.4)
	get_tree().quit()


func _shot(file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := _game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.target_distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = 6.0
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
