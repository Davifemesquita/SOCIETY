extends Node
## Roteiro de verificação visual da Fase 2 (sem tela, roda no xvfb):
##   tools/godot.sh godot --path . --resolution 1920x1080 res://tools/capture_phase2.tscn -- <pasta>
## Monta a vila de demonstração (DemoVillage), deixa a economia rodar 30 minutos de jogo e
## captura a vila, os painéis, as estatísticas e os destaques.

const MINUTES := 30

var _out_dir: String
var _game: GameScreen
var _sim: Simulation


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	GameScreen.load_slot_on_start = ""
	# a vila de demonstração é montada na ilha plana de antes
	GameScreen.flat_world = true
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	GameClock.set_speed(TickClock.PAUSED)
	_run.call_deferred()


func _run() -> void:
	_sim = _game.simulation
	var village := DemoVillage.build(_sim)
	var started := Time.get_ticks_msec()
	_sim.run_ticks(roundi(MINUTES * 60.0 / _sim.config.tick_interval()))
	print("%d min de jogo simulados em %.1f s" % [MINUTES, (Time.get_ticks_msec() - started) / 1000.0])
	var report := _sim.statistics()
	print("população: %s · dinheiro %d · saldo %+.0f/min" % [report.population, _sim.world.money, report.balance_per_min()])
	for good: StringName in [&"fish", &"woolen_clothes", &"planks", &"wheat", &"flour", &"bread"]:
		var line := report.line(good)
		print("  %s: produção %.2f / potencial %.2f / consumo %.2f / estoque %.1f t" % [good, line.produced, line.potential, line.consumed(), line.stock])
	var rig := _game.camera.rig
	rig.focus = Vector3(205, 0, 40)
	rig.distance = 150.0
	_game.camera.apply()
	await _settle()
	await _capture("01_vila.png")
	rig.rotate_quarter(1)
	await _settle()
	await _capture("02_vila_girada.png")
	rig.rotate_quarter(-1)
	var houses: Array[int] = village["houses"]
	_game.tool.select(houses[5])
	await _settle()
	await _capture("03_painel_casa.png")
	var bakery: int = village["bakery"]
	_game.tool.select(bakery)
	await _settle()
	await _capture("04_painel_padaria.png")
	var market: int = village["market"]
	_game.tool.select(market)
	await _settle()
	await _capture("05_alcance_mercado.png")
	_game.tool.select(0)
	_game.hud.toggle_statistics()
	await _settle()
	await _capture("06_estatisticas.png")
	_game.hud.toggle_statistics()
	_game.tool.start_building(_sim.data.building(&"wheat_farm"))
	_game.tool.hover(Vector2i(140, 30))
	await _settle()
	await _capture("07_fazenda_area_campos.png")
	_game.tool.cancel()
	_game.hud._select_category(2)
	await _settle()
	await _capture("08_menu_operarios.png")
	get_tree().quit()


func _settle() -> void:
	for frame: int in 30:
		await get_tree().process_frame


func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
