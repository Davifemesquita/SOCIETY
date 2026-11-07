extends Node
## Roteiro de verificação visual da Fase 122 (pedras no rio): na semente 1840, o matacão de rio com a margem mais baixa
## em volta (de qualquer ilha), com as árvores derrubadas para a câmera ver, de longe e de perto. Precisa de GPU; no PC do dono
## roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase122.tscn -- <pasta>

const SEED := 1840
const CLEARING_CELLS := 9

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
	var boulders: Array[Vector3] = []
	for island_id: int in sim.world.islands.size():
		for entry: Array in RiverStoneView.places(sim.world, island_id):
			if entry[2] == RiverStoneView.Kind.BOULDER:
				var place: Transform3D = entry[1]
				boulders.append(place.origin)
	print("pedras ", game.river_stone_view.stone_count(), " matacões ", boulders.size())
	if boulders.is_empty():
		get_tree().quit()
		return
	# o matacão com a margem mais baixa em volta (num rio de garganta as pedras ficam escondidas lá embaixo)
	var best := boulders[0]
	var best_m := INF
	for at: Vector3 in boulders:
		var highest := -INF
		for k: int in 12:
			var angle := TAU * k / 12.0
			highest = maxf(highest, sim.world.surface_height(at.x + cos(angle) * 9.0, at.z + sin(angle) * 9.0))
		if highest < best_m:
			best_m = highest
			best = at
	var grid := sim.world.island(_island_at(sim.world, best))
	var center := grid.world_to_cell(best)
	var clearing := Rect2i(center, Vector2i.ONE).grow(CLEARING_CELLS)
	var felled: Array[Vector2i] = []
	for y: int in range(clearing.position.y, clearing.end.y):
		for x: int in range(clearing.position.x, clearing.end.x):
			if grid.in_bounds(Vector2i(x, y)):
				felled.append(Vector2i(x, y))
	if grid.clear_trees(felled):
		EventBus.trees_changed.emit(_island_at(sim.world, best), clearing)
	for frame: int in 3:
		await get_tree().process_frame
	await _shot(game, "rio.png", best, 28.0, 0.7)
	await _shot(game, "rio_de_perto.png", best, 11.0, 2.0)
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


func _island_at(world: WorldState, at: Vector3) -> int:
	for index: int in world.islands.size():
		if world.island(index).world_rect().has_point(Vector2(at.x, at.z)):
			return index
	return Simulation.MAIN_ISLAND
