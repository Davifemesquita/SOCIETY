extends Node
## Roteiro de verificação visual da Fase 116 (mesas da taverna): na semente 1840, uma taverna na ilha principal (achada
## pelo SiteFinder) com as mesas e os guarda-sóis em volta, de dia (abertos) e à noite (fechados). Precisa de GPU; no PC
## do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase116.tscn -- <pasta>

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
	_set_hour(11.0)
	game.hud.visible = false
	var sim := game.simulation
	var grid := sim.world.island(Simulation.MAIN_ISLAND)
	sim.free_build = true
	var found := SiteFinder.find(sim, &"tavern", Simulation.MAIN_ISLAND, grid.size / 2)
	if found.is_empty():
		push_warning("capture_phase116: sem lugar para a taverna")
		get_tree().quit()
		return
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := sim.execute(PlaceBuildingCommand.new(0, &"tavern", origin, rotation))
	var record := sim.world.building(result.placed[0])
	# a taverna cai às vezes numa mata: derruba as árvores em volta para as mesas aparecerem
	var clearing := Footprint.rect(record.origin, sim.def_of(record).size, record.rotation).grow(5)
	var felled: Array[Vector2i] = []
	for y: int in range(clearing.position.y, clearing.end.y):
		for x: int in range(clearing.position.x, clearing.end.x):
			if grid.in_bounds(Vector2i(x, y)):
				felled.append(Vector2i(x, y))
	if grid.clear_trees(felled):
		EventBus.trees_changed.emit(Simulation.MAIN_ISLAND, clearing)
	await get_tree().process_frame
	var view := game.tavern_garden_view
	view.rebuild()
	print("mesas ", view.table_count())
	var center := grid.rect_world(Footprint.rect(record.origin, sim.def_of(record).size, record.rotation))
	await _shot(game, "mesas.png", center, 30.0, 2.4)
	await _shot(game, "mesas_de_perto.png", center, 13.0, 2.4)
	_set_hour(22.0)
	await _shot(game, "mesas_a_noite.png", center, 16.0, 2.4)
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
