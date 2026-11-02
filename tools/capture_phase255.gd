extends Node
## Roteiro de verificação visual do ciclo da cor viva (Fases 255 a 259): na semente 1840, uma vila de duas ruas (casas de
## camponeses, operários, artesãos e engenheiros, o mercado, a igreja, a taverna e uma fazenda com os campos) num lugar plano
## da ilha principal; de cima e de perto, os campos, a enseada e a ilha inteira, às 10h30. As mesmas vistas antes e depois de
## cada fase, para comparar a cor. Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 60000 res://tools/capture_phase255.tscn -- <pasta>

const SEED := 1840
const AREA := Vector2i(40, 28)
const TIERS: Array[StringName] = [&"peasants", &"workers", &"artisans", &"engineers"]

var _out_dir: String


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_run.call_deferred()


func _run() -> void:
	var game := _open_game()
	var points: Array[Vector3] = await _build_town(game)
	await _shot(game, "01_vila_de_cima.png", points[0], 110.0, 0.6)
	await _shot(game, "02_vila_de_perto.png", points[0], 42.0, 0.6)
	await _shot(game, "03_campos.png", points[1], 70.0, 0.9)
	await _shot(game, "04_enseada.png", points[2], 140.0, 0.3)
	await _shot(game, "05_ilha.png", points[3], 520.0, 0.3)
	get_tree().quit()


func _open_game() -> GameScreen:
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = false
	GameScreen.world_seed = SEED
	var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(game)
	GameClock.set_speed(TickClock.PAUSED)
	_set_hour(10.5)
	game.hud.visible = false
	return game


## A vila de duas ruas no lugar plano mais perto do meio da ilha principal; devolve os pontos das vistas (a vila,
## os campos, a praia e o meio da ilha).
func _build_town(game: GameScreen) -> Array[Vector3]:
	var sim := game.simulation
	var grid := sim.world.island(Simulation.MAIN_ISLAND)
	var base := _open_ground(grid)
	print("vila em ", base)
	sim.free_build = true
	sim.ignore_terrain = true
	_road(sim, base + Vector2i(0, 6), base + Vector2i(AREA.x - 1, 6), true)
	_road(sim, base + Vector2i(0, 16), base + Vector2i(AREA.x - 1, 16), false)
	_road(sim, base + Vector2i(20, 0), base + Vector2i(20, AREA.y - 1), false)
	var houses: Array[int] = []
	for x: int in range(0, 18, 3):
		houses.append(_place(sim, &"house", base + Vector2i(x, 3), 2))
		houses.append(_place(sim, &"house", base + Vector2i(x, 7), 0))
		houses.append(_place(sim, &"house", base + Vector2i(x, 13), 2))
	for x: int in range(22, 40, 3):
		houses.append(_place(sim, &"house", base + Vector2i(x, 3), 2))
	_place(sim, &"market", base + Vector2i(22, 7), 0)
	_place(sim, &"church", base + Vector2i(30, 7), 0)
	_place(sim, &"tavern", base + Vector2i(22, 12), 2)
	_farm(sim, &"potato_farm", base + Vector2i(4, 17))
	_farm(sim, &"wheat_farm", base + Vector2i(24, 17))
	var i := 0
	for id: int in houses:
		if id == 0:
			continue
		var record := sim.world.building(id)
		record.tier = TIERS[(i / 3) % TIERS.size()]
		record.residents = 5.0
		i += 1
	game.building_view.rebuild()
	for frame: int in 10:
		await get_tree().process_frame
	return [grid.cell_world(base + Vector2i(AREA.x / 2, 9)), grid.cell_world(base + Vector2i(AREA.x / 2, 22)),
			grid.cell_world(_find_beach(grid)), grid.cell_world(grid.size / 2)]


func _place(sim: Simulation, def_id: StringName, origin: Vector2i, rotation: int = 0) -> int:
	var result := sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, def_id, origin, rotation))
	return result.placed[0] if result.ok() else 0


func _road(sim: Simulation, from: Vector2i, to: Vector2i, paved: bool) -> void:
	sim.execute(BuildRoadCommand.new(Simulation.MAIN_ISLAND, RoadPath.l_path(from, to), paved))


func _farm(sim: Simulation, def_id: StringName, origin: Vector2i) -> void:
	_place(sim, def_id, origin)
	var def := sim.data.building(def_id)
	var reach := Footprint.rect(origin, def.size, 0).grow(def.module_radius_cells)
	var placed := 0
	for y: int in range(reach.position.y, reach.end.y - 2):
		for x: int in range(reach.position.x, reach.end.x - 2):
			if placed < def.modules_required and _place(sim, def.module_id, Vector2i(x, y)) != 0:
				placed += 1


## O lugar plano e aberto (terra sem árvore nem água, desnível até 1,2 m) de AREA células mais perto do meio da ilha.
func _open_ground(grid: IslandGrid) -> Vector2i:
	var middle := grid.size / 2
	var candidates: Array[Vector2i] = []
	for y: int in range(2, grid.size.y - AREA.y - 2, 2):
		for x: int in range(2, grid.size.x - AREA.x - 2, 2):
			candidates.append(Vector2i(x, y))
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (a + AREA / 2 - middle).length_squared() < (b + AREA / 2 - middle).length_squared())
	for origin: Vector2i in candidates:
		if _open(grid, origin):
			return origin
	return middle - AREA / 2


func _open(grid: IslandGrid, origin: Vector2i) -> bool:
	var low := INF
	var high := -INF
	for dy: int in range(0, AREA.y, 2):
		for dx: int in range(0, AREA.x, 2):
			var cell := origin + Vector2i(dx, dy)
			var index := grid.index(cell)
			if grid.ground[index] != IslandGrid.Ground.LAND or grid.trees[index] > 0:
				return false
			var height := grid.cell_height(cell)
			low = minf(low, height)
			high = maxf(high, height)
			if high - low > 1.2:
				return false
	return true


## Uma célula de praia (terra baixa encostada no mar), a mais perto do meio da ilha.
func _find_beach(grid: IslandGrid) -> Vector2i:
	var best := grid.size / 2
	var best_score := INF
	for y: int in range(2, grid.size.y - 2, 2):
		for x: int in range(2, grid.size.x - 2, 2):
			var cell := Vector2i(x, y)
			if not grid.is_land(cell) or grid.cell_height(cell) > 1.5:
				continue
			var coastal := false
			for step: Vector2i in [Vector2i(3, 0), Vector2i(-3, 0), Vector2i(0, 3), Vector2i(0, -3)]:
				if grid.ground_at(cell + step) == IslandGrid.Ground.SEA:
					coastal = true
			var score := Vector2(cell - grid.size / 2).length()
			if coastal and score < best_score:
				best_score = score
				best = cell
	return best


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = maxf(game.simulation.world.surface_height(focus.x, focus.z), 0.0)
	game.camera.camera.far = maxf(4000.0, distance * 3.0)
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
