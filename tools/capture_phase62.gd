extends Node
## Roteiro de verificação visual da Fase 62 (malha fina na face da falésia): na semente 1840, de perto, três trechos de
## falésia seca da ilha principal (os quadrados de maior desnível), com o refinamento ligado e, com "liso" no segundo
## argumento, desligado (para comparar). Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase62.tscn -- <pasta> [liso]

const SEED := 1840

var _out_dir: String


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var smooth := args.size() > 1 and args[1] == "liso"
	if smooth:
		GameConfig.get_default().terrain_cliff_refine_relief_m = 0.0
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = false
	GameScreen.world_seed = SEED
	GameScreen.terrain_version = ArchipelagoGenerator.VERSION_V3
	var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(game)
	GameClock.set_speed(TickClock.PAUSED)
	_set_hour(15.0)
	game.hud.visible = false
	var region := game.terrain_view.region_heights(0)
	var heights: PackedFloat32Array = region["heights"]
	var side: int = region["side"]
	var origin: Vector2 = region["origin"]
	var spacing := GameConfig.get_default().cell_size_m
	# os quadrados secos de maior desnível, um por bloco de 24 cantos (lugares diferentes)
	var best: Dictionary[Vector2i, Vector3] = {}
	for y: int in side - 1:
		for x: int in side - 1:
			if not CoastRefine.steep(heights, side, x, y, 2.4):
				continue
			var a := heights[y * side + x]
			var d := heights[(y + 1) * side + x + 1]
			var relief := absf(a - d) + absf(heights[y * side + x + 1] - heights[(y + 1) * side + x])
			var block := Vector2i(x / 24, y / 24)
			if not best.has(block) or best[block].z < relief:
				best[block] = Vector3(x, y, relief)
	var spots: Array[Vector3] = best.values()
	spots.sort_custom(func(p: Vector3, q: Vector3) -> bool: return p.z > q.z)
	print("trechos de falésia ", spots.size())
	for k: int in mini(spots.size(), 3):
		var at := Vector3(origin.x + spots[k].x * spacing, 0.0, origin.y + spots[k].y * spacing)
		await _shot(game, "%s_%d.png" % ["liso" if smooth else "falesia", k], at, 26.0, 0.5 + k * 2.1)
	GameScreen.terrain_version = -1
	get_tree().quit()


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
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
