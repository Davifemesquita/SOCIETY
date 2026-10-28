extends Node
## Roteiro de verificação visual da Fase 78 (tanques da usina a petróleo): no mundo plano, a usina a petróleo ao lado da
## usina a carvão, de perto e de longe. Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase78.tscn -- <pasta>

const OIL := Vector2i(40, 56)
const COAL := Vector2i(48, 56)

var _out_dir: String


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_run.call_deferred()


func _run() -> void:
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = true
	var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(game)
	GameClock.set_speed(TickClock.PAUSED)
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(11.0 - clock.hour(), 24.0)
	game.hud.visible = false
	var sim := game.simulation
	sim.free_build = true
	var oil := sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"oil_power_station", OIL, 0))
	var coal := sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"power_station", COAL, 0))
	print("usina a petróleo ", oil.ok(), " ", oil.reason, " usina a carvão ", coal.ok(), " ", coal.reason)
	if not oil.ok() or not coal.ok():
		get_tree().quit()
		return
	var grid := sim.world.island(Simulation.MAIN_ISLAND)
	var oil_center := grid.cell_world(OIL + Vector2i(2, 2))
	var coal_center := grid.cell_world(COAL + Vector2i(2, 2))
	await _shot(game, "usina_petroleo.png", oil_center, 22.0, PI + 0.5)
	await _shot(game, "tanques_perto.png", oil_center + Vector3(0.0, 0.0, -2.0), 12.0, PI - 0.4)
	await _shot(game, "as_duas.png", (oil_center + coal_center) * 0.5, 40.0, PI + 0.3)
	GameScreen.flat_world = false
	get_tree().quit()


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = maxf(game.simulation.world.surface_height(focus.x, focus.z), 0.0)
	game.camera.apply()
	for frame: int in 25:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)
