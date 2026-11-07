extends Node
## Roteiro de verificação visual da Fase 74 (recintos e vitrines): no mundo plano, um zoológico com os seis bichos e um
## museu com as seis peças, de perto e de longe. Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase74.tscn -- <pasta>

const ZOO := Vector2i(40, 56)
const MUSEUM := Vector2i(52, 57)

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
	var zoo := sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"zoo", ZOO, 0))
	var museum := sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"museum", MUSEUM, 0))
	print("zoológico ", zoo.ok(), " ", zoo.reason, " museu ", museum.ok(), " ", museum.reason)
	if not zoo.ok() or not museum.ok():
		get_tree().quit()
		return
	for def: ExhibitDef in sim.data.exhibits:
		var hall: int = zoo.placed[0] if def.kind == ExhibitDef.Kind.ANIMAL else museum.placed[0]
		print(def.id, " ", sim.execute(PlaceExhibitCommand.new(def.id, hall)).ok())
	var grid := sim.world.island(Simulation.MAIN_ISLAND)
	var zoo_center := grid.cell_world(ZOO + Vector2i(3, 2))
	var museum_center := grid.cell_world(MUSEUM + Vector2i(2, 1))
	await _shot(game, "zoologico.png", zoo_center, 22.0, PI)
	await _shot(game, "zoologico_perto.png", zoo_center + Vector3(-3.0, 0.0, -1.0), 10.0, PI + 0.5)
	await _shot(game, "museu.png", museum_center, 16.0, PI + 0.3)
	await _shot(game, "os_dois.png", (zoo_center + museum_center) * 0.5, 50.0, PI - 0.4)
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
