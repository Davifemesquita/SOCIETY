extends Node
## Roteiro de verificação visual da Fase 3 (sem tela, roda no xvfb):
##   tools/godot.sh godot --path . --resolution 1920x1080 res://tools/capture_phase3.tscn -- <pasta>
## Vila de demonstração com 10 minutos de jogo: carroças na estrada, painel do prédio com a
## carroça, painel e alcance do armazém, e o corte de estrada com os alertas.

const MINUTES := 10

var _out_dir: String
var _game: GameScreen
var _sim: Simulation


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	GameScreen.load_slot_on_start = ""
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	GameClock.set_speed(TickClock.PAUSED)
	_run.call_deferred()


func _run() -> void:
	_sim = _game.simulation
	var village := DemoVillage.build(_sim)
	_sim.run_ticks(roundi(MINUTES * 60.0 / _sim.config.tick_interval()))
	var away := _sim.world.carts.values().filter(func(cart: Cart) -> bool: return cart.is_away())
	print("%d min de jogo · %d carroças na rua de %d" % [MINUTES, away.size(), _sim.world.carts.size()])
	var report := _sim.statistics()
	print("população: %s · dinheiro %d" % [report.population, _sim.world.money])
	for good: StringName in [&"wood", &"planks", &"fish", &"wheat", &"flour", &"bread"]:
		var line := report.line(good)
		print("  %s: produção %.2f / consumo %.2f / estoque %.1f t" % [good, line.produced, line.consumed(), line.stock])
	var rig := _game.camera.rig
	rig.focus = Vector3(160, 0, 50)
	rig.distance = 55.0
	_game.camera.apply()
	await _advance_and_capture("01_carrocas_na_estrada.png")
	rig.distance = 140.0
	rig.focus = Vector3(210, 0, 40)
	var lumberjack: int = village["lumberjack"]
	_game.tool.select(lumberjack)
	await _advance_and_capture("02_painel_lenhador.png")
	var warehouse: int = village["warehouse"]
	_game.tool.select(warehouse)
	await _advance_and_capture("03_armazem_alcance.png")
	var port: int = village["port"]
	_game.tool.select(port)
	await _advance_and_capture("04_entreposto.png")
	_game.tool.select(0)
	_sim.execute(DemolishCommand.new(0, Rect2i(80, 26, 1, 1)))
	_sim.run_ticks(10)
	await _advance_and_capture("05_estrada_cortada.png")
	var sawmill: int = village["sawmill"]
	_game.tool.select(sawmill)
	await _advance_and_capture("06_serraria_sem_armazem.png")
	get_tree().quit()


## Deixa a simulação andar alguns ticks (as carroças se movem) e captura.
func _advance_and_capture(file_name: String) -> void:
	for frame: int in 30:
		if frame % 6 == 0:
			_sim.tick(_sim.world.tick)
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
