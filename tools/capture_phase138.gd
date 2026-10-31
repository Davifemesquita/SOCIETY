extends Node
## Roteiro de verificação visual da Fase 138 (chapa ondulada): na ilha plana, uma fileira de fábricas pesadas (fundição,
## vigas de aço, vidraria, olaria, usina e conservas) ao lado de uma padaria de telha, às 10h e sem a interface, de longe e
## de perto. Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 30000 res://tools/capture_phase138.tscn -- <pasta>

const ORIGIN := Vector2i(20, 20)
const FACTORIES: Array[StringName] = [&"bakery", &"furnace", &"steel_beam_works", &"glassworks", &"brickworks",
		&"power_station", &"cannery"]

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
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(ORIGIN + Vector2i(-2, -1), ORIGIN + Vector2i(56, -1))))
	var x := 0
	for id: StringName in FACTORIES:
		_sim.execute(PlaceBuildingCommand.new(0, id, ORIGIN + Vector2i(x, 0), 0))
		x += _sim.data.building(id).size.x + 1
	_game.building_view.rebuild()
	_set_hour(10.0)
	for frame: int in 5:
		await get_tree().process_frame
	await _shot("fabricas.png", grid.cell_world(ORIGIN + Vector2i(24, 3)), 46.0, 0.5, 8.0)
	await _shot("chapa_de_perto.png", grid.cell_world(ORIGIN + Vector2i(10, 3)), 14.0, 0.7, 22.0)
	await _shot("chapa_e_telha.png", grid.cell_world(ORIGIN + Vector2i(4, 2)), 18.0, 0.3, 18.0)
	get_tree().quit()


func _shot(file_name: String, focus: Vector3, distance: float, yaw: float, pitch: float) -> void:
	var rig := _game.camera.rig
	rig.pitch_offset_deg = pitch
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.target_distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = 0.0
	_game.camera.apply()
	for frame: int in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
