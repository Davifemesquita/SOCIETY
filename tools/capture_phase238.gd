extends Node
## Roteiro de verificação visual da Fase 238 (bandeira na prefeitura): na semente 1840, a prefeitura no lugar que o SiteFinder
## achar perto do meio da ilha principal; a bandeira no alto da cúpula de perto e de meia distância, de dois lados (a câmera
## posta à mão). Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase238.tscn -- <pasta>

const SEED := 1840

var _out_dir: String


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_run.call_deferred()


func _run() -> void:
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = false
	GameScreen.world_seed = SEED
	var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(game)
	GameClock.set_speed(TickClock.PAUSED)
	_set_hour(10.0)
	game.hud.visible = false
	var sim := game.simulation
	var grid := sim.world.island(Simulation.MAIN_ISLAND)
	sim.free_build = true
	var found := SiteFinder.find(sim, &"town_hall", Simulation.MAIN_ISLAND, grid.size / 2)
	if not found.is_empty():
		var origin: Vector2i = found[0]
		var rotation: int = found[1]
		sim.execute(PlaceBuildingCommand.new(0, &"town_hall", origin, rotation))
	await get_tree().process_frame
	game.town_flag_view.rebuild()
	print("bandeiras: ", game.town_flag_view.flag_count())
	if not game.town_flag_view.places.is_empty():
		var foot := game.town_flag_view.places[0]
		var flag := foot + Vector3(0.0, TownFlagView.POLE_M - 1.0, 0.0)
		await _aimed(game, "bandeira_perto.png", flag, 7.0, 0.6)
		await _aimed(game, "bandeira_outro_lado.png", flag, 7.0, 0.6 + PI)
		await _aimed(game, "bandeira_longe.png", foot - Vector3(0.0, 6.0, 0.0), 32.0, 1.1)
	get_tree().quit()


## Põe a Camera3D à mão, um pouco acima do ponto, a distance metros dele no rumo yaw (o offset da câmera é (sen, ·, cos)).
func _aimed(game: GameScreen, file_name: String, at: Vector3, distance: float, yaw: float) -> void:
	game.camera.set_process(false)
	var eye := at + Vector3(sin(yaw), 0.35, cos(yaw)).normalized() * distance
	game.camera.camera.global_transform = Transform3D(Basis.looking_at(at - eye, Vector3.UP), eye)
	for frame: int in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)
	game.camera.set_process(true)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
