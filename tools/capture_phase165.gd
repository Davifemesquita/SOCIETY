extends Node
## Roteiro de verificação visual da Fase 165 (chão batido das fábricas): na semente 1840, uma olaria na ilha principal (achada
## pelo SiteFinder) com o chão de terra batida em volta, de meia distância e de perto.
## Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase165.tscn -- <pasta>

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
	var focus := Vector3.ZERO
	# a câmera do lado de fora do pátio (o offset da câmera é (sen yaw, ·, cos yaw))
	var outward := 0.6
	var found := SiteFinder.find(sim, &"brickworks", Simulation.MAIN_ISLAND, grid.size / 2)
	if not found.is_empty():
		var origin: Vector2i = found[0]
		var rotation: int = found[1]
		var def := sim.data.building(&"brickworks")
		var area := Footprint.rect(origin, def.size, rotation)
		# derruba as árvores em volta, para o pátio ter lugar e a câmera ver
		var clearing := area.grow(12)
		var felled: Array[Vector2i] = []
		for y: int in range(clearing.position.y, clearing.end.y):
			for x: int in range(clearing.position.x, clearing.end.x):
				if grid.in_bounds(Vector2i(x, y)):
					felled.append(Vector2i(x, y))
		if grid.clear_trees(felled):
			EventBus.trees_changed.emit(Simulation.MAIN_ISLAND, clearing)
		var result := sim.execute(PlaceBuildingCommand.new(0, &"brickworks", origin, rotation))
		if result.ok():
			var id: int = result.placed[0]
			await get_tree().process_frame
			game.brick_yard_view.rebuild()
			var sites := BrickYardView.sites(sim.world, sim.data, Simulation.MAIN_ISLAND)
			if sites.has(id):
				var site: Array = sites[id]
				var middle: Vector2i = site[0]
				focus = grid.surface_world(middle)
				var side: Vector2i = site[1]
				outward = atan2(float(side.x), float(side.y))
			else:
				focus = grid.rect_world(area)
	print("pátios: ", game.brick_yard_view.yard_count())
	await _shot(game, "chao_batido.png", focus, 30.0, outward + 0.5)
	await _shot(game, "chao_batido_de_perto.png", focus, 9.0, outward + 0.7)
	await _shot(game, "chao_batido_do_outro_lado.png", focus, 9.0, outward - 0.7)
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
