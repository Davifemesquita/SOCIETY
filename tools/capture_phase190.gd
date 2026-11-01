extends Node
## Roteiro de verificação visual da Fase 190 (colmeias de palha): na semente 1840, fazendas de batata, lúpulo, trigo e ovelhas
## na ilha principal (achadas pelo SiteFinder, com as árvores em volta derrubadas) e as colmeias ao lado das de batata e lúpulo,
## de perto e de meia distância. As capturas das Fases 191 (pombal) e 193 (carroça de feno) herdam este roteiro e trocam só as
## fotos (`_shoot`). Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase190.tscn -- <pasta>

const SEED := 1840
const FARMS: Array[StringName] = [&"potato_farm", &"hop_farm", &"wheat_farm", &"sheep_farm", &"wheat_farm", &"pig_farm"]

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
	var near := grid.size / 2
	for def_id: StringName in FARMS:
		var found := SiteFinder.find(sim, def_id, Simulation.MAIN_ISLAND, near)
		if found.is_empty():
			continue
		var origin: Vector2i = found[0]
		var rotation: int = found[1]
		var area := Footprint.rect(origin, sim.data.building(def_id).size, rotation)
		var clearing := area.grow(6)
		var felled: Array[Vector2i] = []
		for y: int in range(clearing.position.y, clearing.end.y):
			for x: int in range(clearing.position.x, clearing.end.x):
				if grid.in_bounds(Vector2i(x, y)):
					felled.append(Vector2i(x, y))
		if grid.clear_trees(felled):
			EventBus.trees_changed.emit(Simulation.MAIN_ISLAND, clearing)
		sim.execute(PlaceBuildingCommand.new(0, def_id, origin, rotation))
		near = origin + Vector2i(11, 3)
	for frame: int in 3:
		await get_tree().process_frame
	await _shoot(game)
	get_tree().quit()


func _shoot(game: GameScreen) -> void:
	game.beehive_view.rebuild()
	print("colmeias: ", game.beehive_view.hive_count())
	var shot := 0
	for place: Transform3D in game.beehive_view.places:
		var yaw := _away_from_farm(game, place.origin)
		await _aimed(game, "colmeias_%d.png" % shot, place.origin + Vector3(0.0, 0.6, 0.0), 4.0, yaw + 0.35)
		await _aimed(game, "colmeias_%d_longe.png" % shot, place.origin + Vector3(0.0, 1.0, 0.0), 13.0, yaw + 0.5)
		shot += 1


## O rumo da câmera (o offset é (sen, ·, cos)) para o lado de fora do prédio mais perto do ponto: a câmera não cai na parede.
func _away_from_farm(game: GameScreen, at: Vector3) -> float:
	var sim := game.simulation
	var best := Vector3.ZERO
	var best_m := INF
	for id: int in sim.world.building_ids():
		var record := sim.world.building(id)
		var grid := sim.world.island(record.island_id)
		var middle := grid.rect_world(Footprint.rect(record.origin, sim.def_of(record).size, record.rotation))
		if middle.distance_to(at) < best_m:
			best_m = middle.distance_to(at)
			best = middle
	var away := at - best
	return atan2(away.x, away.z)


## Põe a Camera3D à mão, um pouco acima do ponto, a distance metros dele no rumo yaw (o offset da câmera é (sen, ·, cos)).
func _aimed(game: GameScreen, file_name: String, at: Vector3, distance: float, yaw: float) -> void:
	game.camera.set_process(false)
	var eye := at + Vector3(sin(yaw), 0.45, cos(yaw)).normalized() * distance
	game.camera.camera.global_transform = Transform3D(Basis.looking_at(at - eye, Vector3.UP), eye)
	for frame: int in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)
	game.camera.set_process(true)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
