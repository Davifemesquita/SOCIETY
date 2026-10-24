extends Node
## Roteiro de verificação visual dos navios de modelo (sem tela, roda no xvfb):
##   tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 9000 res://tools/capture_ships.tscn -- <pasta>
## Um navio de cada tipo parado no mar ao norte da ilha plana (rumo leste, proa para a direita), de
## lado e de cima, e um rival com as velas na cor dele; depois as carroças na vila de demonstração.

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
	_set_hour(10.0)
	var x := 40.0
	for def_id: StringName in [&"merchant_ship", &"trader_ship", &"frigate", &"clipper"]:
		var ship := Ship.new(_sim.world.next_ship_id, _sim.data.ship(def_id))
		_sim.world.next_ship_id += 1
		ship.position = Vector2(x, -40.0)
		ship.previous_position = ship.position
		ship.heading = 0.0
		ship.previous_heading = 0.0
		_sim.world.ships[ship.id] = ship
		# Fase 26: o mercante e o clíper carregados, um bem de cada forma de pilha, para a carga no convés
		if def_id in [&"merchant_ship", &"clipper"]:
			_load_one_of_each_pile(ship)
		x += 40.0
	var focus := Vector3(100.0, 0.0, -40.0)
	await _shot("01_navios_de_lado.png", focus, 90.0, 0.0, 0.25)
	await _shot("02_navios_de_cima.png", focus, 140.0, 0.6, 0.9)
	await _shot("03_mercante_de_perto.png", Vector3(40.0, 0.0, -40.0), 35.0, 0.5, 0.35)
	await _shot("03b_cordame_e_carga.png", Vector3(40.0, 4.0, -40.0), 24.0, 0.9, 0.3)
	await _shot("03c_cliper_de_perto.png", Vector3(160.0, 4.0, -40.0), 30.0, 0.7, 0.4)
	DemoVillage.build(_sim)
	GameClock.set_speed(1)
	for frame: int in 300:
		await get_tree().process_frame
	GameClock.set_speed(TickClock.PAUSED)
	var grid := _sim.world.island(0)
	for cart: Cart in _sim.world.carts.values():
		if cart.is_away() and cart.path.size() > 0:
			var cell := grid.cell_at(cart.path[clampi(roundi(cart.position), 0, cart.path.size() - 1)])
			await _shot("04_carroca.png", grid.cell_world(cell), 14.0, 0.6, 0.5)
			break
	get_tree().quit()


func _load_one_of_each_pile(ship: Ship) -> void:
	var piles: Dictionary[int, bool] = {}
	for good: GoodDef in _sim.data.goods:
		if good.pile == GoodDef.Pile.NONE or piles.has(good.pile):
			continue
		piles[good.pile] = true
		ship.load_good(good.id, 10.0, 10.0)


func _shot(file_name: String, focus: Vector3, distance: float, yaw: float, pitch: float) -> void:
	var rig := _game.camera.rig
	rig.focus = focus
	rig.distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	if "pitch" in rig:
		rig.set(&"pitch", pitch)
	rig.ground_height = 0.0
	_game.camera.apply()
	for frame: int in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
