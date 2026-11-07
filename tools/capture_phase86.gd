extends Node
## Roteiro de verificação da Fase 86 (foguete e assobio): o bairro da Fase 81 com a festa, à noite; o jogo anda até
## alguns moradores e turistas estarem na rua em volta do mastro da praça (a hora fica presa às 22 h enquanto espera);
## então lança um foguete do mastro e para o jogo no meio da subida (foguete.png, com o rastro). Os
## sons gerados vão em estouro.wav, palmas.wav e assobio.wav, para ouvir; o que viu (e quantas vezes cada som tocou) vai
## em <pasta>/fase86.txt (a área escondida não mostra a saída). Precisa de GPU; no PC do dono roda na área de trabalho
## escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase86.tscn -- <pasta>

const START := Vector2i(24, 50)
const NIGHT_HOUR := 22.0
const WATCHERS := 6

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
	# casas cheias: numa cidade de verdade os moradores são muito mais que os turistas
	for house_id: int in TownLayout.build(sim, 30, &"house", start + Vector2i(0, 3)):
		var house := sim.world.building(house_id)
		house.residents = float(sim.data.tier(house.tier).residents_per_house)
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
	# o jogo andando (a multidão só anda com ele) até alguns moradores e turistas estarem em volta do mastro
	GameClock.set_speed(2)
	var crowd := game.pedestrian_view.crowd
	var residents := 0
	var tourists := 0
	var waited := 0.0
	while (residents < WATCHERS / 2 or residents + tourists < WATCHERS) and waited < 120.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
		_set_hour(NIGHT_HOUR)
		residents = 0
		tourists = 0
		for agent: Crowd.Agent in crowd.agents:
			if agent != null and agent.state == Crowd.State.WAITING and agent.target_id == square:
				if agent.tourist:
					tourists += 1
				else:
					residents += 1
	var seen := "pedestres %d, na rua %d (turistas %d); vendo a festa: moradores %d, turistas %d, depois de %.1f s" % [
			crowd.agent_count(), crowd.visible_count(), crowd.tourist_count(), residents, tourists, waited]
	print(seen)
	var log_file := FileAccess.open(_out_dir.path_join("fase86.txt"), FileAccess.WRITE)
	if log_file != null:
		log_file.store_line(seen)
	var mast: Vector3 = FestivalView.strings_of(sim, square)[0][0]
	# os fogos seguem estourando enquanto a câmera chega (o relógio anda devagar)
	GameClock.set_speed(1)
	await _shot(game, "fogos.png", mast, 34.0, 2.0)
	# um foguete subindo: espera os do ar estourarem, lança um e para o jogo no meio da subida, com o rastro
	var festival := game.festival_view
	for frame: int in 300:
		if festival.rockets_flying() == 0:
			break
		await get_tree().process_frame
	var rising := false
	if festival.fire(mast):
		for frame: int in 300:
			await get_tree().process_frame
			var rocket := _flying_rocket(festival)
			if rocket != null and rocket.position.y > mast.y + 7.0:
				rising = true
				break
	GameClock.set_speed(TickClock.PAUSED)
	if rising:
		await _shot(game, "foguete.png", mast, 30.0, 0.6)
	# os sons gerados, para ouvir fora do jogo, e quantas vezes tocaram
	FestivalSounds.bang_stream().save_to_wav(_out_dir.path_join("estouro.wav"))
	FestivalSounds.applause_stream().save_to_wav(_out_dir.path_join("palmas.wav"))
	FestivalSounds.whistle_stream().save_to_wav(_out_dir.path_join("assobio.wav"))
	if log_file != null:
		var played := game.festival_sounds.played
		log_file.store_line("assobios %d, estouros %d, ecos %d, palmas %d; foguete fotografado subindo: %s" % [
				played.get(&"whistle", 0), played.get(&"bang", 0), played.get(&"echo", 0), played.get(&"applause", 0), rising])
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


func _flying_rocket(festival: FestivalView) -> Node3D:
	for node: Node in festival.get_children():
		if node.name.begins_with("Rocket") and (node as Node3D).visible:
			return node as Node3D
	return null


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
