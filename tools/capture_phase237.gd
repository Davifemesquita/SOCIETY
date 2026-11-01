extends Node
## Roteiro de verificação visual da Fase 237 (marco de légua): na semente 1840, estradas de terra retas e compridas no
## campo da ilha principal, longe de casa; o marco de perto (a câmera posta à mão) e de meia distância.
## Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase237.tscn -- <pasta>

const SEED := 1840
const ROAD_CELLS := 30

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
	# um lugar livre e plano no meio: o do mercado (3×3) que o SiteFinder achar perto do meio
	var found := SiteFinder.find(sim, &"market", Simulation.MAIN_ISLAND, grid.size / 2)
	var center := grid.size / 2
	if not found.is_empty():
		var origin: Vector2i = found[0]
		center = origin + Vector2i(1, 1)
	# estradas retas de ROAD_CELLS células ao longo de x, nas fileiras em volta do meio em que o relevo deixa, até três com marco
	var built := 0
	for row: int in range(-60, 61, 4):
		for start: int in range(-70, 41, 6):
			if built >= 3:
				break
			var before := MilestoneView.stones(sim.world, sim.data, Simulation.MAIN_ISLAND).size()
			var from := center + Vector2i(start, row)
			var result := sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(from, from + Vector2i(ROAD_CELLS, 0))))
			if result.ok() and MilestoneView.stones(sim.world, sim.data, Simulation.MAIN_ISLAND).size() > before:
				built += 1
				break
	await get_tree().process_frame
	game.milestone_view.rebuild()
	print("marcos: ", game.milestone_view.stone_count())
	var shot := 0
	for post: Transform3D in game.milestone_view.places:
		var side := atan2(post.basis.z.x, post.basis.z.z)
		await _aimed(game, "marco_%d.png" % shot, post.origin + Vector3(0.0, 0.45, 0.0), 2.2, side + 0.5)
		await _aimed(game, "marco_%d_longe.png" % shot, post.origin + Vector3(0.0, 0.5, 0.0), 12.0, side + 0.9)
		if shot >= 2:
			break
		shot += 1
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
