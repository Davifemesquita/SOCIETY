extends Node
## Roteiro de verificação visual da Fase 179 (juncos na margem): na semente 1840, as touceiras de junco da ilha principal
## (achadas pelo próprio recheio), de perto e de meia distância, olhando da terra para o rio. Precisa de GPU; no PC do dono
## roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase179.tscn -- <pasta>

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
	var context := ScatterView.island_context(sim.world, sim.data, Simulation.MAIN_ISLAND)
	var reeds: Array[Vector3] = []
	for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
		for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
			var items := ScatterView.places(sim.world, sim.data, sim.config, Simulation.MAIN_ISLAND, Vector2i(cx, cy), context)
			var list: Array = items[ScatterView.Kind.REEDS]
			for item: Array in list:
				var place: Transform3D = item[0]
				reeds.append(place.origin)
	print("juncos na principal: ", reeds.size())
	var shot := 0
	var used: Array[Vector3] = []
	for at: Vector3 in reeds:
		var far := true
		for other: Vector3 in used:
			if other.distance_to(at) < 60.0:
				far = false
		if not far:
			continue
		used.append(at)
		# de costas para a terra: o rio fica do lado mais baixo
		var cell := grid.world_to_cell(at)
		var toward := Vector3.ZERO
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if grid.in_bounds(cell + step) and grid.ground_at(cell + step) == IslandGrid.Ground.RIVER:
				toward = Vector3(step.x, 0.0, step.y)
		var yaw := atan2(-toward.x, -toward.z)
		await _shot(game, "juncos_%d.png" % shot, at, 9.0, yaw + 0.3)
		await _shot(game, "juncos_%d_longe.png" % shot, at, 26.0, yaw + 0.3)
		shot += 1
		if shot >= 3:
			break
	get_tree().quit()


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := game.camera.rig
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
