extends Node
## Roteiro de verificação visual da Fase 82 (ver os fogos): o bairro da Fase 81 com a festa, à noite; o jogo anda até
## alguns turistas estarem na rua em volta do mastro da praça, e a foto é ali, com os fogos no céu. Precisa de GPU; no PC
## do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase82.tscn -- <pasta>

const START := Vector2i(24, 50)
const NIGHT_HOUR := 22.0
const WATCHERS := 4

var _out_dir: String


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_run.call_deferred()


func _run() -> void:
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = true
	var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(game)
	GameClock.set_speed(TickClock.PAUSED)
	_set_hour(NIGHT_HOUR)
	game.hud.visible = false
	var sim := game.simulation
	sim.free_build = true
	sim.ignore_terrain = true
	var post: BuildingRecord = null
	for record: BuildingRecord in sim.world.buildings.values():
		if record.island_id == Simulation.MAIN_ISLAND and sim.def_of(record).is_trading_post:
			post = record
	var start := START
	if post == null:
		# o jogo novo começa sem entreposto: um posto à mão na ponta da rua (sem olhar o terreno)
		var placed := sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"trading_post", start + Vector2i(52, -8), 0))
		if placed.ok():
			post = sim.world.building(placed.placed[0])
	if post == null:
		_quit()
		return
	var post_def := sim.def_of(post)
	var door := Footprint.entrance_cell(post.origin, post_def.size, post.rotation)
	sim.execute(BuildRoadCommand.new(Simulation.MAIN_ISLAND, RoadPath.l_path(door, start)))
	sim.execute(BuildRoadCommand.new(Simulation.MAIN_ISLAND, RoadPath.l_path(start, start + Vector2i(56, 0))))
	sim.execute(BuildRoadCommand.new(Simulation.MAIN_ISLAND, RoadPath.l_path(start, start + Vector2i(0, 3))))
	TownLayout.build(sim, 30, &"house", start + Vector2i(0, 3))
	# as atrações em cima da rua, viradas para ela (a porta dá na rua)
	var placed: Array[CommandResult] = []
	var x := 28
	for def_id: StringName in [&"zoo", &"fountain_square", &"statue"]:
		var size := sim.data.building(def_id).size
		placed.append(sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, def_id, start + Vector2i(x, -size.y), 2)))
		x += size.x + 2
	if placed[0].ok():
		for def: ExhibitDef in sim.data.exhibits:
			if def.kind == ExhibitDef.Kind.ANIMAL:
				sim.execute(PlaceExhibitCommand.new(def.id, placed[0].placed[0]))
	if not placed[1].ok():
		_quit()
		return
	var square: int = placed[1].placed[0]
	sim.world.events_state.enabled = true
	sim.world.events_state.next_edition_tick = 999_999_999
	var event := WorldEvent.new()
	event.def = sim.data.event(&"festival")
	event.def_id = &"festival"
	event.island_id = Simulation.MAIN_ISLAND
	event.ends_tick = sim.world.tick + 100000
	sim.world.events_state.events.append(event)
	EventBus.world_event_started.emit(&"festival", Simulation.MAIN_ISLAND)
	# o jogo andando (a multidão só anda com ele) até alguns turistas estarem em volta do mastro
	GameClock.set_speed(2)
	var crowd := game.pedestrian_view.crowd
	var watchers := 0
	var waited := 0.0
	while watchers < WATCHERS and waited < 120.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
		watchers = 0
		for agent: Crowd.Agent in crowd.agents:
			if agent != null and agent.tourist and agent.state == Crowd.State.WAITING and agent.target_id == square:
				watchers += 1
	print("turistas ", crowd.tourist_count(), " vendo a festa ", watchers, " depois de ", snappedf(waited, 0.1), " s")
	var mast: Vector3 = FestivalView.strings_of(sim, square)[0][0]
	# os fogos seguem estourando enquanto a câmera chega (o relógio anda devagar)
	GameClock.set_speed(1)
	await _shot(game, "fogos_perto.png", mast, 14.0, 0.6)
	await _shot(game, "fogos.png", mast, 34.0, 2.0)
	GameClock.set_speed(TickClock.PAUSED)
	_quit()


func _quit() -> void:
	GameScreen.flat_world = false
	get_tree().quit()


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = maxf(game.simulation.world.surface_height(focus.x, focus.z), 0.0)
	game.camera.apply()
	for frame: int in 25:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
