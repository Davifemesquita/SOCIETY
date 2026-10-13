extends Node
## Roteiro de verificação visual da Fase 6 (sem tela, roda no xvfb):
##   tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 9000 res://tools/capture_phase6.tscn -- <pasta>
## Arquipélago da semente 1840 com a rota de tijolos (TradeDemo): o navio inicial no mar, o navio
## da rota no cais da colônia, navegando entre as ilhas, o posto do comerciante, o painel do navio
## e a janela de rotas com o mapa.

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
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	GameClock.set_speed(TickClock.PAUSED)
	_run.call_deferred()


func _run() -> void:
	_sim = _game.simulation
	_set_hour(10.0)
	var start := _sim.world.player_ships()[0]
	await _shot("01_navio_inicial.png", start.position, 70.0, 0.5)
	var ids := TradeDemo.build(_sim)
	var ship_id: int = ids["ship"]
	var ship := _sim.world.ship(ship_id)
	# até o navio da rota encostar no cais da colônia
	while not (ship.state == Ship.State.DOCKED and ship.at == 1 and ship.berth_id != 0 \
			and ship.position.is_equal_approx(_sim.harbors().berth_point(ship.berth_id))):
		_sim.tick(0)
	print("no cais da colônia no tick ", _sim.world.tick)
	await _shot("02_cais_da_colonia.png", ship.position, 80.0, 2.4)
	while ship.state != Ship.State.SAILING:
		_sim.tick(0)
	for i: int in roundi(40.0 / _sim.config.tick_interval()):
		_sim.tick(0)
	await _shot("03_navegando.png", ship.position, 90.0, 1.2)
	var trader := _sim.world.ship(_sim.world.trader.ship_id)
	var post := _sim.harbors().trader_post
	await _shot("04_posto_do_comerciante.png", post, 90.0, 0.8)
	if trader != null:
		print("navio do comerciante em ", trader.position, " estado ", trader.state)
	_game.tool.select_ship(ship_id)
	await _shot("05_painel_do_navio.png", ship.position, 120.0, 1.2)
	_game.tool.select_ship(0)
	_game.hud.route_window.toggle()
	var route_id: int = ids["route"]
	_game.hud.route_window.select_route(route_id)
	await _shot("06_janela_de_rotas.png", ship.position, 300.0, 1.2)
	_game.hud.route_window.toggle()
	var bounds := _game.world_bounds()
	await _shot("07_arquipelago.png", Vector3(bounds.get_center().x, 0.0, bounds.get_center().y), 1500.0, 0.0)
	get_tree().quit()


func _shot(file_name: String, focus_at: Variant, distance: float, yaw: float) -> void:
	var focus := Vector3.ZERO
	if focus_at is Vector2:
		var flat: Vector2 = focus_at
		focus = Vector3(flat.x, 0.0, flat.y)
	else:
		focus = focus_at
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
