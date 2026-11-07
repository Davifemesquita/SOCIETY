extends Node
## Roteiro de verificação visual da Fase 139 (redes de pesca): na semente 1840, uma cabana de pesca na costa da ilha
## principal (achada pelo SiteFinder), com as árvores em volta derrubadas, às 10h: de longe e de perto das redes. Precisa
## de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase139.tscn -- <pasta>

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
	var found := SiteFinder.find(sim, &"fishery", Simulation.MAIN_ISLAND, grid.size / 2)
	if found.is_empty():
		push_warning("capture_phase139: sem lugar para a cabana de pesca")
		get_tree().quit()
		return
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	# as árvores em volta caem para as redes terem lugar e a câmera ver
	var clearing := Rect2i(origin, Vector2i(3, 3)).grow(5)
	var felled: Array[Vector2i] = []
	for y: int in range(clearing.position.y, clearing.end.y):
		for x: int in range(clearing.position.x, clearing.end.x):
			if grid.in_bounds(Vector2i(x, y)):
				felled.append(Vector2i(x, y))
	if grid.clear_trees(felled):
		EventBus.trees_changed.emit(Simulation.MAIN_ISLAND, clearing)
	var result := sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"fishery", origin, rotation))
	var record := sim.world.building(result.placed[0])
	for frame: int in 3:
		await get_tree().process_frame
	var sites := FishNetView.sites(sim.world, sim.data, Simulation.MAIN_ISLAND)
	print("redes ", game.fish_net_view.site_count())
	if sites.is_empty():
		get_tree().quit()
		return
	var cell: Vector2i = sites.keys()[0]
	var site: Array = sites[cell]
	var out: Vector3 = site[0]
	var at := grid.cell_world(cell)
	var center := grid.rect_world(Footprint.rect(record.origin, sim.def_of(record).size, record.rotation))
	# de longe, do lado do mar, olhando a cabana e as redes na costa
	await _shot(game, "redes.png", (at + center) * 0.5, 18.0, atan2(out.x, out.z) + 0.5, 12.0)
	await _shot(game, "redes_de_perto.png", at, 6.0, atan2(-out.x, -out.z) + 0.9, 10.0)
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
