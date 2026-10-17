extends Node
## Roteiro de verificação visual da Fase 10 (sem tela, roda no xvfb):
##   tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 20000 res://tools/capture_phase10.tscn -- <pasta>
## Jogo novo com o conselheiro e o tutorial apontando o entreposto (aba e cartão piscando), a aba
## Jogo das opções e a mensagem do salvamento automático.

var _out_dir: String


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	GameScreen.load_slot_on_start = ""
	GameScreen.use_sky3d = false
	GameScreen.flat_world = true
	Settings.edge_pan = false
	_run.call_deferred()


func _run() -> void:
	var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(game)
	GameClock.set_speed(TickClock.PAUSED)
	await _save("01_tutorial_aponta_o_entreposto.png")
	game.hud._select_category(game.hud.category_of(&"trading_post"))
	await _save("02_cartao_do_entreposto_piscando.png")
	var options := OptionsDialog.new()
	Modal.open(game._ui_layer, options)
	options.tabs.current_tab = options.tabs.get_tab_count() - 1
	await _save("03_opcoes_aba_jogo.png")
	game._close_all_modals()
	var saves_before := SaveSystem.save_dir
	SaveSystem.save_dir = "user://captura_fase10"
	game.autosave.save_now()
	await _save("04_salvamento_automatico.png")
	for slot: String in SaveSystem.list_slots():
		SaveSystem.delete_slot(slot)
	SaveSystem.save_dir = saves_before
	get_tree().quit()


func _save(file_name: String) -> void:
	for frame: int in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)
