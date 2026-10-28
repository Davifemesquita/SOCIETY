extends Node
## Roteiro de verificação visual da Fase 77 (chão e bebedouro no cercado): no mundo plano, um zoológico com os seis
## bichos, cada cercado com o chão do bicho e o bebedouro, de perto em três momentos do passeio e de longe. Precisa de
## GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase77.tscn -- <pasta>

const ZOO := Vector2i(40, 56)
const STEP_S := 20.0

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
	print("zoológico ", zoo.ok(), " ", zoo.reason)
	if not zoo.ok():
		get_tree().quit()
		return
	for def: ExhibitDef in sim.data.exhibits:
		if def.kind == ExhibitDef.Kind.ANIMAL:
			print(def.id, " ", sim.execute(PlaceExhibitCommand.new(def.id, zoo.placed[0])).ok())
	var grid := sim.world.island(Simulation.MAIN_ISLAND)
	var center := grid.cell_world(ZOO + Vector2i(3, 2))
	for k: int in 3:
		# o jogo pausado: o passeio anda só aqui, de STEP_S em STEP_S segundos de jogo
		game.building_view.walk_animals(STEP_S)
		await _shot(game, "cercados_%d.png" % k, center + Vector3(0.0, 0.0, -1.0), 14.0, PI + 0.35)
	await _shot(game, "zoologico.png", center, 24.0, PI)
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
