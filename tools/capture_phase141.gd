extends Node
## Roteiro de verificação visual da Fase 141 (árvore seca): na semente 1840, as árvores secas do recheio da ilha principal
## mais perto do meio dela, uma da beira da mata e uma da costa se houver, às 10h. Precisa de GPU; no PC do dono roda na
## área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase141.tscn -- <pasta>

const SEED := 1840
const SHOTS := 3

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
	var middle := grid.rect_world(Rect2i(Vector2i.ZERO, grid.size))
	var snags: Array[Vector3] = []
	for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
		for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
			var items := ScatterView.places(sim.world, sim.data, sim.config, Simulation.MAIN_ISLAND, Vector2i(cx, cy))
			for item: Array in items[ScatterView.Kind.SNAG]:
				var place: Transform3D = item[0]
				snags.append(place.origin)
	snags.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.distance_to(middle) < b.distance_to(middle))
	print("árvores secas ", snags.size())
	for shot: int in mini(SHOTS, snags.size()):
		await _shot(game, "arvore_seca_%d.png" % shot, snags[shot], 13.0, 0.5 + shot * 1.7, 4.0)
	get_tree().quit()


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float, pitch: float) -> void:
	var rig := game.camera.rig
	rig.pitch_offset_deg = pitch
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.target_distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = maxf(game.simulation.world.surface_height(focus.x, focus.z), 0.0)
	game.camera.apply()
	for frame: int in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
