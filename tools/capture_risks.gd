extends Node
## Roteiro de verificação visual dos riscos (sem tela, roda no xvfb):
##   tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 20000 res://tools/capture_risks.tscn -- <pasta>
## Na vila de demonstração com os riscos ligados: uma fábrica e uma casa em chamas de perto (dia e
## noite), o painel da fábrica em chamas e da casa doente com os avisos, e a prévia do quartel de
## bombeiros com o que ele protege.

var _out_dir: String
var _game: GameScreen
var _sim: Simulation


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = true
	Settings.edge_pan = false
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	GameClock.set_speed(TickClock.PAUSED)
	_run.call_deferred()


func _run() -> void:
	_sim = _game.simulation
	DemoVillage.build(_sim)
	_sim.free_build = true
	_sim.world.risks_state.enabled = true
	EventBus.world_replaced.emit()
	_set_hour(11.0)
	var factory := 0
	var house := 0
	var sick := 0
	for building_id: int in _sim.world.building_ids():
		var record := _sim.world.building(building_id)
		var def := _sim.def_of(record)
		if def.is_production() and def.fire_risk > 1.0 and factory == 0:
			factory = building_id
		elif record.is_house():
			if house == 0:
				house = building_id
			elif sick == 0:
				sick = building_id
	if factory == 0:
		for building_id: int in _sim.world.building_ids():
			if _sim.def_of(_sim.world.building(building_id)).is_production():
				factory = building_id
				break
	RiskSystem.ignite(_sim.world, factory)
	RiskSystem.ignite(_sim.world, house)
	RiskSystem.infect(_sim.world, sick)
	_sim.run_ticks(2)
	var focus := _center(factory)
	await _shot("01_fabrica_em_chamas.png", focus, 45.0, 0.4)
	await _shot("02_casa_em_chamas.png", _center(house), 35.0, -0.5)
	_set_hour(22.0)
	await _shot("03_fogo_a_noite.png", focus, 60.0, 0.4)
	_set_hour(11.0)
	_game.tool.select(factory)
	await _shot("04_painel_da_fabrica_em_chamas.png", focus, 70.0, 0.4)
	_game.tool.select(sick)
	await _shot("05_painel_da_casa_doente.png", _center(sick), 70.0, 0.4)
	_game.tool.select(0)
	var feed := _game.hud.notifications
	feed.push(feed.watcher.fire_started(factory))
	feed.push(feed.watcher.outbreak(sick))
	feed.push(feed.watcher.building_lost(999, &"bakery", 0))
	await _shot("06_avisos.png", focus, 90.0, 0.4)
	_game.tool.start_building(_sim.data.building(&"fire_station"))
	var grid := _sim.world.island(0)
	var record := _sim.world.building(house)
	var site := SiteFinder.find(_sim, &"fire_station", 0, record.origin)
	if not site.is_empty():
		var origin: Vector2i = site[0]
		_game.tool.rotation = site[1]
		_game.tool.hover(origin + Vector2i(1, 2))
		_game.update_highlight()
		await _shot("07_previa_do_quartel.png", grid.cell_world(origin), 120.0, 0.0)
	get_tree().quit()


func _center(building_id: int) -> Vector3:
	var record := _sim.world.building(building_id)
	var def := _sim.def_of(record)
	return _sim.world.island(record.island_id).rect_world(Footprint.rect(record.origin, def.size, record.rotation))


func _shot(file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := _game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = _sim.world.surface_height(focus.x, focus.z)
	_game.camera.apply()
	for frame: int in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
