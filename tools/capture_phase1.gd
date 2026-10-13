extends Node
## Roteiro de verificação visual da Fase 1 (sem tela, roda no xvfb):
##   tools/godot.sh godot --path . res://tools/capture_phase1.tscn -- <pasta de saída>
## Monta uma vila de 50 casas, captura as 4 direções da câmera, a prévia de construção,
## as camadas F1/F2, e confere que salvar e carregar devolve a mesma imagem.

const HOUSE := &"house"
const SLOT := "verificacao_fase1"

var _out_dir: String
var _game: GameScreen


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = true
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	GameClock.set_speed(TickClock.PAUSED)
	_run.call_deferred()


func _run() -> void:
	var sim := _game.simulation
	sim.free_build = true
	var ids := TownLayout.build(sim, 50, HOUSE, Vector2i(100, 100))
	print("casas construídas: %d" % ids.size())
	var island := Simulation.MAIN_ISLAND
	sim.execute(PlaceBuildingCommand.new(island, &"sawmill", Vector2i(130, 92), 0))
	sim.execute(BuildRoadCommand.new(island, RoadPath.l_path(Vector2i(100, 100), Vector2i(100, 120))))
	sim.execute(PlaceBuildingCommand.new(island, &"furnace", Vector2i(94, 112), 1))
	var rig := _game.camera.rig
	rig.focus = Vector3(220, 0, 222)
	rig.distance = 150.0
	for quarter: int in 4:
		await _settle()
		await _capture("0%d_direcao_%d.png" % [quarter + 1, quarter * 90])
		rig.rotate_quarter(1)
	await _settle()
	rig.distance = 40.0
	rig.focus = Vector3(215, 0, 205)
	await _settle()
	await _capture("05_perto.png")
	rig.distance = 110.0
	rig.focus = Vector3(220, 0, 222)
	var tool := _game.tool
	tool.select(ids[0])
	await _settle()
	await _capture("06_selecionado.png")
	tool.start_building(sim.data.building(&"sawmill"))
	tool.hover(Vector2i(120, 113))
	await _settle()
	await _capture("07_previa_valida.png")
	tool.hover(Vector2i(110, 104))
	await _settle()
	await _capture("08_previa_invalida.png")
	tool.start_road()
	tool.press(Vector2i(104, 110))
	tool.hover(Vector2i(116, 116))
	await _settle()
	await _capture("09_estrada_arrastando.png")
	tool.cancel()
	tool.cancel()
	_game.overlay.toggle(DebugOverlay.Layer.OCCUPANCY)
	await _settle()
	await _capture("10_f1_ocupacao.png")
	_game.overlay.toggle(DebugOverlay.Layer.ROADS)
	await _settle()
	await _capture("11_f2_estradas.png")
	_game.overlay.toggle(DebugOverlay.Layer.ROADS)
	await _check_save_load()
	get_tree().quit()


func _check_save_load() -> void:
	await _settle()
	var before := await _capture("12_antes_de_salvar.png")
	var state_before := _game.game_state()
	_game.save_game(SLOT)
	_game.simulation.execute(DemolishCommand.new(Simulation.MAIN_ISLAND, Rect2i(100, 100, 30, 30)))
	_game.camera.rig.rotate_quarter(1)
	await _settle()
	await _capture("13_alterado.png")
	_game.load_game(SLOT)
	_game.hud.show_message("")
	await _settle()
	var after := await _capture("14_depois_de_carregar.png")
	var same_state := _game.game_state() == state_before
	var diff := _pixel_difference(before, after)
	print("estado igual depois de carregar: %s" % same_state)
	var state_after := _game.game_state()
	for key: String in state_before:
		if state_before[key] != state_after[key]:
			print("  difere em %s: %s -> %s" % [key, str(state_before[key]).left(300), str(state_after[key]).left(300)])
	print("pixels diferentes antes/depois: %d de %d" % [diff, before.get_width() * before.get_height()])
	DirAccess.remove_absolute(SaveSystem.slot_path(SLOT))
	DirAccess.remove_absolute(SaveSystem.thumbnail_path(SLOT))


func _settle() -> void:
	for frame: int in 45:
		await get_tree().process_frame


func _capture(file_name: String) -> Image:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(_out_dir.path_join(file_name))
	return image


func _pixel_difference(a: Image, b: Image) -> int:
	var different := 0
	for y: int in range(0, a.get_height(), 2):
		for x: int in range(0, a.get_width(), 2):
			var pa := a.get_pixel(x, y)
			var pb := b.get_pixel(x, y)
			if absf(pa.r - pb.r) + absf(pa.g - pb.g) + absf(pa.b - pb.b) > 0.06:
				different += 4
	return different
