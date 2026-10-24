extends Node
## Roteiro de verificação visual da Fase 30 (sem tela, roda no xvfb):
##   tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 9000 res://tools/capture_phase30.tscn -- <pasta>
## As moedas e o "+X" sobre o entreposto no meio do salto, o dinheiro da barra pulsando num ganho grande e a cortina
## escura com "Gerando o arquipélago…" no meio de uma troca.

var _out_dir: String
var _game: GameScreen
var _sim: Simulation


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	OS.set_environment("SOCIETY_SEM_TRANSICAO", "0")
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = true
	Settings.edge_pan = false
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	GameClock.set_speed(TickClock.PAUSED)
	_run.call_deferred()


func _run() -> void:
	_sim = _game.simulation
	_sim.free_build = true
	_sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"trading_post", Vector2i(10, 0), 2))
	var post := _game.money_fx_view.trading_post_point(Simulation.MAIN_ISLAND)
	_aim(post, 40.0)
	for frame: int in 30:
		await get_tree().process_frame
	# o comerciante pagou: moedas no ar e o "+1.240" subindo; o dinheiro da barra pulsa
	EventBus.trader_visited.emit(Simulation.MAIN_ISLAND, 1240.0, 0.0)
	_sim.world.money += 1240.0
	_game.hud._refresh()
	await _wait(0.45)
	await _save("01_moedas_no_entreposto.png")
	await _wait(1.6)
	# a cortina no escuro, com o texto, a meio caminho de uma troca que não troca nada
	SceneFader.change_with(func() -> void: pass, "LOADING_NEW_WORLD")
	await _wait(0.4)
	await _save("02_cortina.png")
	await SceneFader.finished
	get_tree().quit()


func _aim(focus: Vector3, distance: float) -> void:
	var rig := _game.camera.rig
	rig.focus = focus
	rig.distance = distance
	rig.ground_height = focus.y
	_game.camera.apply()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _save(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)
