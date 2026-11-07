extends Node
## Roteiro de verificação visual da Fase 158 (carroça de lona): na ilha plana, o entreposto, uma rua, três moendas e um
## lenhador com a produção pronta e um armazém no fim da rua; o jogo anda a 1x até as carroças saírem, e a câmera olha a rua
## de perto (as moendas de id par andam de lona; a do lenhador leva as toras à mostra). Precisa de GPU; no PC do dono roda na
## área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase158.tscn -- <pasta>

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
	_set_hour(10.0)
	game.hud.visible = false
	var sim := game.simulation
	sim.execute(PlaceBuildingCommand.new(0, &"trading_post", Vector2i(100, 0), 2))
	sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(90, 6), Vector2i(170, 6))))
	sim.free_build = true
	var producers: Array[int] = []
	for pair: Array in [[&"mill", 112], [&"mill", 118], [&"mill", 124], [&"lumberjack", 130]]:
		var def_id: StringName = pair[0]
		var x: int = pair[1]
		var result := sim.execute(PlaceBuildingCommand.new(0, def_id, Vector2i(x, 7), 0))
		if result.ok():
			producers.append(result.placed[0])
	sim.execute(PlaceBuildingCommand.new(0, &"warehouse", Vector2i(165, 7), 0))
	for building_id: int in producers:
		sim.world.building(building_id).output_buffer = 2.0
	GameClock.set_speed(0)
	for frame: int in 420:
		await get_tree().process_frame
	GameClock.set_speed(TickClock.PAUSED)
	print("carroças: ", game.cart_view.visible_carts(), " de lona: ", game.cart_view.visible_covers())
	var grid := sim.world.island(0)
	# a câmera na carroça de lona mais adiantada na rua
	var road := grid.cell_world(Vector2i(130, 6))
	var best := -1.0
	for cart: Cart in sim.world.carts.values():
		if not cart.is_away() or cart.path.is_empty():
			continue
		var good := sim.data.good(sim.def_of(sim.world.building(cart.home_id)).output)
		if good == null or not CartView.covers(good.pile, cart.home_id):
			continue
		var cell := grid.cell_at(cart.path[clampi(floori(cart.position), 0, cart.path.size() - 1)])
		if cell.x > best:
			best = cell.x
			road = grid.surface_world(cell)
	await _shot(game, "carrocas_de_lona.png", road, 24.0, 0.5)
	await _shot(game, "carrocas_de_lona_de_perto.png", road, 9.0, 2.2)
	await _shot(game, "carrocas_de_lona_de_tras.png", road, 9.0, 4.3)
	get_tree().quit()


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = 0.0
	game.camera.apply()
	for frame: int in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
