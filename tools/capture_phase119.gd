extends Node
## Roteiro de verificação visual da Fase 119 (poças de luz à noite): na semente 1840, uma rua calçada num descampado da ilha
## principal, com casas de operários de um lado, às 22h: as poças dos postes na rua e as das portas das casas. Precisa de
## GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase119.tscn -- <pasta>

const SEED := 1840
const HOUSES := 6

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
	_set_hour(22.0)
	game.hud.visible = false
	var sim := game.simulation
	var grid := sim.world.island(Simulation.MAIN_ISLAND)
	var base := _open_ground(grid)
	print("rua em ", base)
	sim.free_build = true
	sim.ignore_terrain = true
	sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(base + Vector2i(-2, 4), base + Vector2i(HOUSES * 4 + 1, 4)), true))
	for i: int in HOUSES:
		var result := sim.execute(PlaceBuildingCommand.new(0, &"house", base + Vector2i(i * 4, 1), 2))
		if result.ok():
			var record := sim.world.building(result.placed[0])
			record.tier = &"workers"
			record.residents = 5.0
	game.building_view.rebuild()
	for frame: int in 10:
		await get_tree().process_frame
	print("poças ", game.light_pool_view.pool_count())
	var street := grid.cell_world(base + Vector2i(HOUSES * 2, 4))
	await _shot(game, "pocas.png", street, 30.0, 0.5)
	await _shot(game, "pocas_de_perto.png", street, 14.0, 1.2)
	# a mesma rua de cima, com e sem as poças, para comparar (as árvores da alameda escondem a rua de lado)
	await _shot(game, "pocas_de_cima.png", street, 40.0, 0.0)
	game.light_pool_view.visible = false
	await _shot(game, "sem_pocas_de_cima.png", street, 40.0, 0.0)
	get_tree().quit()


## Um descampado para a rua (terra sem árvore nem água, o mais perto do meio da ilha): HOUSES × 4 + 4 por 8 células.
func _open_ground(grid: IslandGrid) -> Vector2i:
	var size := Vector2i(HOUSES * 4 + 4, 8)
	var best := grid.size / 2
	var best_distance := INF
	for y: int in range(2, grid.size.y - size.y - 2, 2):
		for x: int in range(2, grid.size.x - size.x - 2, 2):
			var open := true
			for dy: int in size.y:
				for dx: int in size.x:
					var index := grid.index(Vector2i(x + dx, y + dy))
					if grid.ground[index] != IslandGrid.Ground.LAND or grid.trees[index] > 0:
						open = false
						break
				if not open:
					break
			var distance := Vector2(x, y).distance_to(Vector2(grid.size / 2))
			if open and distance < best_distance:
				best_distance = distance
				best = Vector2i(x + 2, y + 1)
	return best


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
