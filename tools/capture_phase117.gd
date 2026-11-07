extends Node
## Roteiro de verificação visual da Fase 117 (silos das fazendas): na semente 1840, fazendas na ilha principal (achadas
## pelo SiteFinder) com o silo ou a caixa d'água ao lado de cada uma, vistas pelos fundos. Precisa de GPU; no PC do dono
## roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase117.tscn -- <pasta>

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
	var centers: Array[Vector3] = []
	var near := grid.size / 2
	for def_id: StringName in [&"wheat_farm", &"potato_farm", &"sheep_farm"]:
		var found := SiteFinder.find(sim, def_id, Simulation.MAIN_ISLAND, near)
		if found.is_empty():
			continue
		var origin: Vector2i = found[0]
		var rotation: int = found[1]
		var result := sim.execute(PlaceBuildingCommand.new(0, def_id, origin, rotation))
		if not result.ok():
			continue
		var record := sim.world.building(result.placed[0])
		var area := Footprint.rect(record.origin, sim.def_of(record).size, record.rotation)
		# as fazendas caem às vezes numa mata: derruba as árvores em volta
		var clearing := area.grow(5)
		var felled: Array[Vector2i] = []
		for y: int in range(clearing.position.y, clearing.end.y):
			for x: int in range(clearing.position.x, clearing.end.x):
				if grid.in_bounds(Vector2i(x, y)):
					felled.append(Vector2i(x, y))
		if grid.clear_trees(felled):
			EventBus.trees_changed.emit(Simulation.MAIN_ISLAND, clearing)
		centers.append(grid.rect_world(area))
		near = origin + Vector2i(8, 0)
	await get_tree().process_frame
	var view := game.farm_silo_view
	view.rebuild()
	print("silos ", view.count(FarmSiloView.Kind.SILO), " caixas ", view.count(FarmSiloView.Kind.TANK))
	for i: int in centers.size():
		await _shot(game, "fazenda_%d.png" % i, centers[i], 24.0, 5.5)
	if not centers.is_empty():
		await _shot(game, "fazenda_de_perto.png", centers[0], 14.0, 5.9)
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
