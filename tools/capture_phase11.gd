extends Node
## Roteiro de verificação visual da Fase 11 (sem tela, roda no xvfb):
##   tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 20000 res://tools/capture_phase11.tscn -- <pasta>
## Segunda região climática na semente 1840: o arquipélago com as ilhas tropicais a leste, cada
## ilha tropical de cima, as palmeiras de perto, a mina de ouro sobre a jazida (destaque de
## terreno), o canavial com os campos e o mapa das rotas com as ilhas novas. Depois, eventos e
## encomendas: a janela com a oferta, a aceita e os eventos, os selos na barra e os avisos
## (CAPTURA_SO=eventos tira só estas) e as rivais: a vila, o navio, o mapa e a diplomacia
## (CAPTURA_SO=rivais).

const SEED := 1840

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
	Settings.edge_pan = false
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	GameClock.set_speed(TickClock.PAUSED)
	_run.call_deferred()


func _run() -> void:
	_sim = _game.simulation
	_set_hour(11.0)
	var bounds := _game.world_bounds()
	if OS.get_environment("CAPTURA_SO") == "eventos":
		await _events_shots()
		return
	if OS.get_environment("CAPTURA_SO") == "rivais":
		await _rival_shots()
		return
	await _shot("01_arquipelago_com_os_tropicos.png", Vector3(bounds.get_center().x, 0.0, bounds.get_center().y), 2200.0, 0.0)
	var tropical: Array[int] = []
	for island_id: int in _sim.world.islands.size():
		if _sim.world.is_tropical(island_id, _sim.data):
			tropical.append(island_id)
	for island_id: int in tropical:
		var grid := _sim.world.island(island_id)
		await _shot("02_ilha_%d_%s.png" % [island_id, _sim.world.economy(island_id).profile_id], grid.cell_world(grid.size / 2), grid.size.x * 1.7, 0.0)
	var first := _sim.world.island(tropical[0])
	await _shot("03_palmeiras.png", first.cell_world(_first_cell(first, func(i: int) -> bool: return first.trees[i] >= 3)), 40.0, 0.3)
	for island_id: int in tropical:
		var grid := _sim.world.island(island_id)
		if not grid.deposit_goods.has(&"gold"):
			continue
		var mine := SiteFinder.find(_sim, &"gold_mine", island_id, grid.size / 2)
		if mine.is_empty():
			continue
		var mine_origin: Vector2i = mine[0]
		_game.tool.island_id = island_id
		_game.tool.start_building(_sim.data.building(&"gold_mine"))
		_game.tool.hover(mine_origin + Vector2i(2, 2))
		await _shot("04_mina_de_ouro_na_jazida.png", grid.cell_world(mine_origin), 55.0, 0.0)
		_game.tool.cancel()
		break
	for island_id: int in tropical:
		if _sim.data.profile(_sim.world.economy(island_id).profile_id).fertilities.has(&"sugar"):
			await _build_cane_farm(island_id)
			break
	_game.hud.route_window.toggle()
	_game.hud.route_window.create_route()
	await _shot("06_mapa_das_rotas.png", Vector3(bounds.get_center().x, 0.0, bounds.get_center().y), 2200.0, 0.0)
	_game.hud.route_window.visible = false
	await _events_shots()
	await _rival_shots()


## Eventos e encomendas (CAPTURA_SO=eventos tira só estas).
func _events_shots() -> void:
	_fill_events()
	_game.hud._refresh()
	_game.hud.mission_window.open()
	var main := _sim.world.island(0)
	await _shot("07_encomendas_e_eventos.png", main.cell_world(main.size / 2), 260.0, 0.3)
	_game.hud.mission_window.visible = false
	var feed := _game.hud.notifications
	feed.push(feed.watcher.event_started(&"storm", -1))
	feed.push(feed.watcher.event_started(&"good_harvest", 0))
	feed.push(feed.watcher.mission_offered(1))
	feed.push(feed.watcher.mission_completed(&"fish", 540))
	await _shot("08_avisos_de_eventos_e_encomendas.png", main.cell_world(main.size / 2), 260.0, 0.3)
	feed.clear()
	if OS.get_environment("CAPTURA_SO") == "eventos":
		get_tree().quit()


