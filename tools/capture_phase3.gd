extends Node
## Roteiro de verificação visual da Fase 3 (sem tela, roda no xvfb):
##   tools/godot.sh godot --path . --resolution 1920x1080 res://tools/capture_phase3.tscn -- <pasta>
## Vila de demonstração com 10 minutos de jogo: carroças na estrada, painel do prédio com a
## carroça, painel e alcance do armazém, e o corte de estrada com os alertas.
## CAPTURA_SO=animais tira só os bichos (Fase 13): ovelhas no pasto, cão na porta e o cavalo da carroça
## (e, de lado, o arreio da Fase 18).

const MINUTES := 10

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
	_sim.run_ticks(roundi(MINUTES * 60.0 / _sim.config.tick_interval()))
	var away := _sim.world.carts.values().filter(func(cart: Cart) -> bool: return cart.is_away())
	print("%d min de jogo · %d carroças na rua de %d" % [MINUTES, away.size(), _sim.world.carts.size()])
	var report := _sim.statistics()
	print("população: %s · dinheiro %d" % [report.population, _sim.world.money])
	for good: StringName in [&"wood", &"planks", &"fish", &"wheat", &"flour", &"bread"]:
		var line := report.line(good)
		print("  %s: produção %.2f / consumo %.2f / estoque %.1f t" % [good, line.produced, line.consumed(), line.stock])
	if OS.get_environment("CAPTURA_SO") == "animais":
		await _animals()
		get_tree().quit()
		return
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


## Fase 13: os bichos de perto (a câmera vai até o primeiro de cada um).
func _animals() -> void:
	var view := _game.animal_view
	# uma fileira de casas numa rua aberta: na vila elas dão frente umas para as outras e o cão some na viela
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(60, 60), Vector2i(100, 60))))
	var dog_house := 0
	for x: int in range(62, 98, 4):
		var result := _sim.execute(PlaceBuildingCommand.new(0, &"house", Vector2i(x, 61), 0))
		if result.ok() and result.placed[0] % AnimalView.DOG_EVERY == 0:
			dog_house = result.placed[0]
	view.rebuild()
	await get_tree().process_frame
	print("ovelhas %d · porcos %d · cães %d · cavalos %d" % [view.animal_count(&"sheep"), view.animal_count(&"pig"),
			view.animal_count(&"dog"), _game.cart_view.visible_horses()])
	var rig := _game.camera.rig
	for shot: Array in [["07_ovelhas.png", view.find_child("Sheep", false, false), 12.0],
			["08_cao.png", view.find_child("Dog", false, false), 12.0],
			["09_cavalo.png", _game.cart_view.find_child("Horses", false, false), 10.0],
			["09b_arreio.png", _game.cart_view.find_child("Horses", false, false), 9.0]]:
		var file_name: String = shot[0]
		var node: Node = shot[1]
		var distance: float = shot[2]
		var layer := node as MultiMeshInstance3D
		if layer == null or layer.multimesh.visible_instance_count == 0:
			print("sem ", file_name)
			continue
		var first := layer.multimesh.get_instance_transform(0)
		if file_name == "08_cao.png" and dog_house != 0:
			# o cão da casa da rua aberta (os cães saem pela ordem dos ids: é o último)
			first = layer.multimesh.get_instance_transform(layer.multimesh.visible_instance_count - 1)
		rig.focus = first.origin
		rig.distance = distance
		# a câmera fica do lado para onde o bicho olha (o −Z dele)
		var ahead := -first.basis.z
		rig.yaw = atan2(ahead.x, ahead.z)
		if file_name == "09b_arreio.png":
			# de lado, para ver o arreio (Fase 18) entre o cavalo e os varais
			rig.yaw += PI * 0.5
		rig.target_yaw = rig.yaw
		rig.ground_height = 0.0
		_game.camera.apply()
		if layer.get_parent() == _game.cart_view:
			# a carroça anda: a câmera vai atrás do cavalo enquanto os quadros passam
			for frame: int in 20:
				await get_tree().process_frame
				rig.focus = layer.multimesh.get_instance_transform(0).origin
				_game.camera.apply()
		await _advance_and_capture(file_name)
