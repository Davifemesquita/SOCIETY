extends Node
## Roteiro de verificação visual da Fase 39 (prédios assentados), no arquipélago da semente 1840: uma rua de casas por
## classe (ids seguidos, como o jogador constrói), o entreposto e as casas no barranco, de perto, às 10h (o céu no vidro).
## Precisa de GPU; no PC do dono roda na área de trabalho escondida (F:\ferramentas\desktop_oculto.ps1):
##   godot --path . --resolution 1920x1080 --quit-after 30000 res://tools/capture_phase39.tscn -- <pasta>

const SEED := 1840
const TIERS: Array[StringName] = [&"peasants", &"workers", &"artisans", &"engineers", &"investors"]
const HOUSES_PER_STREET := 8
## A rua de cada classe: 3 células de casa, uma de estrada e um vão (as casas altas não escondem a rua de trás).
const STREET_STEP := 12

var _out_dir: String
var _game: GameScreen
var _sim: Simulation


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = false
	GameScreen.world_seed = SEED
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	GameClock.set_speed(TickClock.PAUSED)
	_run.call_deferred()


func _run() -> void:
	_sim = _game.simulation
	_sim.free_build = true
	var grid := _sim.world.island(0)
	var block := _find_block(grid, Vector2i(HOUSES_PER_STREET * 3 + 2, TIERS.size() * STREET_STEP + 1))
	var streets: Array[Vector2i] = []
	for row: int in TIERS.size():
		var street_y := block.y + row * STREET_STEP + 3
		_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(block.x, street_y),
				Vector2i(block.x + HOUSES_PER_STREET * 3 + 1, street_y))))
		for i: int in HOUSES_PER_STREET:
			var result := _sim.execute(PlaceBuildingCommand.new(0, &"house", Vector2i(block.x + 1 + i * 3, street_y - 3), 2))
			if result.ok():
				_sim.world.building(result.placed[0]).tier = TIERS[row]
		streets.append(Vector2i(block.x + HOUSES_PER_STREET * 3 / 2, street_y))
	var post := SiteFinder.find(_sim, &"trading_post", 0, Vector2i(grid.size.x / 2, 0))
	var post_origin: Vector2i = post[0]
	var post_rotation: int = post[1]
	_sim.execute(PlaceBuildingCommand.new(0, &"trading_post", post_origin, post_rotation))
	# as classes mudadas à mão: refaz os modelos de uma vez (sem o andaime da subida de classe)
	_game.building_view.rebuild()
	_set_hour(10.0)
	for row: int in TIERS.size():
		# a rua fica na frente das casas (rotação 2: frente em +z da grade); as duas tomadas, da rua e dos fundos
		var at := grid.cell_world(streets[row] + Vector2i(0, -2))
		await _shot("rua_%s_a.png" % TIERS[row], at, 48.0, 0.0)
		await _shot("rua_%s_b.png" % TIERS[row], at, 48.0, PI)
	await _shot("ruas_de_cima.png", grid.cell_world(streets[2]), 150.0, 0.0)
	await _shot("entreposto_a.png", grid.cell_world(post_origin + Vector2i(3, 3)), 70.0, 0.0)
	await _shot("entreposto_b.png", grid.cell_world(post_origin + Vector2i(3, 3)), 70.0, PI)
	var sloped := _sloped_house()
	if sloped != Vector3.INF:
		await _shot("casa_no_barranco_a.png", sloped, 55.0, 0.0)
		await _shot("casa_no_barranco_b.png", sloped, 55.0, PI)
	get_tree().quit()


## O canto de um bloco de células todo em terra e quase plano (cada lote de casa dentro do desnível construível).
func _find_block(grid: IslandGrid, size: Vector2i) -> Vector2i:
	var center := grid.size / 2
	var best := Vector2i(4, 4)
	var best_gap := INF
	for y: int in range(4, grid.size.y - size.y - 4, 3):
		for x: int in range(4, grid.size.x - size.x - 4, 3):
			var area := Rect2i(Vector2i(x, y), size)
			if not grid.area_is_land(area) or grid.area_relief(area) > _sim.config.max_build_height_delta_m * 2.0:
				continue
			var gap := Vector2(Vector2i(x, y) + size / 2 - center).length()
			if gap < best_gap:
				best = Vector2i(x, y)
				best_gap = gap
	return best


## Uma casa da vila com plinto (a do barranco), ou INF.
func _sloped_house() -> Vector3:
	var view := _game.building_view
	for id: int in _sim.world.building_ids():
		var part := view.plinth_of(id)
		if not part.is_empty():
			var place: Transform3D = part[1]
			return view.to_global(place.origin)
	return Vector3.INF


func _shot(file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := _game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = _sim.world.surface_height(focus.x, focus.z)
	_game.camera.camera.far = maxf(4000.0, distance * 3.0)
	_game.camera.apply()
	for frame: int in 24:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