## Rivais: as colônias saem cedo (tempos encurtados), a vila cresce, o navio vai ao comerciante; a
## vila de perto, o navio dela, o mapa com as ilhas marcadas e a janela da diplomacia.
func _rival_shots() -> void:
	var state := _sim.world.rivals_state
	state.start(_sim.data, _sim.config)
	for rival: RivalState in state.rivals:
		rival.def = rival.def.duplicate()
		rival.def.first_colony_s = 10.0
		rival.def.colony_interval_s = 20.0
	_sim.free_build = true
	var main := _sim.world.island(0)
	var site := SiteFinder.find(_sim, &"trading_post", 0, main.size / 2)
	if not site.is_empty() and not _sim.world.has_trading_post(0, _sim.data):
		var post_origin: Vector2i = site[0]
		var post_rotation: int = site[1]
		_sim.execute(PlaceBuildingCommand.new(0, &"trading_post", post_origin, post_rotation))
	print("rivais: simulando")
	var started := Time.get_ticks_msec()
	_sim.run_ticks(_sim.config.ticks_per_second * 60 * 25)
	print("rivais: 25 min simulados em %d ms" % (Time.get_ticks_msec() - started))
	GameClock.clock.tick_count = _sim.world.tick
	_set_hour(15.0)
	_game.rival_view.refresh()
	var first := state.rivals[0]
	if first.islands.is_empty():
		get_tree().quit()
		return
	var island_id: int = first.island_ids()[0]
	var grid := _sim.world.island(island_id)
	var slots := RivalView._find_slots(grid, _sim.config)
	var village_cell: Vector2i = slots[0] if not slots.is_empty() else grid.size / 2
	var village_at := grid.cell_world(village_cell)
	await _shot("09_vila_rival.png", village_at, 90.0, 0.6)
	var ship := _sim.world.ship(first.ship_id)
	if ship != null:
		await _shot("10_navio_rival.png", Vector3(ship.position.x, 0.0, ship.position.y), 45.0, 0.9)
	_game.hud.route_window.toggle()
	await _shot("11_mapa_com_as_rivais.png", village_at, 300.0, 0.0)
	_game.hud.route_window.visible = false
	_sim.world.money = 100000.0
	_sim.execute(DiplomacyCommand.new(&"hanseatic", DiplomacyCommand.Action.GIFT))
	state.by_id(&"ironside").stance = RivalState.Stance.WAR
	_game.hud._refresh()
	_game.hud.diplomacy_window.open()
	await _shot("12_diplomacia.png", village_at, 300.0, 0.0)
	get_tree().quit()


## Uma encomenda oferecida, uma aceita em andamento e dois eventos (sem esperar o sorteio).
func _fill_events() -> void:
	var state := _sim.world.events_state
	state.enabled = true
	for index: int in 2:
		var item := Mission.new()
		item.id = state.next_mission_id
		state.next_mission_id += 1
		item.def = _sim.data.missions[index]
		item.def_id = item.def.id
		item.expires_tick = _sim.world.tick + _sim.config.ticks_of(240.0 if index == 0 else 1100.0)
		if index == 1:
			item.state = Mission.State.ACCEPTED
			item.delivered = 12.0
		state.missions.append(item)
	for def_id: StringName in [&"fair", &"good_harvest"]:
		var event := WorldEvent.new()
		event.def = _sim.data.event(def_id)
		event.def_id = def_id
		event.island_id = 0 if event.def.is_local() else -1
		event.good = &"bricks" if def_id == &"fair" else &""
		event.started_tick = _sim.world.tick
		event.ends_tick = _sim.world.tick + _sim.config.ticks_of(event.def.duration_s)
		state.events.append(event)


## Canavial com os seis campos perto do meio da ilha (sem custo, só para ver).
func _build_cane_farm(island_id: int) -> void:
	var grid := _sim.world.island(island_id)
	_sim.free_build = true
	var farm := SiteFinder.find(_sim, &"sugar_cane_farm", island_id, grid.size / 2)
	if farm.is_empty():
		return
	var origin: Vector2i = farm[0]
	var rotation: int = farm[1]
	_sim.execute(PlaceBuildingCommand.new(island_id, &"sugar_cane_farm", origin, rotation))
	var placed := 0
	for radius: int in range(3, 9):
		for dy: int in range(-radius, radius + 1):
			for dx: int in range(-radius, radius + 1):
				if placed < 6 and _sim.execute(PlaceBuildingCommand.new(island_id, &"field", origin + Vector2i(dx, dy), 0)).ok():
					placed += 1
	print("canavial em %s com %d campos" % [origin, placed])
	await _shot("05_canavial.png", grid.cell_world(origin), 60.0, 0.5)


func _first_cell(grid: IslandGrid, accepts: Callable) -> Vector2i:
	var center := grid.size / 2
	for radius: int in grid.size.x:
		for cell: Vector2i in [center + Vector2i(radius, 0), center + Vector2i(-radius, 0), center + Vector2i(0, radius), center + Vector2i(0, -radius)]:
			if grid.in_bounds(cell) and accepts.call(grid.index(cell)):
				return cell
	return center


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
