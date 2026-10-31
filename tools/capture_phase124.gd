extends Node
## Roteiro de verificação visual da Fase 124 (mansarda): na ilha plana, uma rua de casas dos investidores bem separadas
## (com e sem a mansarda, que depende da ala), às 10h e sem a interface, de frente, de trás e de cima. Precisa de GPU; no
## PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 30000 res://tools/capture_phase124.tscn -- <pasta>

const HOUSES := 6
const ORIGIN := Vector2i(20, 20)
const STEP := 6

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
	var street_y := ORIGIN.y + 3
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(ORIGIN.x, street_y),
			Vector2i(ORIGIN.x + HOUSES * STEP + 1, street_y))))
	var line := ""
	for i: int in HOUSES:
		var result := _sim.execute(PlaceBuildingCommand.new(0, &"house", Vector2i(ORIGIN.x + 1 + i * STEP, street_y - 3), 2))
		if result.ok():
			var record := _sim.world.building(result.placed[0])
			record.tier = &"investors"
			record.residents = 5.0
			var spec := BuildingKit.spec_for(_sim, record, grid.cell_size)
			line += "%d:%s " % [i, "mansarda" if spec.mansard else ("ala" if spec.wing != 0 else "plano")]
	print("casas ", line)
	_game.building_view.rebuild()
	_set_hour(10.0)
	var middle := grid.cell_world(Vector2i(ORIGIN.x + HOUSES * STEP / 2, street_y - 1))
	await _shot("mansardas.png", middle, 70.0, 0.25)
	await _shot("mansardas_de_tras.png", middle, 70.0, PI + 0.25)
	await _shot("mansardas_de_cima.png", middle, 110.0, 0.0)
	var first := grid.cell_world(Vector2i(ORIGIN.x + 2, street_y - 2))
	await _shot("mansarda_de_perto.png", first, 36.0, 0.5)
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
