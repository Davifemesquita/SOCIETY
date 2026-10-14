extends Node
## Roteiro de verificação visual da Fase 8 (sem tela, roda no xvfb):
##   tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 20000 res://tools/capture_phase8.tscn -- <pasta>
## A partida roteirizada (ProgressionDemo) depois de chegar aos investidores: a rua das casas com
## os modelos e tons, as casas de investidor de perto, o painel delas, as metas com a fala do
## conselheiro, as abas de produção das classes novas, a rua de paralelepípedo, mover um prédio e
## o conselheiro em inglês.

var _out_dir: String
var _game: GameScreen
var _sim: Simulation
var _demo: ProgressionDemo


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	GameScreen.load_slot_on_start = ""
	GameScreen.use_sky3d = false
	Settings.edge_pan = false
	_run.call_deferred()


func _run() -> void:
	_demo = ProgressionDemo.build()
	_demo.run_until_tier(&"investors", 2.0 * 3600.0)
	_demo.run(600.0)
	GameScreen.flat_world = true
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	_sim = _game.simulation
	GameClock.set_speed(TickClock.PAUSED)
	await get_tree().process_frame
	_sim.world = _demo.simulation.world
	GameClock.clock.tick_count = _sim.world.tick
	EventBus.world_replaced.emit()
	_set_hour(16.5)
	var street := ProgressionDemo.RESIDENTIAL_STREETS[0]
	var investor := _first_house(&"investors")
	var center := _focus_of(investor)
	await _shot("01_rua_das_casas.png", Vector3(center.x, 0, street * 2.0), 140.0)
	await _shot("02_casas_de_perto.png", center, 45.0)
	_game.tool.select(investor)
	await _shot("03_painel_investidor.png", center, 60.0)
	_game.tool.select(0)
	_game.hud.goal_panel.speak_current()
	await _shot("04_meta_e_conselheiro.png", center, 90.0)
	_game.hud.goal_panel.advance()
	_game.hud.goal_panel.advance()
	for tier_index: int in [3, 4, 5]:
		_game.hud._select_category(tier_index)
		await _shot("05_producao_%s.png" % _sim.data.tiers[tier_index - 1].id, center, 90.0)
	_game.hud._select_category(_game.hud._categories().size() - 1)
	_sim.free_build = true
	# a rua das fábricas (y = 36), metade calçada: a diferença para a terra fica à vista
	var paved := _sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(1, 36), Vector2i(70, 36)), true))
	print("paralelepípedo: ", "ok" if paved.ok() else paved.reason)
	await _shot("06_paralelepipedo.png", Vector3(140.0, 0, 80.0), 70.0)
	_game.tool.start_move(investor)
	_game.tool.hover(Vector2i(160, 175))
	await _shot("07_mover_casa.png", Vector3(320, 0, 350), 70.0)
	_game.tool.cancel()
	Settings.set_locale("en")
	Settings.apply()
	_game.hud.goal_panel.speak_current()
	await _shot("08_conselheiro_em_ingles.png", center, 90.0)
	Settings.set_locale("pt_BR")
	Settings.apply()
	get_tree().quit()


func _first_house(tier: StringName) -> int:
	for house_id: int in _demo.houses:
		if _sim.world.building(house_id).tier == tier:
			return house_id
	return _demo.houses[0]


func _focus_of(building_id: int) -> Vector3:
	var record := _sim.world.building(building_id)
	return _sim.world.island(record.island_id).rect_world(Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation))


func _shot(file_name: String, focus: Vector3, distance: float) -> void:
	var rig := _game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.ground_height = _sim.world.surface_height(focus.x, focus.z)
	_game.camera.apply()
	await _save(file_name)


func _save(file_name: String) -> void:
	for frame: int in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
