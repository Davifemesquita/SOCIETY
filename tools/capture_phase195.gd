extends Node
## Roteiro de verificação visual da Fase 195 (cemitério da igreja): na semente 1840, num descampado da ilha principal, a
## igreja de frente para uma rua, com o largo e o cemitério atrás. Precisa de GPU; no PC do dono roda na área de trabalho
## escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase195.tscn -- <pasta>

const SEED := 1840
const OPEN := Vector2i(14, 16)

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
	var base := _open_ground(grid)
	print("descampado em ", base)
	sim.free_build = true
	sim.ignore_terrain = true
	# a rua ao sul e a igreja virada para ela (rotação 2: a frente para +Z), o cemitério fica ao norte
	var road_y := base.y + OPEN.y - 2
	sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(base.x, road_y), Vector2i(base.x + OPEN.x - 1, road_y))))
	var size := Footprint.rotated_size(sim.data.building(&"church").size, 2)
	var church := Vector2i(base.x + (OPEN.x - size.x) / 2, road_y - size.y)
	sim.execute(PlaceBuildingCommand.new(0, &"church", church, 2))
	game.building_view.rebuild()
	for frame: int in 10:
		await get_tree().process_frame
	print("covas ", game.graveyard_view.grave_count(), " muro ", game.graveyard_view.wall_places.size())
	var yard := grid.cell_world(church + Vector2i(size.x / 2, -3))
	await _shot(game, "cemiterio.png", yard, 30.0, PI + 0.5)
	await _shot(game, "cemiterio_de_perto.png", yard, 14.0, PI - 0.6)
	await _shot(game, "cemiterio_pela_rua.png", grid.cell_world(church + Vector2i(size.x / 2, 2)), 40.0, 0.3)
	get_tree().quit()


## Um descampado (terra sem árvore nem água, o mais perto do meio da ilha) de OPEN células.
func _open_ground(grid: IslandGrid) -> Vector2i:
	var best := grid.size / 2
	var best_distance := INF
	for y: int in range(2, grid.size.y - OPEN.y - 2, 2):
		for x: int in range(2, grid.size.x - OPEN.x - 2, 2):
			var open := true
			for dy: int in OPEN.y:
				for dx: int in OPEN.x:
					var index := grid.index(Vector2i(x + dx, y + dy))
					if grid.ground[index] != IslandGrid.Ground.LAND or grid.trees[index] > 0:
						open = false
						break
				if not open:
					break
			var distance := Vector2(x, y).distance_to(Vector2(grid.size / 2))
			if open and distance < best_distance:
				best_distance = distance
				best = Vector2i(x, y)
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
