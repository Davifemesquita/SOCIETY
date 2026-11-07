extends Node
## Roteiro de verificação visual da Fase 60 (sub-bosque tropical): na semente 1840, de perto, bananeiras e samambaias
## que o recheio pôs numa ilha tropical. Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase60.tscn -- <pasta> [heliconia]
## Com "heliconia" (Fase 61), as helicônias de perto no lugar das bananeiras.

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
	GameScreen.terrain_version = ArchipelagoGenerator.VERSION_V3
	var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(game)
	GameClock.set_speed(TickClock.PAUSED)
	_set_hour(11.0)
	game.hud.visible = false
	var world := game.simulation.world
	# a peça procurada sai do segundo argumento ("heliconia" para a Fase 61); sem ele, a bananeira
	var args := OS.get_cmdline_user_args()
	var kind := ScatterView.Kind.HELICONIA if args.size() > 1 and args[1] == "heliconia" else ScatterView.Kind.BANANA
	var spots: Array[Vector3] = []
	for index: int in world.islands.size():
		if not world.is_tropical(index, game.simulation.data) or world.island(index).flat:
			continue
		var grid := world.island(index)
		for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
			for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
				var items := game.scatter_view.chunk_items(index, Vector2i(cx, cy))
				var found: Array = items.get(kind, [])
				for item: Array in found:
					var place: Transform3D = item[0]
					spots.append(place.origin)
	print("peças ", spots.size())
	var prefix := "heliconia" if kind == ScatterView.Kind.HELICONIA else "sub_bosque"
	var distance := 9.0 if kind == ScatterView.Kind.HELICONIA else 16.0
	for k: int in mini(spots.size(), 3):
		await _shot(game, "%s_%d.png" % [prefix, k], spots[k * (spots.size() / 3)], distance, 0.6 + k * 2.0)
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
