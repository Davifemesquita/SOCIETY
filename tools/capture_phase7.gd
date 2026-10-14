extends Node
## Roteiro de verificação visual da Fase 7 (sem tela, roda no xvfb):
##   tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 20000 res://tools/capture_phase7.tscn -- <pasta>
## Menu principal e jogo novo; a vila de demonstração (ilha plana) depois de 30 minutos de jogo com
## a barra, as notificações e o menu de construção; painéis de produção (calculadora) e da casa
## (retrato e semáforo); estatísticas nas três abas com os gráficos; camadas de serviço e poluição;
## menu da partida, opções, salvar e créditos; a interface em inglês; e, no arquipélago da semente
## 1840 com a rota de tijolos, a janela de rotas com o mapa ilustrado e o comércio.

const SEED := 1840

var _out_dir: String
var _game: GameScreen
var _sim: Simulation


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	GameScreen.load_slot_on_start = ""
	GameScreen.use_sky3d = false
	# no xvfb o mouse fica no canto: sem pan pela borda a câmera não anda sozinha
	Settings.edge_pan = false
	_run.call_deferred()


func _run() -> void:
	var boot: Control = (load("res://ui/screens/boot_screen.tscn") as PackedScene).instantiate()
	add_child(boot)
	await _save("01_menu_principal.png")
	boot.call(&"open_new_game")
	await _save("02_jogo_novo.png")
	remove_child(boot)
	boot.queue_free()
	await _village()
	await _archipelago()
	get_tree().quit()


func _start(flat: bool) -> void:
	GameScreen.flat_world = flat
	GameScreen.world_seed = SEED
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	_sim = _game.simulation
	GameClock.set_speed(TickClock.PAUSED)
	await get_tree().process_frame


func _village() -> void:
	await _start(true)
	var ids := DemoVillage.build(_sim)
	_sim.free_build = false
	_sim.run_ticks(_sim.config.ticks_per_second * 60 * 30)
	GameClock.clock.tick_count = _sim.world.tick
	_set_hour(10.0)
	var feed := _game.hud.notifications
	feed.push(feed.watcher.milestone(1))
	var port: int = ids["port"]
	var center := _focus_of(port) + Vector3(0, 0, 50)
	await _shot("03_partida_30_minutos.png", center, 120.0)
	var bakery: int = ids["bakery"]
	_game.tool.select(bakery)
	await _shot("04_painel_padaria.png", center, 120.0)
	var houses: Array[int] = ids["houses"]
	_game.tool.select(houses[3])
	await _shot("05_painel_casa.png", center, 120.0)
	_game.tool.select(0)
	_game.hud.toggle_statistics()
	for tab: int in 3:
		_game.hud.statistics_window._tabs.current_tab = tab
		await _shot("06_estatisticas_%d.png" % tab, center, 120.0)
	_game.hud.statistics_window.visible = false
	_game.hud.set_overlay(MapOverlays.Layer.SERVICE)
	await _shot("07_camada_servicos.png", center, 150.0)
	_sim.free_build = true
	_sim.execute(PlaceBuildingCommand.new(0, &"brickworks", Vector2i(100, 41), 0))
	_sim.free_build = false
	_game.hud.set_overlay(MapOverlays.Layer.POLLUTION)
	await _shot("08_camada_poluicao.png", center, 150.0)
	_game.hud.set_overlay(MapOverlays.Layer.NONE)
	_game.open_menu()
	await _shot("09_menu_da_partida.png", center, 120.0)
	var options := OptionsDialog.new()
	Modal.open(_game._ui_layer, options)
	options.tabs.current_tab = 2
	await _shot("10_opcoes_controles.png", center, 120.0)
	options.tabs.current_tab = 4
	await _shot("11_opcoes_interface.png", center, 120.0)
	_game._close_all_modals()
	_game.save_game("captura_fase7", "Vila de demonstração")
	_game.open_save_dialog()
	await _shot("12_salvar.png", center, 120.0)
	_game._close_all_modals()
	SaveSystem.delete_slot("captura_fase7")
	Modal.open(_game._ui_layer, CreditsDialog.new())
	await _shot("13_creditos.png", center, 120.0)
	_game._close_all_modals()
	Settings.set_locale("en")
	Settings.apply()
	_game.tool.select(bakery)
	await _shot("14_interface_em_ingles.png", center, 120.0)
	Settings.set_locale("pt_BR")
	Settings.apply()
	remove_child(_game)
	_game.queue_free()
	await get_tree().process_frame


func _archipelago() -> void:
	await _start(false)
	var ids := TradeDemo.build(_sim)
	for i: int in _sim.config.ticks_per_second * 60 * 6:
		_sim.tick(0)
	_set_hour(17.5)
	var ship_id: int = ids["ship"]
	var route_id: int = ids["route"]
	var ship: Ship = _sim.world.ship(ship_id)
	_game.hud.toggle_routes()
	_game.hud.route_window.select_route(route_id)
	await _shot("15_rotas_mapa_ilustrado.png", Vector3(ship.position.x, 0, ship.position.y), 200.0)
	_game.hud.route_window.visible = false
	_game.hud.trade_window.open(0)
	await _shot("16_comercio.png", Vector3(ship.position.x, 0, ship.position.y), 200.0)


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
