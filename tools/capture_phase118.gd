extends Node
## Roteiro de verificação visual da Fase 118 (chão gasto no pasto): na semente 1840, uma fazenda de ovelhas e dois pastos
## na ilha principal (achados pelo SiteFinder), com as manchas de terra pisada e o cocho. Precisa de GPU; no PC do dono
## roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase118.tscn -- <pasta>

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
	var found := SiteFinder.find(sim, &"sheep_farm", Simulation.MAIN_ISLAND, grid.size / 2)
	if found.is_empty():
		get_tree().quit()
		return
	var farm_origin: Vector2i = found[0]
	var farm_rotation: int = found[1]
	sim.execute(PlaceBuildingCommand.new(0, &"sheep_farm", farm_origin, farm_rotation))
	var pastures: Array[Vector3] = []
	for k: int in 2:
		var spot := SiteFinder.find(sim, &"pasture", Simulation.MAIN_ISLAND, farm_origin + Vector2i(4, 0))
		if spot.is_empty():
			break
		var origin: Vector2i = spot[0]
		var rotation: int = spot[1]
		var result := sim.execute(PlaceBuildingCommand.new(0, &"pasture", origin, rotation))
		if not result.ok():
			break
		var record := sim.world.building(result.placed[0])
		pastures.append(grid.rect_world(Footprint.rect(record.origin, sim.def_of(record).size, record.rotation)))
	# os pastos caem às vezes numa mata: derruba as árvores em volta
	var clearing := Rect2i(farm_origin, Vector2i.ONE).grow(16)
	var felled: Array[Vector2i] = []
	for y: int in range(clearing.position.y, clearing.end.y):
		for x: int in range(clearing.position.x, clearing.end.x):
			if grid.in_bounds(Vector2i(x, y)):
				felled.append(Vector2i(x, y))
	if grid.clear_trees(felled):
		EventBus.trees_changed.emit(Simulation.MAIN_ISLAND, clearing)
	for frame: int in 3:
		await get_tree().process_frame
	print("cochos ", game.pasture_trough_view.trough_count())
	if pastures.is_empty():
		get_tree().quit()
		return
	await _shot(game, "pasto.png", pastures[0], 22.0, 2.4)
	await _shot(game, "pasto_de_perto.png", pastures[0], 11.0, 0.9)
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
